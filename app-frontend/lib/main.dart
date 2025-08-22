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
import 'screens/freelancer_profile_screen.dart';
import 'screens/client_profile_screen.dart';
import 'screens/forgot_password.dart';
import 'widgets/background_video_single.dart';
import 'services/preferences_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _darkMode = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    PreferencesService.instance.loadDarkMode().then((v){ if(mounted) setState(() { _darkMode = v; _loaded = true; }); });
  }

  void _toggleTheme(){
    setState(() => _darkMode = !_darkMode);
    PreferencesService.instance.setDarkMode(_darkMode);
  }

  @override
  Widget build(BuildContext context) {
    final seed = const Color(0xFF14B8A6);
    final lightScheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light).copyWith(
      primary: const Color(0xFF0F172A),
      onPrimary: Colors.white,
      secondary: const Color(0xFF14B8A6),
      onSecondary: const Color(0xFF052E2B),
      tertiary: const Color(0xFF7C3AED),
      surface: const Color(0xFFF9FAFB),
      onSurface: const Color(0xFF0B1324),
      outlineVariant: const Color(0xFFE5E7EB),
    );
    final darkScheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark).copyWith(
      primary: const Color(0xFF1E293B),
      secondary: const Color(0xFF0D9488),
      tertiary: const Color(0xFF6D28D9),
      surface: const Color(0xFF111827),
      onSurface: Colors.white.withOpacity(0.92),
    );

    ThemeData baseTheme(ColorScheme cs) => ThemeData(
      colorScheme: cs,
      useMaterial3: true,
      appBarTheme: AppBarTheme(backgroundColor: cs.primary, foregroundColor: cs.onPrimary, elevation: 1),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: ZoomPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: ZoomPageTransitionsBuilder(),
        TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
      }),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: cs.secondary, foregroundColor: cs.onSecondary, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: cs.primary)),
      chipTheme: ChipThemeData(backgroundColor: cs.secondary.withOpacity(0.12), labelStyle: TextStyle(color: cs.primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: cs.secondary.withOpacity(0.35)))),
      cardTheme: CardThemeData(color: cs.surface, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: cs.outlineVariant.withOpacity(0.4)))),
    );

    return MaterialApp(
      title: 'Gigmework',
      theme: baseTheme(lightScheme),
      darkTheme: baseTheme(darkScheme),
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      routes: {
        SignInUserPage.routeName: (_) => const SignInUserPage(),
        SignInClientPage.routeName: (_) => const SignInClientPage(),
        ProfileUserPage.routeName: (_) => const ProfileUserPage(),
        ProfileClientPage.routeName: (_) => const ProfileClientPage(),
        ProfileFreelancerPage.routeName: (_) => const ProfileFreelancerPage(),
        RegisterFreelancerPage.routeName: (_) => const RegisterFreelancerPage(),
        RegisterClientPage.routeName: (_) => const RegisterClientPage(),
        FreelancerHomePage.routeName: (_) => const FreelancerHomePage(),
        FreelancerProfileScreen.route: (_) => const FreelancerProfileScreen(),
        ClientProfileScreen.route: (_) => const ClientProfileScreen(),
        ForgotPasswordPage.routeName: (_) => const ForgotPasswordPage(),
      },
      home: _loaded ? LandingPage(onToggleTheme: _toggleTheme, darkMode: _darkMode) : const SizedBox.shrink(),
    );
  }
}

