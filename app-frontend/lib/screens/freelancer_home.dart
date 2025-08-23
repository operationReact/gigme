import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/session_service.dart';
import '../api/home_api.dart';

// Cover image (network) for profile header banner
const _kCoverImageUrl = 'https://images.unsplash.com/photo-1498050108023-c5249f4df085?auto=format&fit=crop&w=1350&q=80';
// Optional local asset override (put your image at assets/images/cover_banner.jpg and declare in pubspec)
const _kCoverImageAsset = 'assets/images/cover_banner.jpg';

// Brand palette constants
const _kTeal = Color(0xFF00C2A8);
const _kIndigo = Color(0xFF3B82F6);
const _kViolet = Color(0xFF7C3AED);
const _kHeading = Color(0xFF111827);
const _kBody = Color(0xFF374151);
const _kMuted = Color(0xFF6B7280);

// Helper for dark mode checks reused across widgets
bool _isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

class FreelancerHomePage extends StatelessWidget {
  static const routeName = '/home/freelancer';
  const FreelancerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      extendBodyBehindAppBar: true,
      floatingActionButton: _AddPortfolioFab(),
      appBar: AppBar(
        title: const Text('Freelancer Home'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FreelancerHomeLoader(child: Stack(
        children: [
          // Soft neutral gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEEF2FF), Color(0xFFF0FDFA)],
              ),
            ),
          ),
          // Subtle animated color mist overlay
          const _AnimatedBackground(),
          // Gradient hero banner at top
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cs.primary.withValues(alpha: 0.35),
                    cs.secondary.withValues(alpha: 0.25),
                    cs.tertiary.withValues(alpha: 0.2),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                final isWide = constraints.maxWidth >= 960;
                final sidePadding = isWide ? 32.0 : 16.0;
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(sidePadding, 16, sidePadding, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HeaderHero(isWide: isWide),
                      const SizedBox(height: 24),
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // LEFT COLUMN
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: const [
                                  _ProfileOverview(),
                                  SizedBox(height: 20),
                                  _AboutSection(),
                                  SizedBox(height: 20),
                                  _ContactSection(),
                                  SizedBox(height: 20),
                                  _RecentActivitySection(),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            // RIGHT COLUMN
                            Expanded(
                              flex: 7,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const _StatsAndProgress(),
                                  const SizedBox(height: 20),
                                  const _QuickActions(),
                                  const SizedBox(height: 20),
                                  const _PortfolioSection(),
                                  const SizedBox(height: 20),
                                  const _ActiveContracts(),
                                  const SizedBox(height: 20),
                                  const _Recommendations(),
                                  const SizedBox(height: 20),
                                  _ScheduleMini(),
                                ],
                              ),
                            ),
                          ],
                        )
                      else ...[
                        const _ProfileOverview(),
                        const SizedBox(height: 20),
                        const _StatsAndProgress(),
                        const SizedBox(height: 20),
                        const _QuickActions(),
                        const SizedBox(height: 20),
                        const _PortfolioSection(),
                        const SizedBox(height: 20),
                        const _AboutSection(),
                        const SizedBox(height: 20),
                        const _ContactSection(),
                        const SizedBox(height: 20),
                        const _RecentActivitySection(),
                        const SizedBox(height: 20),
                        const _ActiveContracts(),
                        const SizedBox(height: 20),
                        const _Recommendations(),
                        const SizedBox(height: 20),
                        _ScheduleMini(),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      )),
    );
  }
}

class HomeData extends InheritedWidget {
  final FreelancerHomeDto? data; final bool loading; final bool error; final VoidCallback retry;
  const HomeData({super.key, required this.data, required this.loading, required this.error, required this.retry, required Widget child}) : super(child: child);
  static HomeData of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<HomeData>()!;
  @override bool updateShouldNotify(HomeData old)=> data!=old.data || loading!=old.loading || error!=old.error;
}

class FreelancerHomeLoader extends StatefulWidget { final Widget child; const FreelancerHomeLoader({super.key, required this.child}); @override State<FreelancerHomeLoader> createState()=>_FreelancerHomeLoaderState(); }
class _FreelancerHomeLoaderState extends State<FreelancerHomeLoader>{
  FreelancerHomeDto? _dto; bool _loading=true; bool _error=false;
  @override void initState(){ super.initState(); _load(); }
  Future<void> _load() async {
    setState(() { _loading=true; });
    final user = SessionService.instance.user;
    if(user==null){
      setState(() { _loading=false; _error=true; });
      return;
    }
    try {
      final dto = await HomeApi().getHome(user.id);
      if(!mounted) return;
      setState(() { _dto=dto; _loading=false; _error=false; });
    } catch(_){
      if(mounted){
        setState(() { _loading=false; _error=true; });
      }
    }
  }
  @override Widget build(BuildContext context){ return HomeData(data:_dto, loading:_loading, error:_error, retry:_load, child: widget.child); }
}

