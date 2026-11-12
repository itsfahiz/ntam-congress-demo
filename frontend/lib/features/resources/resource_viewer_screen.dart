import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

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
  YoutubePlayerController? _youtubeController;

  CongressResource? get _resource {
    for (final resource in CongressCatalog.resources) {
      if (resource.id == widget.resourceId) return resource;
    }
    return null;
  }

  @override
  void dispose() {
    _youtubeController?.close();
    super.dispose();
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

  /// Starts the official YouTube iframe *inside* this screen.
  /// The embedded player is created on demand to keep navigation/tests light.
  void _watchVideo() {
    final resource = _resource;
    if (resource == null || resource.kind != ResourceKind.video ||
        _youtubeController != null) return;
    final videoId = ResourceVideoLinks.videoIdForResource(resource.id);
    if (videoId == null) {
      setState(() => _error = 'This video is unavailable.');
      return;
    }
    try {
      final controller = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: true,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          playsInline: true,
          privacyEnhancedMode: true,
        ),
      );
      setState(() {
        _youtubeController = controller;
        _error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'The embedded player could not start. Please try again.');
      }
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
                    onPressed: externalVideo
                        ? (_youtubeController == null ? _watchVideo : null)
                        : (_busy ? null : _download),
                    icon: Icon(externalVideo
                        ? Icons.play_circle_outline_rounded
                        : Icons.download_rounded),
                    label: Text(externalVideo ?
                        (_youtubeController == null ? 'Play Video' : 'Playing below')
                        : 'Download'),
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
          if (_youtubeController case final controller?)
            YoutubePlayer(
              key: const ValueKey('stanford-embedded-youtube-player'),
              controller: controller,
              aspectRatio: 16 / 9,
            )
          else
          InkWell(
            key: const ValueKey('stanford-inline-video-play'),
            onTap: _watchVideo,
            borderRadius: BorderRadius.circular(20),
            child: Container(
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
            'Tap Play Video to stream the Stanford trailer inside this app. '
            'Internet is required. Playback and fullscreen controls are built into '
            'the embedded YouTube player. If YouTube restricts embedding, '
            'the video may be unavailable; this app does not rehost it.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
