import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class BackgroundVideoMosaic extends StatefulWidget {
  final List<String> sources;
  final double darken;
  final double tileAspect; // width/height
  final double targetTileWidth; // px target width; rows/cols adapt

  const BackgroundVideoMosaic({
    super.key,
    required this.sources,
    this.darken = 0.45,
    this.tileAspect = 16 / 9,
    this.targetTileWidth = 180,
  });

  @override
  State<BackgroundVideoMosaic> createState() => _BackgroundVideoMosaicState();
}

class _BackgroundVideoMosaicState extends State<BackgroundVideoMosaic> with TickerProviderStateMixin {
  final List<VideoPlayerController> _controllers = [];
  late final AnimationController _pulseCtl;
  int _cols = 1;
  int _rows = 1;

  @override
  void initState() {
    super.initState();
    _pulseCtl = AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _computeGridAndEnsureControllers();
  }

  void _computeGridAndEnsureControllers() {
    final size = MediaQuery.sizeOf(context);
    if (size.width == 0 || size.height == 0) return;
    final cols = (size.width / widget.targetTileWidth).ceil().clamp(1, 20);
    final tileH = (widget.targetTileWidth / widget.tileAspect);
    final rows = (size.height / tileH).ceil().clamp(1, 20);

    final needed = cols * rows;
    if (_cols == cols && _rows == rows && _controllers.length == needed) return;
    _cols = cols;
    _rows = rows;

    // Grow or shrink controllers to match needed count, cap to reasonable amount
    final cap = (cols * rows).clamp(1, 80); // cap at 80 tiles for performance
    final target = cap;

    // Add
    for (int i = _controllers.length; i < target; i++) {
      final src = widget.sources[i % widget.sources.length];
      final c = VideoPlayerController.networkUrl(Uri.parse(src))
        ..setLooping(true)
        ..setVolume(0);
      _controllers.add(c);
      _initAndPlay(c);
    }
    // Remove extra
    if (_controllers.length > target) {
      final extra = _controllers.sublist(target);
      for (final c in extra) {
        c.pause();
        c.dispose();
      }
      _controllers.removeRange(target, _controllers.length);
    }
    setState(() {});
  }

  Future<void> _initAndPlay(VideoPlayerController c) async {
    try {
      await c.initialize();
      if (!mounted) return;
      unawaited(c.play());
    } catch (_) {
      // swallow init errors
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pulseCtl.dispose();
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controllers.isEmpty) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _pulseCtl,
      builder: (context, _) {
        return Stack(
          fit: StackFit.expand,
          children: [
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _cols,
                childAspectRatio: widget.tileAspect,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
              ),
              itemCount: _controllers.length,
              itemBuilder: (context, i) {
                final c = _controllers[i];
                final ready = c.value.isInitialized;
                final t = _pulseCtl.value;
                final scale = 1.0 + 0.06 * math.sin((i * 0.73) + t * math.pi * 2);
                final opacity = 0.9 + 0.1 * math.sin((i * 1.11) + t * math.pi * 2);
                return Transform.scale(
                  scale: scale.clamp(0.9, 1.1),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (ready)
                          FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: c.value.size.width,
                              height: c.value.size.height,
                              child: Opacity(opacity: opacity.clamp(0.8, 1.0), child: VideoPlayer(c)),
                            ),
                          )
                        else
                          Container(color: Colors.black12),
                        Container(color: Colors.black.withOpacity(widget.darken)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