// Animated subtle moving radial gradients / particles
class _AnimatedBackground extends StatefulWidget {
  const _AnimatedBackground();
  @override
  State<_AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<_AnimatedBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat();
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (ctx, _) {
        final t = _c.value;
        return CustomPaint(
          painter: _BgPainter(t),
          size: Size.infinite,
        );
      },
    );
  }
}

class _BgPainter extends CustomPainter {
  final double t;
  _BgPainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      Colors.purpleAccent.withValues(alpha: 0.12),
      Colors.cyanAccent.withValues(alpha: 0.10),
      Colors.blue.withValues(alpha: 0.07),
    ];
    for (int i = 0; i < colors.length; i++) {
      final progress = (t + i * 0.33) % 1.0;
      final dx = size.width * (0.2 + 0.6 * math.sin(progress * math.pi * 2 + i));
      final dy = size.height * (0.15 + 0.5 * math.cos(progress * math.pi * 2 + i));
      final radius = size.shortestSide * (0.25 + 0.1 * math.sin(progress * math.pi * 2));
      final paint = Paint()
        ..shader = ui.Gradient.radial(
          Offset(dx, dy),
          radius,
          [colors[i], Colors.transparent],
        );
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }
  @override
  bool shouldRepaint(covariant _BgPainter oldDelegate) => oldDelegate.t != t;
}

// Header hero placeholder (title, maybe actions)
class _HeaderHero extends StatelessWidget {
  final bool isWide;
  const _HeaderHero({required this.isWide});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Your Freelance Workspace',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _kHeading,
                    ),
              ),
              const _FindWorkCta(),
              const _ApplyGigsCta(),
            ],
          ),
        ),
        if (isWide)
          Row(
            children: const [
              _GradientButton(icon: Icons.edit_outlined, label: 'Edit Profile'),
              SizedBox(width: 12),
              _OutlineSoftButton(icon: Icons.notifications_outlined, label: 'Notifications'),
            ],
          )
      ],
    );
  }
}

class _FindWorkCta extends StatelessWidget {
  const _FindWorkCta();
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final grad = LinearGradient(colors: isDark ? const [_kIndigo,_kTeal] : const [_kViolet, _kIndigo]);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: (){},
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: grad,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [BoxShadow(color: Color(0x337C3AED), blurRadius: 24, offset: Offset(0,8))],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal:20, vertical:12),
            child: Row(mainAxisSize: MainAxisSize.min, children:[
              const Icon(Icons.travel_explore_outlined, color: Colors.white, size:20),
              const SizedBox(width:8),
              Text('Find Work', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _ApplyGigsCta extends StatelessWidget {
  const _ApplyGigsCta();
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final grad = LinearGradient(colors: isDark ? const [_kTeal,_kViolet] : const [_kTeal, _kViolet]);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {},
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: grad,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [BoxShadow(color: Color(0x3300C2A8), blurRadius: 24, offset: Offset(0, 8))],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.work_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('Apply for Gigs', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      ),
    );
  }
}

// Reusable glassmorphic card
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final GestureTapCallback? onTap;
  const GlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.borderRadius = 20, this.onTap});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassColor = isDark ? Colors.white.withValues(alpha:0.08) : const Color(0xD9FFFFFF);
    final borderClr = isDark ? Colors.white.withValues(alpha:0.18) : Colors.white.withValues(alpha: 0.30);
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: glassColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: borderClr, width: 1),
            boxShadow: [
              if(!isDark) const BoxShadow(color: Color(0x33000000), blurRadius: 30, offset: Offset(0, 10)),
              BoxShadow(color: isDark? Colors.black.withValues(alpha:0.50): const Color(0x1FFFFFFF), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: DefaultTextStyle.merge(
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: _kBody),
            child: child,
          ),
        ),
      ),
    );
    if (onTap != null) {
      return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(borderRadius), child: card);
    }
    return card;
  }
}

// Hover scale effect
class HoverScale extends StatefulWidget {
  final Widget child; final double scale; const HoverScale({super.key, required this.child, this.scale = 1.02});
  @override State<HoverScale> createState() => _HoverScaleState(); }
class _HoverScaleState extends State<HoverScale> { bool _h = false; @override Widget build(BuildContext context){ return MouseRegion(onEnter: (_)=>setState(()=>_h=true), onExit: (_)=>setState(()=>_h=false), child: AnimatedScale(scale: _h?widget.scale:1, duration: const Duration(milliseconds: 180), curve: Curves.easeOut, child: widget.child)); }}

