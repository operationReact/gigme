import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'screens/sign_in_user.dart';
import 'screens/sign_in_client.dart';
import 'screens/profile_user.dart';
import 'screens/profile_client.dart';
import 'screens/profile_freelancer.dart';
import 'screens/register_freelancer.dart';
import 'screens/register_client.dart';
import 'screens/freelancer_home.dart';
import 'widgets/background_video_single.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Fresh teal + violet theme (distinct from previous orange/black)
    final seed = const Color(0xFF14B8A6); // teal
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    ).copyWith(
      primary: const Color(0xFF0F172A), // slate-900 for strong text/appbar
      onPrimary: Colors.white,
      secondary: const Color(0xFF14B8A6), // teal accent
      onSecondary: const Color(0xFF052E2B),
      tertiary: const Color(0xFF7C3AED), // violet accent
      surface: const Color(0xFFF9FAFB),
      onSurface: const Color(0xFF0B1324),
      outlineVariant: const Color(0xFFE5E7EB),
    );

    return MaterialApp(
      title: 'Gigmework',
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 1,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.linux: ZoomPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: ZoomPageTransitionsBuilder(),
            TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
          },
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.secondary,
            foregroundColor: colorScheme.onSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: colorScheme.secondary.withOpacity(0.12),
          labelStyle: TextStyle(color: colorScheme.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: colorScheme.secondary.withOpacity(0.35)),
          ),
        ),
        cardTheme: CardThemeData(
          color: colorScheme.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
        ),
      ),
      routes: {
        SignInUserPage.routeName: (_) => const SignInUserPage(),
        SignInClientPage.routeName: (_) => const SignInClientPage(),
        ProfileUserPage.routeName: (_) => const ProfileUserPage(),
        ProfileClientPage.routeName: (_) => const ProfileClientPage(),
        ProfileFreelancerPage.routeName: (_) => const ProfileFreelancerPage(),
        RegisterFreelancerPage.routeName: (_) => const RegisterFreelancerPage(),
        RegisterClientPage.routeName: (_) => const RegisterClientPage(),
        FreelancerHomePage.routeName: (_) => const FreelancerHomePage(),
      },
      home: const LandingPage(),
    );
  }
}

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with TickerProviderStateMixin {
  late final AnimationController _bgCtl;
  late final AnimationController _introCtl;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideIn;

  // Single background video (replace with your own link)
  static const String _videoSource =
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4';

  @override
  void initState() {
    super.initState();
    _bgCtl = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();
    _introCtl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
    _fadeIn = CurvedAnimation(parent: _introCtl, curve: Curves.easeOut);
    _slideIn = Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(CurvedAnimation(parent: _introCtl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _bgCtl.dispose();
    _introCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Gigmework'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: AnimatedBuilder(
        animation: _bgCtl,
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // Single cinematic video background
              const BackgroundVideoSingle(
                source: _videoSource,
                darken: 0.35,
              ),
              // Rotating gradient base (subtle to tint the videos)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cs.secondary.withOpacity(0.14),
                      cs.tertiary.withOpacity(0.14),
                    ],
                    transform: GradientRotation(_bgCtl.value * 6.2831853),
                  ),
                ),
              ),
              // Soft moving blobs for parallax depth
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _ParticlePainter(
                      t: _bgCtl.value,
                      colorA: cs.secondary.withOpacity(0.06),
                      colorB: cs.tertiary.withOpacity(0.06),
                    ),
                  ),
                ),
              ),
              // Foreground content
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: FadeTransition(
                      opacity: _fadeIn,
                      child: SlideTransition(
                        position: _slideIn,
                        child: SafeArea(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'GigMeWork',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'People Need People',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                                    ),
                                    const SizedBox(height: 22),
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        final available = constraints.maxWidth;
                                        final cardWidth = available >= 760 ? 360.0 : available < 340 ? available : (available - 0); // two cards side-by-side if room (> 760 incl padding), else full width
                                        final sideBySide = available >= 760;
                                        final children = [
                                          _ActionCard(
                                            icon: Icons.person_outline,
                                            title: 'I am a Freelancer',
                                            subtitle: 'Create a stellar profile and showcase your work',
                                            gradient: LinearGradient(colors: [cs.secondary, cs.tertiary]),
                                            heroTag: 'hero-freelancer',
                                            width: cardWidth,
                                            onTap: () => Navigator.of(context).pushNamed(SignInUserPage.routeName),
                                          ),
                                          _ActionCard(
                                            icon: Icons.business_center_outlined,
                                            title: 'I need a freelancer',
                                            subtitle: 'Post jobs and hire verified talent',
                                            gradient: LinearGradient(colors: [cs.tertiary, cs.secondary]),
                                            heroTag: 'hero-client',
                                            width: cardWidth,
                                            onTap: () => Navigator.of(context).pushNamed(SignInClientPage.routeName),
                                          ),
                                        ];
                                        if (sideBySide) {
                                          return Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              for (int i = 0; i < children.length; i++) ...[
                                                children[i],
                                                if (i < children.length - 1) const SizedBox(width: 20)
                                              ]
                                            ],
                                          );
                                        }
                                        return Column(
                                          children: [
                                            for (int i = 0; i < children.length; i++) ...[
                                              children[i],
                                              if (i < children.length - 1) const SizedBox(height: 16)
                                            ]
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ActionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;
  final String? heroTag;
  final double? width; // new responsive width
  const _ActionCard({required this.icon, required this.title, required this.subtitle, required this.gradient, required this.onTap, this.heroTag, this.width});

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
   bool _hovered = false;
   bool _pressed = false;

   @override
   Widget build(BuildContext context) {
     final cs = Theme.of(context).colorScheme;
     final scale = _pressed ? 0.98 : (_hovered ? 1.03 : 1.0);
     return MouseRegion(
       onEnter: (_) => setState(() => _hovered = true),
       onExit: (_) => setState(() => _hovered = false),
       child: GestureDetector(
         onTapDown: (_) => setState(() => _pressed = true),
         onTapCancel: () => setState(() => _pressed = false),
         onTapUp: (_) => setState(() => _pressed = false),
         onTap: widget.onTap,
         child: AnimatedScale(
           scale: scale,
           duration: const Duration(milliseconds: 140),
           curve: Curves.easeOut,
           child: Container(
             width: widget.width ?? 360,
             height: 120,
             decoration: BoxDecoration(
               gradient: widget.gradient,
               borderRadius: BorderRadius.circular(16),
               boxShadow: [
                 BoxShadow(
                   color: cs.tertiary.withOpacity(0.15),
                   blurRadius: 16,
                   offset: const Offset(0, 8),
                 ),
               ],
             ),
             child: Padding(
               padding: const EdgeInsets.all(18),
               child: Row(
                 children: [
                   if (widget.heroTag != null)
                     Hero(
                       tag: widget.heroTag!,
                       child: _BadgeAvatar(icon: widget.icon),
                     )
                   else
                     _BadgeAvatar(icon: widget.icon),
                   const SizedBox(width: 14),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         Text(
                           widget.title,
                           maxLines: 1,
                           overflow: TextOverflow.ellipsis,
                           style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                         ),
                         const SizedBox(height: 4),
                         Text(
                           widget.subtitle,
                           maxLines: 2,
                           overflow: TextOverflow.ellipsis,
                           style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.9)),
                         ),
                       ],
                     ),
                   ),
                 ],
               ),
             ),
           ),
         ),
       ),
     );
   }
 }

class _BadgeAvatar extends StatelessWidget {
  final IconData icon;
  const _BadgeAvatar({required this.icon});
  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 26,
      backgroundColor: Colors.white.withOpacity(0.18),
      child: Icon(icon, color: Colors.white),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double t; // 0..1 loop
  final Color colorA;
  final Color colorB;
  _ParticlePainter({required this.t, required this.colorA, required this.colorB});

  @override
  void paint(Canvas canvas, Size size) {
    final paintA = Paint()..color = colorA;
    final paintB = Paint()..color = colorB;
    // Draw a few soft circles moving sinusoidally
    for (int i = 0; i < 24; i++) {
      final phase = (i * 0.261799) + t * 6.2831853; // i*15deg + time
      final r = 10 + (i % 5) * 3;
      final x = size.width * (0.5 + 0.45 * math.cos(phase + i));
      final y = size.height * (0.5 + 0.45 * math.sin(phase * 0.9 + i * 0.3));
      final paint = i.isEven ? paintA : paintB;
      canvas.drawCircle(Offset(x, y), r.toDouble(), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => oldDelegate.t != t || oldDelegate.colorA != colorA || oldDelegate.colorB != colorB;
}