class LandingPage extends StatefulWidget {
  final VoidCallback onToggleTheme; final bool darkMode;
  const LandingPage({super.key, required this.onToggleTheme, required this.darkMode});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with TickerProviderStateMixin {
  late final AnimationController _bgCtl; // still used for base timing
  late final AnimationController _introCtl;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideIn;

  // pointer tracking
  Offset _pointer = Offset.zero;
  double _parallaxY = 0; // smoothed relative y (-0.5..0.5)
  Offset? _lastPointer;
  DateTime? _lastMoveTs;
  double _velocity = 0; // px/sec
  double _rotSpeedFactor = 1; // 1..4

  static const String _videoSource = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4';

  @override
  void initState() {
    super.initState();
    _bgCtl = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();
    _introCtl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
    _fadeIn = CurvedAnimation(parent: _introCtl, curve: Curves.easeOut);
    _slideIn = Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(CurvedAnimation(parent: _introCtl, curve: Curves.easeOutCubic));
  }

  void _updatePointer(PointerEvent e){
    final size = MediaQuery.of(context).size;
    _pointer = e.position; // global
    // velocity
    final now = DateTime.now();
    if(_lastPointer!=null && _lastMoveTs!=null){
      final dt = now.difference(_lastMoveTs!).inMicroseconds / 1e6;
      if(dt>0){
        final dist = (e.position - _lastPointer!).distance;
        final instV = dist / dt; // px/sec
        // low-pass filter
        _velocity = _velocity*0.85 + instV*0.15;
        final norm = (_velocity/800).clamp(0,3); // typical mouse flick ~800-1500
        _rotSpeedFactor = 1 + norm.toDouble(); // 1..4
      }
    }
    _lastPointer = e.position; _lastMoveTs = now;
    // parallax (vertical)
    final relY = (e.position.dy/size.height) - 0.5; // -0.5..0.5
    _parallaxY = ui.lerpDouble(_parallaxY, relY, 0.15)!;
    setState((){});
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
    final tScaled = (_bgCtl.value * _rotSpeedFactor) % 1.0; // dynamic speed
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Gigmework'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: widget.darkMode? 'Light mode' : 'Dark mode',
            onPressed: widget.onToggleTheme,
            icon: Icon(widget.darkMode? Icons.light_mode_outlined : Icons.dark_mode_outlined, color: Colors.white),
          )
        ],
      ),
      body: Listener(
        onPointerHover: _updatePointer,
        onPointerMove: _updatePointer,
        child: AnimatedBuilder(
          animation: _bgCtl,
          builder: (context, _) {
            return Stack(
              fit: StackFit.expand,
              children: [
                const BackgroundVideoSingle(source: _videoSource, darken: 0.35),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        cs.secondary.withOpacity(0.14),
                        cs.tertiary.withOpacity(0.14),
                      ],
                      transform: GradientRotation(tScaled * 6.2831853),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _ParticlePainter(
                        t: tScaled,
                        colorA: cs.secondary.withOpacity(0.06),
                        colorB: cs.tertiary.withOpacity(0.06),
                      ),
                    ),
                  ),
                ),
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
                                  child: LayoutBuilder(
                                    builder: (context, constraints){
                                      final available = constraints.maxWidth;
                                      final cardWidth = available >= 760 ? 360.0 : available < 340 ? available : (available - 0);
                                      final sideBySide = available >= 760;
                                      final headingOffset = _parallaxY * -20; // invert for subtle lift
                                      final cardsOffset = _parallaxY * 12;
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
                                      return Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          Transform.translate(
                                            offset: Offset(0, headingOffset),
                                            child: Column(
                                              children: [
                                                Text('GigMeWork', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700, color: Colors.white)),
                                                const SizedBox(height: 8),
                                                Text('People Need People', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70)),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 22),
                                          Transform.translate(
                                            offset: Offset(0, cardsOffset),
                                            child: sideBySide ? Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [for (int i=0;i<children.length;i++) ...[children[i], if(i<children.length-1) const SizedBox(width:20)]],
                                            ) : Column(children: [for (int i=0;i<children.length;i++) ...[children[i], if(i<children.length-1) const SizedBox(height:16)]]),
                                          ),
                                        ],
                                      );
                                    },
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

class _ActionCardState extends State<_ActionCard> with SingleTickerProviderStateMixin {
  bool _hovered = false;
  bool _pressed = false;
  late final AnimationController _anim;

  // target & smoothed tilt (-1..1)
  double _txTarget = 0; // x axis tilt input (horizontal movement)
  double _tyTarget = 0; // y axis tilt input (vertical movement)
  double _tx = 0; // smoothed
  double _ty = 0; // smoothed

  @override
  void initState(){
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
      ..addListener(_tick)
      ..repeat(); // acts as ticker for damping + gradient sweep
  }