// Profile Overview (picture, name, role, skills, rating, progress)
class _ProfileOverview extends StatelessWidget {
  const _ProfileOverview();
  double _calcCompletion(FreelancerHomeDto? d){ if(d==null) return 0; int total=5; int have=0; if(d.displayName!=null) have++; if(d.professionalTitle!=null) have++; if(d.skillsCsv!=null && d.skillsCsv!.isNotEmpty) have++; if(d.portfolioCount>0) have++; if(d.assignedCount>0) have++; return have/total; }
  @override
  Widget build(BuildContext context){
    final home = HomeData.of(context);
    final d = home.data; final loading = home.loading; final error = home.error;
    final user = SessionService.instance.user;
    final displayName = d?.displayName ?? (user!=null? user.email.split('@').first : 'Guest');
    final title = d?.professionalTitle ?? 'Freelance Professional';
    final skillsSet = (d?.skillsCsv??'').split(',').map((s)=>s.trim()).where((s)=>s.isNotEmpty).toSet();
    final skills = skillsSet.isEmpty? <String>{}:skillsSet;
    final rating = 4.6;
    final profileCompletion = _calcCompletion(d);
    if(error){
      return GlassCard(
        child: SizedBox(
          height:180,
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children:[
              const Icon(Icons.warning_amber_rounded,color:Colors.orange,size:42),
              const SizedBox(height:12),
              const Text('Failed to load home data', style: TextStyle(fontWeight:FontWeight.w600)),
              const SizedBox(height:8),
              ElevatedButton.icon(onPressed: home.retry, icon: const Icon(Icons.refresh), label: const Text('Retry'))
            ]),
          ),
        ),
      );
    }
    final headerInfoChildren = loading ? <Widget>[
      const _SkeletonBar(width:160,height:28),
      const SizedBox(height:10),
      const _SkeletonBar(width:120,height:16),
      const SizedBox(height:14),
      const _SkeletonRating(),
    ] : <Widget>[
      Text(displayName, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight:FontWeight.w800,color:_kHeading)),
      const SizedBox(height:6),
      Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color:_kMuted,fontWeight:FontWeight.w500)),
      const SizedBox(height:10),
      _AnimatedStarRating(rating: rating),
    ];
    final profileCompletionWidget = Row(children:[
      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: profileCompletion, minHeight:10, backgroundColor: _kIndigo.withValues(alpha:0.15), valueColor: const AlwaysStoppedAnimation(_kTeal)))),
      const SizedBox(width:12),
      Text('${(profileCompletion*100).round()}%', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight:FontWeight.w600,color:_kHeading)),
      const SizedBox(width:16),
      const _GradientButton(icon: Icons.edit, label: 'Edit Profile')
    ]);
    return HoverScale(
      child: GlassCard(
        child: SizedBox(
          height:320,
          child: Stack(
            children:[
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin:Alignment.topLeft,
                        end:Alignment.bottomRight,
                        colors:[Color(0xFF3B82F6), Color(0xFF7C3AED)],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20,18,20,16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:[
                          const _GlowingAvatar(loading:false),
                          const SizedBox(width:20),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: headerInfoChildren)),
                          const _FindWorkCta(),
                        ],
                      ),
                      const SizedBox(height:18),
                      if(loading)
                        Wrap(spacing:10, runSpacing:10, children: List.generate(6,(i)=> const _SkeletonChip()))
                      else if(skills.isEmpty)
                        const Text('Add skills to complete your profile', style: TextStyle(fontWeight: FontWeight.w600, color: _kMuted))
                      else
                        Wrap(spacing:10, runSpacing:10, children: skills.map((s)=> _SkillChip(label:s)).toList()),
                      const Spacer(),
                      profileCompletionWidget,
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String label; const _SkillChip({required this.label});
  @override Widget build(BuildContext context) { return _InteractiveChip(label: label); }
}

class _InteractiveChip extends StatefulWidget {
  final String label; const _InteractiveChip({required this.label});
  @override State<_InteractiveChip> createState()=>_InteractiveChipState();
}
class _InteractiveChipState extends State<_InteractiveChip> {
  bool _hover=false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_)=>setState(()=>_hover=true),
      onExit: (_)=>setState(()=>_hover=false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds:220),
        transform: Matrix4.diagonal3Values(_hover?1.07:1.0, _hover?1.07:1.0, 1),
        padding: const EdgeInsets.symmetric(horizontal:14, vertical:8),
        decoration: BoxDecoration(
          color: _hover? (_isDark(context)? _kTeal : _kTeal) : _kTeal.withValues(alpha: _isDark(context)?0.20:0.10),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _kTeal.withValues(alpha:_hover?0.55:0.35)),
          boxShadow: _hover? [BoxShadow(color: _kTeal.withValues(alpha:0.35), blurRadius:14, offset: const Offset(0,6))] : null,
        ),
        child: Text(
          widget.label,
          style: TextStyle(
            color: _hover? Colors.white : _kBody,
            fontWeight: FontWeight.w600,
          ),
        ),
      ));
  }
}

