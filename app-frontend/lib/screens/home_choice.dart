import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class HomeChoiceScreen extends StatelessWidget {
  const HomeChoiceScreen({super.key});
  static const route = '/';

  void _go(BuildContext context, UserType type) {
    Navigator.of(context).pushNamed(LoginScreen.route, arguments: type);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _VideoMosaicBackground(),
          Container(color: Colors.black.withOpacity(.55)), // dark overlay for contrast
          Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;
                final double panelWidth = isWide
                    ? 900.0
                    : ((constraints.maxWidth - 32).clamp(0.0, 900.0) as double);
                return ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                    child: Container(
                      width: panelWidth,
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 50),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.10),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(color: Colors.white.withOpacity(.18), width: 1.2),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(.45), blurRadius: 60, spreadRadius: -8, offset: const Offset(0, 30))
                        ],
                      ),
                      child: _Panel(go: _go, isWide: isWide),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final void Function(BuildContext, UserType) go;
  final bool isWide;
  const _Panel({required this.go, required this.isWide});

  @override
  Widget build(BuildContext context) {
    final titleStyle = GoogleFonts.poppins(fontSize: isWide ? 54 : 44, fontWeight: FontWeight.w700, height: 1.05, color: Colors.white, letterSpacing: -.5);
    final subtitleStyle = GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.white70, height: 1.35);

    final cards = [
      _RoleFixedCard(
        title: 'I am Freelancer',
        subtitle: 'Craft a compelling profile, showcase skills, get matched intelligently with quality projects.',
        gradient: const LinearGradient(colors: [Color(0xFF6D83F2), Color(0xFF5146E1)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        icon: Icons.bolt_rounded,
        tag: 'freelancerRole',
        onTap: () => go(context, UserType.freelancer),
      ),
      _RoleFixedCard(
        title: 'I Need Freelancer',
        subtitle: 'Post a gig with clarity and let curated talent surface fast. Manage applicants with insight.',
        gradient: const LinearGradient(colors: [Color(0xFFEE7752), Color(0xFFE73C7E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        icon: Icons.work_outline_rounded,
        tag: 'clientRole',
        onTap: () => go(context, UserType.client),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Connect. Create. Grow.', style: titleStyle),
        const SizedBox(height: 18),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Text('A refined talent marketplace experience. Purpose-built for focus, trust, and velocity.', style: subtitleStyle),
        ),
        const SizedBox(height: 40),
        if (isWide)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: cards.map((c) => SizedBox(width: 360, child: c)).toList(),
          )
        else ...[
          for (final c in cards) ...[
            SizedBox(width: double.infinity, child: c),
            const SizedBox(height: 22)
          ]
        ],
        const SizedBox(height: 38),
        Wrap(
          spacing: 24,
            runSpacing: 12,
            children: [
              _chip('Fast Matching'),
              _chip('Transparent Profiles'),
              _chip('Quality First'),
              _chip('Smart Filters'),
              _chip('Secure'),
            ])
      ],
    );
  }

  Widget _chip(String text) => Chip(
    backgroundColor: Colors.white.withOpacity(.12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    label: Text(text, style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
    side: BorderSide(color: Colors.white.withOpacity(.25), width: 1),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
  );
}

class _RoleFixedCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final IconData icon;
  final String tag;
  final VoidCallback onTap;
  const _RoleFixedCard({required this.title, required this.subtitle, required this.gradient, required this.icon, required this.tag, required this.onTap});

  @override
  State<_RoleFixedCard> createState() => _RoleFixedCardState();
}

class _RoleFixedCardState extends State<_RoleFixedCard> with SingleTickerProviderStateMixin {
  bool _hover = false;
  late AnimationController _c;
  late Animation<double> _scale;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 360));
    _scale = Tween<double>(begin: 1, end: 1.025).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }

  void _setHover(bool h){
    setState(()=> _hover = h);
    if (h) { _c.forward(); } else { _c.reverse(); }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, child) => Transform.scale(scale: _scale.value, child: child),
          child: Container(
            height: 120,
            width: 360,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: widget.gradient,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(.35), blurRadius: 26, offset: const Offset(0, 16)),
                if (_hover) BoxShadow(color: Colors.white.withOpacity(.18), blurRadius: 32, spreadRadius: -6)
              ],
            ),
            child: Row(
              children: [
                Hero(
                  tag: widget.tag,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(.15),
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: Icon(widget.icon, color: Colors.white, size: 30),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(height: 6),
                      Text(widget.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 12.8, fontWeight: FontWeight.w400, height: 1.25, color: Colors.white.withOpacity(.90))),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(Icons.arrow_forward_rounded, color: Colors.white.withOpacity(.85))
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoMosaicBackground extends StatefulWidget {
  const _VideoMosaicBackground();
  @override
  State<_VideoMosaicBackground> createState() => _VideoMosaicBackgroundState();
}

class _VideoMosaicBackgroundState extends State<_VideoMosaicBackground> {
  final List<String> sources = const [
    // Royalty-free short looping samples (replace with your own if desired)
    'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
    'https://samplelib.com/lib/preview/mp4/sample-5s.mp4',
    'https://samplelib.com/lib/preview/mp4/sample-10s.mp4',
    'https://samplelib.com/lib/preview/mp4/sample-15s.mp4',
  ];
  final List<VideoPlayerController> _controllers = [];
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    for (final src in sources) {
      final c = VideoPlayerController.networkUrl(Uri.parse(src))
        ..setLooping(true)
        ..setVolume(0);
      _controllers.add(c);
    }
    try {
      await Future.wait(_controllers.map((c) => c.initialize()));
      for (final c in _controllers) { c.play(); }
      if (mounted) setState(()=> _initialized = true);
    } catch (_) {
      if (mounted) setState(()=> _initialized = false);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      // Animated gradient fallback
      return const _AnimatedGradientFallback();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final cols = w > 1000 ? 4 : w > 700 ? 3 : 2;
        final rows = h > 900 ? 4 : h > 700 ? 3 : 2;
        final total = cols * rows;
        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              childAspectRatio: 1,
            ),
            itemCount: total,
            itemBuilder: (context, i) {
              final controller = _controllers[i % _controllers.length];
              return ColorFiltered(
                colorFilter: ColorFilter.mode(Colors.black.withOpacity(.25), BlendMode.darken),
                child: FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: controller.value.size.width,
                    height: controller.value.size.height,
                    child: VideoPlayer(controller),
                  ),
                ),
              );
            });
      },
    );
  }
}

class _AnimatedGradientFallback extends StatefulWidget {
  const _AnimatedGradientFallback();
  @override
  State<_AnimatedGradientFallback> createState() => _AnimatedGradientFallbackState();
}

class _AnimatedGradientFallbackState extends State<_AnimatedGradientFallback> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.lerp(const Color(0xFF0F2027), const Color(0xFF2C5364), t)!,
                Color.lerp(const Color(0xFF203A43), const Color(0xFF0F2027), 1-t)!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        );
      },
    );
  }
}
