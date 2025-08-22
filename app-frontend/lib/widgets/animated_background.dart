import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

/// Simple reusable animated particles / floating blobs background.
/// Lightweight so it won't impact form performance.
class AnimatedSignInBackground extends StatefulWidget {
  final Widget child;
  final int particleCount;
  const AnimatedSignInBackground({super.key, required this.child, this.particleCount = 26});
  @override
  State<AnimatedSignInBackground> createState() => _AnimatedSignInBackgroundState();
}

class _AnimatedSignInBackgroundState extends State<AnimatedSignInBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;
  late final List<_Particle> _particles;
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat();
    _particles = List.generate(widget.particleCount, (i) => _Particle(_rand));
  }

  @override
  void dispose() { _ctl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _ctl,
      builder: (context, _) {
        return CustomPaint(
          painter: _ParticlesPainter(_particles, _ctl.value, cs),
          child: widget.child,
        );
      },
    );
  }
}

class _Particle {
  double x; double y; double r; double speed; double drift; double hueShift; double alpha;
  _Particle(Random rand)
      : x = rand.nextDouble(),
        y = rand.nextDouble(),
        r = rand.nextDouble() * 26 + 6,
        speed = rand.nextDouble() * 0.25 + 0.05,
        drift = rand.nextDouble() * 0.4 - 0.2,
        hueShift = rand.nextDouble(),
        alpha = rand.nextDouble() * 0.35 + 0.2;
}

class _ParticlesPainter extends CustomPainter {
  final List<_Particle> particles; final double t; final ColorScheme cs;
  _ParticlesPainter(this.particles, this.t, this.cs);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    for (final p in particles) {
      // loop vertical movement
      final dy = (p.y + (t * p.speed)) % 1.0; // wrap
      final dx = (p.x + (t * p.drift)) % 1.0;
      final center = Offset(dx * size.width, dy * size.height);
      final color = HSVColor.fromAHSV(p.alpha, (p.hueShift * 180 + t * 120) % 360, 0.45, 0.95).toColor();
      paint
        ..shader = RadialGradient(colors: [color.withOpacity(0.0), color]).createShader(Rect.fromCircle(center: center, radius: p.r*2))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, p.r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) => true;
}