// Animated stats with icons
class _StatsAndProgress extends StatelessWidget { const _StatsAndProgress(); @override Widget build(BuildContext context){ final home = HomeData.of(context); final d = home.data; final loading = home.loading; Widget content; if(loading || d==null){ content = LayoutBuilder(builder:(ctx,c){ final isWide = c.maxWidth>600; final placeholders = List.generate(4,(i)=>Expanded(child: Padding(padding: EdgeInsets.only(right: i==3?0:14), child: _SkeletonBar(width: double.infinity, height:90)))); if(isWide) return Row(children: placeholders); return Column(children: List.generate(4,(i)=> Padding(padding: EdgeInsets.only(bottom: i==3?0:14), child: SizedBox(height:90, child: _SkeletonBar(width:double.infinity, height:90))))); }); } else { final tiles = [ _AnimatedStat(icon: Icons.folder_open_outlined, label: 'Projects', value: d.assignedCount, tint: _kIndigo), _AnimatedStat(icon: Icons.people_outline, label: 'Clients', value: d.distinctClients, tint: _kTeal), _AnimatedStat(icon: Icons.attach_money, label: 'Earnings', value: d.totalBudgetCents~/100, currency: true, tint: _kViolet), _AnimatedStat(icon: Icons.emoji_events_outlined, label: 'Success', value: d.successPercent, suffix: '%', tint: _kIndigo), ]; content = LayoutBuilder(builder:(ctx,c){ final isWide = c.maxWidth>600; if(isWide){ final rowChildren=<Widget>[]; for(var i=0;i<tiles.length;i++){ rowChildren.add(Expanded(child: tiles[i])); if(i!=tiles.length-1) rowChildren.add(const SizedBox(width:14)); } return Row(children: rowChildren); } final col=<Widget>[]; for(var i=0;i<tiles.length;i++){ col.add(tiles[i]); if(i!=tiles.length-1) col.add(const SizedBox(height:14)); } return Column(children: col); }); }
    return HoverScale(child: GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[ Text('Performance Overview', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w700,color:_kHeading)), const SizedBox(height:16), content ]))); }
}
class _GlowingAvatar extends StatelessWidget { final bool loading; const _GlowingAvatar({required this.loading}); @override Widget build(BuildContext context){ return Stack(alignment: Alignment.center, children:[ AnimatedContainer(duration: const Duration(milliseconds:600), width:120, height:120, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: SweepGradient(colors: [_kTeal,_kIndigo,_kViolet,_kTeal], stops: [0,.33,.66,1]), boxShadow:[BoxShadow(color: Color(0x3300C2A8), blurRadius:30, offset: Offset(0,8))])), Container(width:108,height:108, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width:4), color: _kTeal.withValues(alpha:.15)), child: loading? const Center(child: CircularProgressIndicator(strokeWidth:3)) : const Icon(Icons.person, size:48, color: Colors.white)) ]); }}
class _ProfileBannerPattern extends CustomPainter { @override void paint(Canvas canvas, Size size){ final paint = Paint()..style=PaintingStyle.stroke..color=Colors.white.withValues(alpha:0.25)..strokeWidth=1.1; for(double y=0; y<size.height; y+=32){ final path = Path(); for(double x=0; x<=size.width; x+=28){ final dy = math.sin((x+y)/54)*7; if(x==0) path.moveTo(x,y+dy); else path.lineTo(x,y+dy); } canvas.drawPath(path, paint); } } @override bool shouldRepaint(covariant CustomPainter oldDelegate)=>false; }
class _AnimatedStarRating extends StatefulWidget { final double rating; const _AnimatedStarRating({required this.rating}); @override State<_AnimatedStarRating> createState()=>_AnimatedStarRatingState(); }
class _AnimatedStarRatingState extends State<_AnimatedStarRating> with SingleTickerProviderStateMixin { late final AnimationController _c; @override void initState(){ super.initState(); _c=AnimationController(vsync:this,duration: const Duration(milliseconds:800))..forward(); } @override void dispose(){ _c.dispose(); super.dispose(); } @override Widget build(BuildContext context){ final full = widget.rating.floor(); final half = (widget.rating-full)>=0.25 && (widget.rating-full)<0.75; return Row(children: List.generate(5, (i){ IconData ic; if(i<full) ic=Icons.star; else if(i==full && half) ic=Icons.star_half; else ic=Icons.star_outline; return ScaleTransition(scale: CurvedAnimation(parent:_c, curve: Interval(i/5,1, curve: Curves.easeOutBack)), child: Icon(ic, color: Colors.amber, size:22)); })); }}
// Animated stat tile
class _AnimatedStat extends StatefulWidget { final IconData icon; final String label; final int value; final String? suffix; final String? prefix; final bool currency; final Color tint; const _AnimatedStat({required this.icon, required this.label, required this.value, this.suffix, this.prefix, this.currency=false, required this.tint}); @override State<_AnimatedStat> createState()=>_AnimatedStatState(); }
class _AnimatedStatState extends State<_AnimatedStat> with SingleTickerProviderStateMixin { late final AnimationController _ctl; late final Animation<double> _anim; @override void initState(){ super.initState(); _ctl=AnimationController(vsync:this,duration: const Duration(milliseconds:1100)); _anim=CurvedAnimation(parent:_ctl, curve: Curves.easeOutCubic); _ctl.forward(); } @override void dispose(){ _ctl.dispose(); super.dispose(); } String _format(int v){ if(widget.currency){ if(v>=1000){ return '\$'+(v/1000).toStringAsFixed(1)+'k'; } return '\$'+v.toString(); } return v.toString(); } @override Widget build(BuildContext context){ final isDark=_isDark(context); return AnimatedBuilder(animation:_anim, builder:(ctx,_) { final val=(widget.value*_anim.value).clamp(0, widget.value).round(); return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: widget.tint.withValues(alpha:isDark?0.22:0.08), border: Border.all(color: Colors.white.withValues(alpha:isDark?0.18:0.38))), child: Row(children:[ Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors:[widget.tint, widget.tint.withValues(alpha:0.4)])), child: Icon(widget.icon, color: Colors.white, size:22)), const SizedBox(width:14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[ Text('${widget.prefix??''}${_format(val)}${widget.suffix??''}', style: Theme.of(context).textTheme.titleLarge?.copyWith(color:_kHeading, fontWeight: FontWeight.w700)), const SizedBox(height:4), Text(widget.label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color:_kMuted, fontWeight: FontWeight.w500)), const SizedBox(height:6), LinearProgressIndicator(value: (val/widget.value).clamp(0,1), minHeight:4, backgroundColor: widget.tint.withValues(alpha:0.15), valueColor: AlwaysStoppedAnimation(widget.tint)) ])) ])); }); }
}

