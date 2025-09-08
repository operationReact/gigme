import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'api/auth_api.dart';
import 'screens/sign_in_user.dart';
import 'screens/sign_in_client.dart';
import 'screens/edit_profile_user.dart';
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
import 'services/session_service.dart';
import 'screens/share_card_public.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

// ── Brand palette used by the logo ─────────────────────────────────────────────
const _kTeal = Color(0xFF00C2A8);
const _kIndigo = Color(0xFF3B82F6);
const _kViolet = Color(0xFF7C3AED);
const _kHeading = Color(0xFF111827);
const _kMuted = Color(0xFF6B7280);

/// ===== Brand Logo (same widget used on freelancer home) ======================
class _GmwLogo extends StatelessWidget {
  final double markSize;
  final double fontSize;
  final bool showTagline;
  final double opacity;
  final bool onDark; // true when logo sits on dark backgrounds

  const _GmwLogo({
    this.markSize = 32,
    this.fontSize = 24,
    this.showTagline = false,
    this.opacity = 1,
    this.onDark = false,
    super.key,
  });

  const _GmwLogo.compact()
      : this(markSize: 26, fontSize: 20, showTagline: false);

  const _GmwLogo.watermark()
      : this(markSize: 72, fontSize: 56, showTagline: false, opacity: .06);

  @override
  Widget build(BuildContext context) {
    final head = onDark ? Colors.white : _kHeading;
    final muted = onDark ? Colors.white70 : _kMuted;

    final wordmark = Text.rich(
      TextSpan(children: [
        TextSpan(
          text: 'Gig',
          style: TextStyle(color: head, fontWeight: FontWeight.w800),
        ),
        const TextSpan(
          text: 'Me',
          style: TextStyle(color: _kTeal, fontWeight: FontWeight.w800),
        ),
        TextSpan(
          text: 'Work',
          style: TextStyle(color: head, fontWeight: FontWeight.w800),
        ),
      ]),
      style: TextStyle(fontSize: fontSize, height: 1.0, letterSpacing: 0.2),
    );

    final tagline = Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        'People Need People',
        textAlign: TextAlign.left,
        textHeightBehavior: const TextHeightBehavior(
          applyHeightToFirstAscent: false,
          applyHeightToLastDescent: false,
        ),
        style: TextStyle(
          color: (onDark ? Colors.white.withOpacity(0.92) : muted.withOpacity(0.92)),
          fontSize: (fontSize * 0.46).clamp(10.0, 14.0),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.35,
          height: 1.05,
        ),
      ),
    );

    return Opacity(
      opacity: opacity,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _GmwMark(size: markSize),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              wordmark,
              if (showTagline) tagline,
            ],
          ),
        ],
      ),
    );
  }
}

class _GmwMark extends StatelessWidget {
  final double size;
  const _GmwMark({required this.size, super.key});