  void _tick(){
    // exponential smoothing toward target
    _tx += (_txTarget - _tx) * 0.12;
    _ty += (_tyTarget - _ty) * 0.12;
    if(mounted) setState((){});
  }

  void _updateRel(PointerEvent e, BoxConstraints c){
    final renderBox = context.findRenderObject() as RenderBox?;
    if(renderBox==null) return;
    final local = renderBox.globalToLocal(e.position);
    final w = renderBox.size.width;
    final h = renderBox.size.height;
    final dx = (local.dx / w) * 2 - 1; // -1..1
    final dy = (local.dy / h) * 2 - 1; // -1..1
    _txTarget = dx.clamp(-1,1); // horizontal moves rotateY
    _tyTarget = dy.clamp(-1,1); // vertical moves rotateX
  }

  @override
  void dispose(){ _anim.dispose(); super.dispose(); }

  double get _highlightProgress => _anim.value; // 0..1 looping

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hoverScale = 1.0 + (_hovered? 0.02 : 0.0) - (_pressed? 0.02 : 0.0);
    const maxDeg = 8.0; // degrees
    final rx = (-_ty) * (maxDeg * math.pi / 180); // invert so moving mouse down tilts card away
    final ry = (_tx) * (maxDeg * math.pi / 180);
    final shadowLift = _hovered ? -4.0 : 0.0;
    final blur = 16 + (_hovered? 10 : 0);
    final spread = _hovered? 2.0 : 0.5;
    final shadowColor = cs.tertiary.withOpacity(_hovered? 0.28 : 0.15);

    Widget cardCore = Container(
      width: widget.width ?? 360,
      height: 120,
      decoration: BoxDecoration(
        gradient: widget.gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: shadowColor, blurRadius: blur.toDouble(), spreadRadius: spread, offset: Offset(0, 8 + shadowLift)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            if (widget.heroTag != null)
              Hero(tag: widget.heroTag!, child: _BadgeAvatar(icon: widget.icon))
            else
              _BadgeAvatar(icon: widget.icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(widget.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.9))),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // Gradient sweep highlight overlay
    if(_hovered){
      cardCore = Stack(children:[
        cardCore,
        Positioned.fill(
          child: CustomPaint(painter: _SweepHighlightPainter(progress: _highlightProgress)),
        )
      ]);
    }

    final matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.0016) // perspective
      ..rotateX(rx)
      ..rotateY(ry);

    return LayoutBuilder(
      builder:(ctx,constraints){
        return MouseRegion(
          onEnter: (_){ setState(()=> _hovered=true); },
          onExit: (_){ setState(() { _hovered=false; _txTarget=0; _tyTarget=0; }); },
          child: Listener(
            onPointerHover: (e)=> _updateRel(e, constraints),
            onPointerMove: (e)=> _updateRel(e, constraints),
            child: GestureDetector(
              onTapDown: (_)=> setState(()=> _pressed=true),
              onTapCancel: ()=> setState(()=> _pressed=false),
              onTapUp: (_)=> setState(()=> _pressed=false),
              onTap: widget.onTap,
              child: AnimatedScale(
                scale: hoverScale,
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                child: Transform(
                  alignment: Alignment.center,
                  transform: matrix,
                  child: cardCore,
                ),
              ),
            ),
          ),
        );
      },
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

class _SweepHighlightPainter extends CustomPainter {
  final double progress; // 0..1
  const _SweepHighlightPainter({required this.progress});
  @override
  void paint(Canvas canvas, Size size) {
    final p = progress; // loop
    // Move highlight left->right then repeat
    final x = size.width * p;
    final halfSpan = size.width * 0.35; // width of highlight influence
    final rect = Rect.fromLTWH(x - halfSpan, 0, halfSpan * 2, size.height);
    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.white.withOpacity(0.0),
        Colors.white.withOpacity(0.40),
        Colors.white.withOpacity(0.0),
      ],
      stops: const [0.0, 0.5, 1.0],
    );
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..blendMode = BlendMode.plus;
    canvas.drawRect(rect, paint);
  }
  @override
  bool shouldRepaint(covariant _SweepHighlightPainter old) => old.progress != progress;
}