// Restore previously removed section widgets (simplified styling kept)
class _AboutSection extends StatelessWidget {
  const _AboutSection();
  @override
  Widget build(BuildContext context) {
    return HoverScale(
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('About', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: _kHeading, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Passionate freelancer building performant apps with delightful UX.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: _kBody)),
          ],
        ),
      ),
    );
  }
}
class _ContactSection extends StatelessWidget {
  const _ContactSection();
  @override
  Widget build(BuildContext context) {
    return HoverScale(
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contact', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: _kHeading, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _ContactRow(icon: Icons.email_outlined, label: 'Email', value: SessionService.instance.user?.email ?? 'user@example.com'),
            const SizedBox(height: 8),
            const _ContactRow(icon: Icons.location_on_outlined, label: 'Location', value: 'Remote / Worldwide'),
            const SizedBox(height: 8),
            const _ContactRow(icon: Icons.language_outlined, label: 'Website', value: 'portfolio.example.com'),
          ],
        ),
      ),
    );
  }
}
class _RecentActivitySection extends StatelessWidget {
  const _RecentActivitySection();
  @override
  Widget build(BuildContext context) {
    final activities = [
      'Applied to Mobile MVP',
      'Submitted proposal for Dashboard Revamp',
      'Updated portfolio with Travel App UI',
      'Received feedback from Acme Corp',
    ];
    return HoverScale(
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Activity', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: _kHeading, fontWeight: FontWeight.w600)),
                TextButton(onPressed: () {}, child: const Text('View all')),
              ],
            ),
            const SizedBox(height: 8),
            for (final a in activities)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.bolt_outlined, size: 18, color: _kViolet),
                    const SizedBox(width: 8),
                    Expanded(child: Text(a, style: const TextStyle(color: _kBody))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
class _QuickActions extends StatelessWidget {
  const _QuickActions();
  @override
  Widget build(BuildContext context) {
    return HoverScale(
      child: GlassCard(
        child: Wrap(
          spacing: 12,
            runSpacing: 12,
            children: const [
              _ActionChip(icon: Icons.search, label: 'Find gigs'),
              _ActionChip(icon: Icons.send_outlined, label: 'New proposal'),
              _ActionChip(icon: Icons.schedule, label: 'Availability'),
              _ActionChip(icon: Icons.account_balance_wallet_outlined, label: 'Withdraw'),
              _ActionChip(icon: Icons.ios_share_outlined, label: 'Share card', share: true),
            ],
        ),
      ),
    );
  }
}
class _PortfolioSection extends StatelessWidget { const _PortfolioSection(); @override Widget build(BuildContext context){ final home = HomeData.of(context); final d = home.data; final loading = home.loading; final items = (d?.portfolioItems ?? []).take(8).toList(); return HoverScale(child: GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[ Row(children:[ Text('Portfolio', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w700,color:_kHeading)), const Spacer(), _LargeAddProjectButton(onTap: (){}) ]), const SizedBox(height:16), if(loading) Wrap(spacing:14, runSpacing:14, children: List.generate(4,(i)=> const SizedBox(width:160, height:120, child: _SkeletonBar(width:160, height:120)))) else LayoutBuilder(builder:(ctx,c){ final cols = c.maxWidth>1000?4: c.maxWidth>760?3:2; final gap=14.0; final w=(c.maxWidth - (cols-1)*gap)/cols; final tiles = items.map((pi)=> SizedBox(width:w, child: _DynamicPortfolioCard(title: pi.title, imageUrl: pi.imageUrl))).toList(); while(tiles.length < cols*2){ tiles.add(SizedBox(width:w, child: _EmptyPortfolioCard(onTap: (){}))); } return Wrap(spacing:gap, runSpacing:gap, children: tiles); }) ]))); }}
class _DynamicPortfolioCard extends StatelessWidget {
  final String title; final String? imageUrl; const _DynamicPortfolioCard({required this.title, this.imageUrl});
  @override Widget build(BuildContext context){
    return HoverScale(
      child: AspectRatio(
        aspectRatio:4/3,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha:0.30)),
            gradient: const LinearGradient(colors:[_kIndigo,_kViolet], begin: Alignment.topLeft, end: Alignment.bottomRight),
            image: imageUrl!=null? DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover, opacity:0.25): null,
          ),
          child: Stack(children:[
            Positioned.fill(child: Opacity(opacity:0.10, child: const Icon(Icons.image_outlined, size:64, color:Colors.white))),
            Align(alignment: Alignment.bottomLeft, child: Padding(padding: const EdgeInsets.all(10), child: Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color:Colors.white,fontWeight:FontWeight.w600))))
          ]),
        ),
      ),
    );
  }
}