  @override
  Widget build(BuildContext context) {
    final h = size;
    final w = size * 1.7;
    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: h,
              height: h,
              decoration: const BoxDecoration(color: _kTeal, shape: BoxShape.circle),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: h,
              height: h,
              decoration: const BoxDecoration(color: _kViolet, shape: BoxShape.circle),
            ),
          ),
          Container(
            width: w * 0.74,
            height: h * 0.34,
            decoration: BoxDecoration(
              color: _kIndigo,
              borderRadius: BorderRadius.circular(h),
              border: Border.all(color: Colors.white, width: h * 0.10),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────

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
    Future.wait([
      PreferencesService.instance.loadDarkMode(),
      PreferencesService.instance.loadUser(),
    ]).then((results) {
      final darkMode = results[0] as bool;
      final user = results[1] as AuthUser?;
      if (user != null) {
        SessionService.instance.setUser(user);
      }
      if (mounted) setState(() { _darkMode = darkMode; _loaded = true; });
    });
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
      navigatorObservers: [routeObserver],
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
        ShareCardPublicPage.routeName: (_) => const ShareCardPublicPage(),
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
        // Small brand logo at top-left (white text for dark video header)
        title: const _GmwLogo(markSize: 22, fontSize: 18, showTagline: false, onDark: true),
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
                                  // ↑ added extra vertical padding for breathing room
                                  padding: const EdgeInsets.fromLTRB(24, 36, 24, 36),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                                  ),
                                  child: LayoutBuilder(
                                    builder: (context, constraints){
                                      final available = constraints.maxWidth;
                                      final isWide = available >= 760;
                                      final cardWidth = isWide ? 360.0 : available < 340 ? available : (available - 0);
                                      final sideBySide = isWide;

                                      // Responsive hero sizing
                                      final heroMark = isWide ? 56.0 : 46.0;
                                      final heroFont = isWide ? 44.0 : 36.0;

                                      // Professional vertical gap between logo and cards (36–72 px)
                                      final screenH = MediaQuery.of(context).size.height;
                                      final verticalGap = math.min(math.max(screenH * 0.08, 36.0), 72.0);

                                      final headingOffset = _parallaxY * -20; // invert for subtle lift
                                      final cardsOffset = _parallaxY * 12;

                                      final children = [
                                        _ActionCard(
                                          icon: Icons.person_outline,
                                          title: 'I am Freelancer or Professional',
                                          subtitle: 'Find work and get paid',
                                          gradient: LinearGradient(colors: [cs.secondary, cs.tertiary]),
                                          heroTag: 'hero-freelancer',
                                          width: cardWidth,
                                          onTap: () => Navigator.of(context).pushNamed(SignInUserPage.routeName),
                                        ),
                                        _ActionCard(
                                          icon: Icons.business_center_outlined,
                                          title: 'I Need a Freelancer or Professional',
                                          subtitle: 'Post jobs and hire verified talent',
                                          gradient: LinearGradient(colors: [cs.tertiary, cs.secondary]),
                                          heroTag: 'hero-client',
                                          width: cardWidth,
                                          onTap: () => Navigator.of(context).pushNamed(SignInClientPage.routeName),
                                        ),
                                      ];
                                      return SingleChildScrollView(
                                        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                              // Center hero brand logo (white/ inverse)
                                              Transform.translate(
                                                offset: Offset(0, headingOffset),
                                                child: Align(
                                                  alignment: Alignment.center,
                                                  child: _GmwLogo(
                                                    markSize: heroMark,
                                                    fontSize: heroFont,
                                                    showTagline: true,
                                                    onDark: true,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: verticalGap),
                                              Transform.translate(
                                                offset: Offset(0, cardsOffset),
                                                child: sideBySide
                                                    ? Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    for (int i = 0; i < children.length; i++) ...[
                                                      children[i],
                                                      if (i < children.length - 1) const SizedBox(width: 20),
                                                    ]
                                                  ],
                                                )
                                                    : Column(
                                                  children: [
                                                    for (int i = 0; i < children.length; i++) ...[
                                                      children[i],
                                                      if (i < children.length - 1) const SizedBox(height: 16),
                                                    ]
                                                  ],
                                                ),
                                              ),
                                              // small bottom spacer so cards don’t hug the panel edge
                                              SizedBox(height: verticalGap * 0.6),
                                            ],
                                          ),
                                        ),
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
  const _ActionCard({super.key, required this.icon, required this.title, required this.subtitle, required this.gradient, required this.onTap, this.heroTag, this.width});

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
    _txTarget = dx.clamp(-1,1);
    _tyTarget = dy.clamp(-1,1);
  }

  @override
  void dispose(){ _anim.dispose(); super.dispose(); }

  double get _highlightProgress => _anim.value; // 0..1 looping

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hoverScale = 1.0 + (_hovered? 0.02 : 0.0) - (_pressed? 0.02 : 0.0);
    const maxDeg = 8.0;
    final rx = (-_ty) * (maxDeg * math.pi / 180);
    final ry = (_tx) * (maxDeg * math.pi / 180);
    final shadowLift = _hovered ? -4.0 : 0.0;
    final blur = 16 + (_hovered? 10 : 0);
    final spread = _hovered? 2.0 : 0.5;
    final shadowColor = cs.tertiary.withOpacity(_hovered? 0.28 : 0.15);

    // ——— Professional, lighter typography ———
    final titleBase = Theme.of(context).textTheme.titleLarge?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w600,   // lighter than w800
      height: 1.15,
      letterSpacing: 0.15,
      fontSize: 20,
      shadows: const [ Shadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 1)) ],
    ) ?? const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w600,
      height: 1.15,
      letterSpacing: 0.15,
      fontSize: 20,
      shadows: [Shadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 1))],
    );

    final subtitleBase = Theme.of(context).textTheme.bodyLarge?.copyWith(
      color: Colors.white.withOpacity(0.95),
      fontWeight: FontWeight.w500,
      height: 1.35,
      letterSpacing: 0.05,
      fontSize: 14.5,
      shadows: const [ Shadow(color: Color(0x14000000), blurRadius: 5, offset: Offset(0, 1)) ],
    ) ?? const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w500,
      height: 1.35,
      letterSpacing: 0.05,
      fontSize: 14.5,
      shadows: [Shadow(color: Color(0x14000000), blurRadius: 5, offset: Offset(0, 1))],
    );

    final titleStyle = titleBase.copyWith(
      letterSpacing: _hovered ? 0.18 : 0.15,
      color: Colors.white.withOpacity(_hovered ? 1.0 : 0.98),
    );
    final subtitleStyle = subtitleBase.copyWith(
      color: Colors.white.withOpacity(_hovered ? 0.98 : 0.92),
    );

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
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOut,
                    style: titleStyle,
                    child: Text(
                      widget.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOut,
                    style: subtitleStyle,
                    child: Text(
                      widget.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if(_hovered){
      cardCore = Stack(children:[
        cardCore,
        Positioned.fill(
          child: CustomPaint(painter: _SweepHighlightPainter(progress: _highlightProgress)),
        )
      ]);
    }

    final matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.0016)
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
    for (int i = 0; i < 24; i++) {
      final phase = (i * 0.261799) + t * 6.2831853;
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
    final p = progress;
    final x = size.width * p;
    final halfSpan = size.width * 0.35;
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
