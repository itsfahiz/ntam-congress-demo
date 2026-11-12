import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../app/theme/app_colors.dart';
import '../../core/widgets/congress_feature_scaffold.dart';
import '../congress/data/congress_catalog.dart';
import '../congress/domain/congress_models.dart';
import '../saved/state/saved_items_controller.dart';
import 'data/demo_resource_pdf.dart';
import 'data/resource_file_service.dart';
import 'data/resource_video_links.dart';

/// Shared destination from Library, Search and Saved Items.
class ResourceViewerScreen extends StatefulWidget {
  const ResourceViewerScreen({super.key, required this.resourceId});
  final String resourceId;

  @override
  State<ResourceViewerScreen> createState() => _ResourceViewerScreenState();
}

class _ResourceViewerScreenState extends State<ResourceViewerScreen> {
  bool _busy = false;
  String? _error;

  CongressResource? get _resource {
    for (final resource in CongressCatalog.resources) {
      if (resource.id == widget.resourceId) return resource;
    }
    return null;
  }

  Future<void> _download() async {
    final resource = _resource;
    if (resource == null || _busy || resource.kind == ResourceKind.video) return;
    setState(() { _busy = true; _error = null; });
    try {
      await ResourceFileService.export(resource);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not open Save/Share. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _watchVideo() async {
    final resource = _resource;
    if (resource == null || _busy || resource.kind != ResourceKind.video) return;
    setState(() { _busy = true; _error = null; });
    try {
      final opened = await ResourceVideoLinks.watch(resource.id);
      if (!opened && mounted) {
        setState(() => _error =
            'Unable to open YouTube. Check your browser or internet connection.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'Unable to open YouTube. Check your browser or internet connection.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleSaved() async {
    final resource = _resource;
    if (resource == null) return;
    try {
      await SavedItemsScope.of(context).toggle('resource', resource.id);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final resource = _resource;
    if (resource == null) {
      return CongressFeatureScaffold(
        title: 'Resource',
        body: const Center(child: Text('Resource not found.')),
      );
    }
    final externalVideo = resource.kind == ResourceKind.video;
    final saved = SavedItemsScope.of(context);
    return CongressFeatureScaffold(
      title: externalVideo ? 'Educational Video' : 'Document',
      titleAlign: TextAlign.start,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(resource.title, style: const TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 20)),
                const SizedBox(height: 4),
                Text(
                  externalVideo
                      ? 'Stanford University · External course trailer. Not congress footage.'
                      : 'Original illustrative assessment material — not official congress media.',
                  style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _toggleSaved,
                    icon: Icon(saved.isSaved('resource', resource.id)
                        ? Icons.bookmark_rounded : Icons.bookmark_border_rounded),
                    label: Text(saved.isSaved('resource', resource.id)
                        ? 'Saved' : 'Save'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null : externalVideo ? _watchVideo : _download,
                    icon: Icon(externalVideo
                        ? Icons.play_circle_outline_rounded
                        : Icons.download_rounded),
                    label: Text(externalVideo ? 'Watch Video' : 'Download'),
                  ),
                ]),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_error!, style: const TextStyle(color: Colors.red))),
                if (_busy) const LinearProgressIndicator(),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: externalVideo
                ? _externalVideoInfo(resource)
                : PdfPreview(
                    key: ValueKey(resource.id),
                    build: (_) => DemoResourcePdf.build(resource),
                    allowPrinting: true,
                    allowSharing: true,
                    canChangeOrientation: false,
                    canChangePageFormat: false,
                    pdfFileName: ResourceFileService.filename(resource),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _externalVideoInfo(CongressResource resource) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF052453), Color(0xFF12549C)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_circle_fill_rounded,
                    size: 70, color: Colors.white),
                SizedBox(height: 12),
                Text('Stanford University',
                    style: TextStyle(color: Colors.white, fontSize: 19,
                        fontWeight: FontWeight.w800)),
                SizedBox(height: 6),
                Text('Introduction to Food & Health · Course Trailer',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text('External educational resource',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(resource.body,
              style: const TextStyle(height: 1.5, fontSize: 14,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 14),
          const Text(
            'Tap Watch Video to open the original trailer on YouTube. '
            'An internet connection is required. The video is hosted by '
            'its publisher and is not downloaded or repackaged by this demo.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