class _ActiveContracts extends StatelessWidget { const _ActiveContracts(); @override Widget build(BuildContext context){ final home = HomeData.of(context); final d = home.data; final loading = home.loading; final active = (d?.recentAssignedJobs ?? []).where((j)=> j.status=='ASSIGNED').toList(); return HoverScale(child: GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children:[ const _SectionHeader(title:'Active Contracts', actionLabel:'View all'), const SizedBox(height:8), if (loading) ...List.generate(2,(i)=> Padding(padding: EdgeInsets.only(bottom: i==1?0:12), child: const _SkeletonBar(width: double.infinity, height:64))) else if (active.isEmpty) const Text('No active contracts yet', style: TextStyle(color:_kMuted)) else ...active.map((j)=> Padding(padding: const EdgeInsets.only(bottom:12), child: _ContractTile(client: j.clientEmail??'Client', role: j.title, progress: .5, due: '')) ) ]))); }}
class _Recommendations extends StatelessWidget { const _Recommendations(); @override Widget build(BuildContext context){ final home = HomeData.of(context); final d = home.data; final loading = home.loading; final recs = d?.recommendedJobs ?? []; return HoverScale(child: GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [ const _SectionHeader(title:'Recommended for you', actionLabel:'Refresh'), const SizedBox(height:8), if (loading) SizedBox( height:170, child: Row( children: List.generate(3,(i)=> Expanded( child: Padding( padding: EdgeInsets.only(right: i==2?0:12), child: const _SkeletonBar(width: double.infinity, height:170), ), ), ), ), ) else SizedBox( height:170, child: recs.isEmpty ? const Center(child: Text('No recommendations right now')) : ListView.separated( scrollDirection: Axis.horizontal, itemBuilder:(c,i){ final r = recs[i]; final budget = r.budgetCents/100; return _RecCard( title: r.title, budget: '\$${budget.toStringAsFixed(0)}', tags: (d?.skillsCsv??'').split(',').where((s)=>s.trim().isNotEmpty).take(3).toList(), ); }, separatorBuilder: (_, __)=> const SizedBox(width:12), itemCount: recs.length, ), ), ], ))); }}
// Section header used in multiple cards
class _SectionHeader extends StatelessWidget {
  final String title; final String actionLabel; final VoidCallback? onAction;
  const _SectionHeader({required this.title, required this.actionLabel, this.onAction});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: _kHeading),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (actionLabel.isNotEmpty)
          TextButton(
            onPressed: onAction ?? () {},
            child: Text(actionLabel),
          ),
      ],
    );
  }
}

