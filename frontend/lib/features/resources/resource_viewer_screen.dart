import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:video_player/video_player.dart';

import '../../app/theme/app_colors.dart';
import '../../core/widgets/congress_feature_scaffold.dart';
import '../congress/data/congress_catalog.dart';
import '../congress/domain/congress_models.dart';
import '../saved/state/saved_items_controller.dart';
import 'data/demo_resource_pdf.dart';
import 'data/resource_file_service.dart';

/// Standalone viewer, shared by Resources, Saved Items, and global Search.
class ResourceViewerScreen extends StatefulWidget {
  const ResourceViewerScreen({super.key, required this.resourceId});
  final String resourceId;

  @override
  State<ResourceViewerScreen> createState() => _ResourceViewerScreenState();
}

class _ResourceViewerScreenState extends State<ResourceViewerScreen> {
  VideoPlayerController? _video;
  bool _videoLoaded = false;
  bool _busy = false;
  String? _error;
  String? _offlinePath;

  CongressResource? get _resource {
    for (final resource in CongressCatalog.resources) {
      if (resource.id == widget.resourceId) return resource;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    if (_resource?.kind == ResourceKind.video) _initVideo();
  }

  Future<void> _initVideo() async {
    final controller =
        VideoPlayerController.asset('assets/media/day1_demo_recap.mp4');
    _video = controller;
    try {
      await controller.initialize();
      await controller.setLooping(true);
      if (mounted) setState(() => _videoLoaded = true);
    } catch (_) {
      if (mounted) setState(() => _error = 'Demo video cannot be played on this device.');
    }
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final resource = _resource;
    if (resource == null || _busy) return;
    setState(() { _busy = true; _error = null; });
    try {
      final location = await ResourceFileService.download(resource);
      if (!mounted) return;
      setState(() => _offlinePath = location);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved to $location')),
      );
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message ?? 'Download failed.');
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not download this resource.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share() async {
    final resource = _resource;
    if (resource == null || _busy) return;
    setState(() { _busy = true; _error = null; });
    try {
      await ResourceFileService.export(resource);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not export this file. Try again.');
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
    final saved = SavedItemsScope.of(context);
    return CongressFeatureScaffold(
      title: resource.kind == ResourceKind.video ? 'Video' : 'Document',
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
                const Text(
                  'Original illustrative assessment material — not official congress media.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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
                    onPressed: _busy ? null : _save,
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Download'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _share,
                    icon: const Icon(Icons.ios_share_rounded),
                    label: const Text('Export'),
                  ),
                ]),
                if (_offlinePath != null) const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Saved in device Downloads. Open Files → Downloads → NTAM Congress.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ),
                if (_error != null) Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_error!, style: const TextStyle(color: Colors.red))),
                if (_busy) const LinearProgressIndicator(),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: resource.kind == ResourceKind.video
                ? _videoPlayer(resource)
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

  String _time(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _videoPlayer(CongressResource resource) {
    final controller = _video;
    if (controller == null || !_videoLoaded) {
      return Center(
        child: _error == null
            ? const CircularProgressIndicator()
            : const Text('Video preview unavailable.'),
      );
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 14),
          AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                final value = controller.value;
                final durationMs = value.duration.inMilliseconds;
                final progress = durationMs > 0
                    ? value.position.inMilliseconds / durationMs
                    : 0.0;
                final caption = switch (progress) {
                  < 0.25 => 'Opening Ceremony',
                  < 0.5 => 'Welcome & Introduction',
                  < 0.75 => 'Pediatric Nutrition',
                  _ => 'Clinical Research Highlights',
                };
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    VideoPlayer(controller),
                    Positioned(
                      left: 10,
                      right: 10,
                      bottom: 8,
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xDD052453),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.auto_awesome,
                                  color: Colors.cyanAccent, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(caption,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    )),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final value = controller.value;
              final duration = value.duration;
              final position = value.position;
              final maximum = duration.inMilliseconds > 0
                  ? duration.inMilliseconds.toDouble()
                  : 1.0;
              final progress = position.inMilliseconds
                  .toDouble()
                  .clamp(0.0, maximum);
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                    child: Row(
                      children: [
                        IconButton.filled(
                          tooltip: value.isPlaying ? 'Pause video' : 'Play video',
                          icon: Icon(value.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded),
                          onPressed: () async {
                            if (value.isPlaying) {
                              await controller.pause();
                            } else {
                              await controller.play();
                            }
                          },
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Slider(
                            value: progress,
                            min: 0,
                            max: maximum,
                            onChanged: (next) async {
                              await controller.seekTo(
                                Duration(milliseconds: next.round()),
                              );
                            },
                          ),
                        ),
                        Text('${_time(position)} / ${_time(duration)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (value.isPlaying)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Playing short illustrative recap clip',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Text(
              'This is an original demonstration title-card clip, '
              'not a recording of actual congress sessions.\n\n'
              '${resource.body}',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
