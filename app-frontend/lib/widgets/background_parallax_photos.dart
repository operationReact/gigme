import 'dart:math' as math;
import 'package:flutter/material.dart';

class BackgroundParallaxPhotos extends StatefulWidget {
  final List<String> sources; // network image URLs
  final Duration cycle; // how long for a full drift cycle
  final double darken; // overlay darkness 0..1
  final double amplitude; // max drift in px
  final double speedMultiplier; // scales layer speeds (1.0 default)

  const BackgroundParallaxPhotos({
    super.key,
    required this.sources,
    this.cycle = const Duration(seconds: 40),
    this.darken = 0.35,
    this.amplitude = 24,
    this.speedMultiplier = 1,
  });

  @override
  State<BackgroundParallaxPhotos> createState() => _BackgroundParallaxPhotosState();
}

class _BackgroundParallaxPhotosState extends State<BackgroundParallaxPhotos>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(vsync: this, duration: widget.cycle)..repeat();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sources.isEmpty) return const SizedBox.shrink();

    // Use up to 5 layers for performance, repeating sources if needed
    final layers = <Widget>[];
    final count = math.min(5, widget.sources.length);
    for (var i = 0; i < count; i++) {
      final url = widget.sources[i % widget.sources.length];
      final speed = widget.speedMultiplier * (0.4 + (i * 0.15)); // slower back, faster top
      final phase = i * 0.8; // stagger start
      final opacity = (0.55 + i * 0.08).clamp(0.5, 0.9);
      final scale = 1.05 + i * 0.03;
      layers.add(_ParallaxLayer(
        url: url,
        controller: _ctl,
        amplitude: widget.amplitude,
        speed: speed,
        phase: phase,
        opacity: opacity,
        scale: scale,
      ));
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        ...layers,
        Container(color: Colors.black.withOpacity(widget.darken)),
      ],
    );
  }
}

class _ParallaxLayer extends StatelessWidget {
  final String url;
  final AnimationController controller;
  final double amplitude;
  final double speed;
  final double phase;
  final double opacity;
  final double scale;

  const _ParallaxLayer({
    required this.url,
    required this.controller,
    required this.amplitude,
    required this.speed,
    required this.phase,
    required this.opacity,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value * speed + phase;
        final dx = math.sin(t * 2 * math.pi) * amplitude;
        final dy = math.cos((t + 0.33) * 2 * math.pi) * amplitude;
        return Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: _Photo(url: url),
            ),
          ),
        );
      },
    );
  }
}

class _Photo extends StatelessWidget {
  final String url;
  const _Photo({required this.url});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.cover,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : Container(color: Colors.black12),
        errorBuilder: (context, error, stack) => Container(color: Colors.black12),
      ),
    );
  }
}