// Mini schedule placeholder card
class _ScheduleMini extends StatelessWidget {
  const _ScheduleMini();
  @override
  Widget build(BuildContext context) {
    final home = HomeData.of(context);
    final loading = home.loading;
    // Placeholder list of upcoming items (no schedule data yet in DTO)
    final upcoming = <String>['Daily stand‑up 9:00 AM', 'Client sync 2:30 PM'];
    return HoverScale(
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(title: 'Schedule', actionLabel: 'Open'),
            const SizedBox(height: 8),
            if (loading)
              ...List.generate(2, (i) => Padding(
                    padding: EdgeInsets.only(bottom: i == 1 ? 0 : 10),
                    child: const _SkeletonBar(width: double.infinity, height: 46),
                  ))
            else if (upcoming.isEmpty)
              const Text('No upcoming events', style: TextStyle(color: _kMuted))
            else
              ...upcoming.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.event_note_outlined, size: 18, color: _kIndigo),
                        const SizedBox(width: 8),
                        Expanded(child: Text(e, style: const TextStyle(color: _kBody))),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}
class _AddPortfolioFab extends StatelessWidget {
  const _AddPortfolioFab();
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: (){},
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
      label: Ink(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [_kViolet,_kIndigo]),
          borderRadius: BorderRadius.all(Radius.circular(40)),
          boxShadow: [BoxShadow(color: Color(0x337C3AED), blurRadius:16, offset: Offset(0,6))],
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal:18, vertical:12),
          child: Row(
            children:[
              Icon(Icons.add, color:Colors.white),
              SizedBox(width:8),
              Text('Add Portfolio Item', style: TextStyle(color:Colors.white,fontWeight:FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback? onTap;
  const _GradientButton({required this.icon, required this.label, this.onTap});
  @override
  Widget build(BuildContext context){
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap ?? (){},
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors:[_kTeal,_kIndigo]),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(color: Color(0x3300C2A8), blurRadius:20, offset: Offset(0,8))],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal:16, vertical:12),
            child: Row(children:[
              Icon(icon, color:Colors.white,size:18),
              const SizedBox(width:8),
              Text(label, style: const TextStyle(color:Colors.white,fontWeight:FontWeight.w600)),
            ]),
          ),
        ),
      ),
    );
  }
}

// Soft outline button used in header actions
class _OutlineSoftButton extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback? onTap;
  const _OutlineSoftButton({required this.icon, required this.label, this.onTap});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap ?? (){},
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal:16, vertical:12),
          decoration: BoxDecoration(
            color: cs.surface.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outline.withValues(alpha: 0.40)),
            boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0,4))],
          ),
          child: Row(children:[
            Icon(icon, size:18, color: _kIndigo),
            const SizedBox(width:8),
            Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, color: _kHeading)),
          ]),
        ),
      ),
    );
  }
}

// Contact row (icon + label + value)
class _ContactRow extends StatelessWidget {
  final IconData icon; final String label; final String value;
  const _ContactRow({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Row(children:[
      Icon(icon, size:18, color:_kIndigo), const SizedBox(width:8),
      Text('$label: ', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color:_kBody,fontWeight:FontWeight.w600)),
      Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color:_kMuted), overflow: TextOverflow.ellipsis))
    ]);
  }
}

// Portfolio item preview (in portfolio section)
class _PortfolioItem extends StatelessWidget {
  final int index; const _PortfolioItem({required this.index});
  @override
  Widget build(BuildContext context) {
    return HoverScale(child: AspectRatio(aspectRatio:4/3, child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha:0.30)),
        gradient: const LinearGradient(colors:[_kIndigo,_kViolet], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Stack(children:[
        Positioned.fill(child: Opacity(opacity:0.10, child: Icon(Icons.image_outlined, size:64, color:Colors.white))),
        Align(alignment: Alignment.bottomLeft, child: Padding(padding: const EdgeInsets.all(10), child: Text('Project ${index+1}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color:Colors.white,fontWeight:FontWeight.w600))))
      ]),
    )));
  }
}

// Large button to add new project (in portfolio section)
class _LargeAddProjectButton extends StatelessWidget {
  final VoidCallback onTap; const _LargeAddProjectButton({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(onTap:onTap, child: DecoratedBox(
      decoration: BoxDecoration(gradient: const LinearGradient(colors:[_kTeal,_kIndigo]), borderRadius: BorderRadius.circular(30), boxShadow: const [BoxShadow(color: Color(0x3300C2A8), blurRadius:20, offset: Offset(0,8))]),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal:18, vertical:10), child: Row(mainAxisSize: MainAxisSize.min, children:[const Icon(Icons.add,color:Colors.white), const SizedBox(width:6), Text('Add Project', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600))])),
    )));
  }
}

