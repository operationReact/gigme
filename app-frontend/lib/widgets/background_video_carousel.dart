import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class BackgroundVideoCarousel extends StatefulWidget {
  final List<String> sources; // network URLs or asset identifiers (network only by default)
  final Duration switchEvery;
  final double darken;

  const BackgroundVideoCarousel({super.key, required this.sources, this.switchEvery = const Duration(seconds: 7), this.darken = 0.35});

  @override
  State<BackgroundVideoCarousel> createState() => _BackgroundVideoCarouselState();
}

class _BackgroundVideoCarouselState extends State<BackgroundVideoCarousel> {
  final List<VideoPlayerController> _controllers = [];
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.sources.isNotEmpty) {
      for (final src in widget.sources) {
        final c = VideoPlayerController.networkUrl(Uri.parse(src))
          ..setLooping(true)
          ..setVolume(0);
        _controllers.add(c);
      }
      _initAndPlay(0);
      _timer = Timer.periodic(widget.switchEvery, (_) => _next());
    }
  }

  Future<void> _initAndPlay(int i) async {
    try {
      final c = _controllers[i];
      await c.initialize();
      if (!mounted) return;
      for (var j = 0; j < _controllers.length; j++) {
        if (j == i) {
          _controllers[j].play();
        } else {
          _controllers[j].pause();
          _controllers[j].seekTo(Duration.zero);
        }
      }
      setState(() {});
    } catch (_) {
      // ignore init failures; fallback to gradient layer underneath
      setState(() {});
    }
  }

  void _next() {
    if (_controllers.isEmpty) return;
    final next = (_index + 1) % _controllers.length;
    _index = next;
    _initAndPlay(_index);
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controllers.isEmpty) return const SizedBox.shrink();
    final active = _controllers[_index];
    final ready = active.value.isInitialized;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      child: ready
          ? Stack(
              key: ValueKey(_index),
              fit: StackFit.expand,
              children: [
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: active.value.size.width,
                    height: active.value.size.height,
                    child: VideoPlayer(active),
                  ),
                ),
                Container(color: Colors.black.withOpacity(widget.darken)),
              ],
            )
          : const SizedBox.expand(),
    );
  }
}

