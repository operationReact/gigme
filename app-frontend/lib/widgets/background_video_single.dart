import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class BackgroundVideoSingle extends StatefulWidget {
  final String source; // network URL
  final double darken; // 0..1 overlay

  const BackgroundVideoSingle({super.key, required this.source, this.darken = 0.35});

  @override
  State<BackgroundVideoSingle> createState() => _BackgroundVideoSingleState();
}

class _BackgroundVideoSingleState extends State<BackgroundVideoSingle> {
  VideoPlayerController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    final c = VideoPlayerController.networkUrl(Uri.parse(widget.source))
      ..setLooping(true)
      ..setVolume(0);
    _controller = c;
    c.initialize().then((_) {
      if (!mounted) return;
      setState(() => _ready = true);
      c.play();
    }).catchError((_) {
      if (mounted) setState(() => _ready = false);
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) return const SizedBox.shrink();
    final c = _controller!;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: _ready && c.value.isInitialized
          ? Stack(
              key: const ValueKey('video-ready'),
              fit: StackFit.expand,
              children: [
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: c.value.size.width,
                    height: c.value.size.height,
                    child: VideoPlayer(c),
                  ),
                ),
                Container(color: Colors.black.withOpacity(widget.darken)),
              ],
            )
          : const SizedBox.expand(key: ValueKey('video-loading')),
    );
  }
}