// Placeholder card in portfolio section
class _EmptyPortfolioCard extends StatelessWidget {
  final VoidCallback onTap; const _EmptyPortfolioCard({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(onTap:onTap, borderRadius: BorderRadius.circular(18), child: Ink(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: _kIndigo.withValues(alpha:0.25)), color: _kIndigo.withValues(alpha:0.05)),
      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children:[ const Icon(Icons.add_photo_alternate_outlined, color:_kIndigo,size:32), const SizedBox(height:8), Text('Add Project', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color:_kIndigo,fontWeight:FontWeight.w600)) ])),
    ));
  }
}

// Contract tile (in active contracts section)
class _ContractTile extends StatelessWidget {
  final String client; final String role; final double progress; final String due;
  const _ContractTile({required this.client, required this.role, required this.progress, required this.due});
  @override
  Widget build(BuildContext context) {
    return Row(children:[
      const CircleAvatar(radius:20, child: Icon(Icons.business_outlined)), const SizedBox(width:12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
        Text(role, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight:FontWeight.w600)),
        Text(client, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height:6), LinearProgressIndicator(value:progress), const SizedBox(height:4),
        Text(due, style: Theme.of(context).textTheme.bodySmall)
      ]))
    ]);
  }
}

// Recommendation card (in recommendations section)
class _RecCard extends StatelessWidget {
  final String title; final String budget; final List<String> tags; const _RecCard({required this.title, required this.budget, required this.tags});
  @override
  Widget build(BuildContext context) {
    return HoverScale(
      child: GlassCard(
        borderRadius:16,
        padding: const EdgeInsets.all(14),
        child: SizedBox(
          width:220,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:[
              Text(title, maxLines:2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height:6),
              Text(budget, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height:6),
              Wrap(spacing:6, runSpacing:6, children: tags.map((t)=>Chip(label: Text(t))).toList()),
              const Spacer(),
              Align(alignment: Alignment.bottomRight, child: ElevatedButton(onPressed: (){}, child: const Text('View'))),
            ],
          ),
        ),
      ),
    );
  }
}

// Visiting card share helper + action chip (missing earlier)
void _openVisitingCard(BuildContext context) {
  final user = SessionService.instance.user;
  final name = user?.email.split('@').first ?? 'freelancer';
  final shareText = 'Check out my freelance profile: $name';
  Share.share(shareText, subject: 'Freelance Profile');
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile link shared')));
}

class _ActionChip extends StatelessWidget {
  final IconData icon; final String label; final bool share;
  const _ActionChip({required this.icon, required this.label, this.share=false});
  @override
  Widget build(BuildContext context) {
    return HoverScale(
      child: InkWell(
        onTap: () { if (share) _openVisitingCard(context); },
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal:16, vertical:12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors:[_kTeal,_kIndigo]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Color(0x3300C2A8), blurRadius:18, offset: Offset(0,6))],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children:[
              Icon(icon, color:Colors.white,size:20), const SizedBox(width:8),
              Text(label, style: const TextStyle(color:Colors.white,fontWeight:FontWeight.w600))
            ])
        ),
      ),
    );
  }
}

// Skeleton widgets
class _SkeletonBar extends StatefulWidget { final double width; final double height; const _SkeletonBar({required this.width, required this.height}); @override State<_SkeletonBar> createState()=>_SkeletonBarState(); }
class _SkeletonBarState extends State<_SkeletonBar> with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;
  @override void initState(){ super.initState(); _ctl=AnimationController(vsync:this, duration: const Duration(milliseconds:1100))..repeat(); }
  @override void dispose(){ _ctl.dispose(); super.dispose(); }
  @override Widget build(BuildContext context){
    final isDark=_isDark(context);
    return AnimatedBuilder(
      animation:_ctl,
      builder: (_,__) {
        final shimmer = LinearGradient(
          colors:[
            Colors.white.withValues(alpha:isDark?0.07:0.40),
            Colors.white.withValues(alpha:0.05),
            Colors.white.withValues(alpha:isDark?0.07:0.40)
          ],
          stops: const [0,0.5,1],
          begin: Alignment(-1+2*_ctl.value,0),
          end: const Alignment(1,0),
        );
        return Container(
          width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: shimmer,
            ),
        );
      },
    );
  }
}
class _SkeletonChip extends StatelessWidget { const _SkeletonChip(); @override Widget build(BuildContext context){ final isDark=_isDark(context); return Container(width:90, height:34, decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), color: Colors.white.withValues(alpha:isDark?0.10:0.35))); }}
class _SkeletonRating extends StatelessWidget {
  const _SkeletonRating();
  @override Widget build(BuildContext context){ final isDark=_isDark(context); return Row(children: List.generate(5, (i)=> Padding(padding: const EdgeInsets.only(right:4), child: Icon(Icons.star, size:20, color: Colors.white.withValues(alpha:isDark?0.15:0.30))))); }}
