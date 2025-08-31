import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import '../services/session_service.dart';
import '../api/home_api.dart';
import '../widgets/apply_for_work_cta.dart';
import '../job_service.dart';
import '../widgets/profile_preview_card.dart';
import '../main.dart';

// Brand palette constants
const _kTeal = Color(0xFF00C2A8);
const _kIndigo = Color(0xFF3B82F6);
const _kViolet = Color(0xFF7C3AED);
const _kHeading = Color(0xFF111827);
const _kBody = Color(0xFF374151);
const _kMuted = Color(0xFF6B7280);

// Helper for dark mode checks reused across widgets
bool _isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

class FreelancerHomePage extends StatefulWidget {
  static const routeName = '/home/freelancer';
  const FreelancerHomePage({super.key});

  @override
  State<FreelancerHomePage> createState() => _FreelancerHomePageState();
}

class _FreelancerHomePageState extends State<FreelancerHomePage> {
  int? _newJobsCount;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCount();
  }

  Future<void> _loadCount() async {
    try {
      final count = await JobService().countNewJobs();
      if (mounted) {
        setState(() {
          _newJobsCount = count;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _newJobsCount = null;
          _loading = false;
        });
      }
    }
  }

  void _onApplyPressed() {
    // TODO: Implement navigation or action for applying to work
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      extendBodyBehindAppBar: true,
      floatingActionButton: isMobile
          ? ApplyForWorkCta(
        initialCount: _newJobsCount,
        onPressed: _onApplyPressed,
        dense: true,
        showLabel: true,
      )
          : null,
      appBar: AppBar(
        title: const Text('Freelancer Home'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!isMobile)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
              child: ApplyForWorkCta(
                initialCount: _newJobsCount,
                onPressed: _onApplyPressed,
                dense: true,
                showLabel: true,
              ),
            ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
              ),
              // Dot indicator for unread notifications
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: FreelancerHomeLoader(
        child: Stack(
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
        ),
      ),
    );
  }
}

class HomeData extends InheritedWidget {
  final FreelancerHomeDto? data;
  final bool loading;
  final bool error;
  final VoidCallback retry;
  const HomeData({
    super.key,
    required this.data,
    required this.loading,
    required this.error,
    required this.retry,
    required Widget child,
  }) : super(child: child);

  static HomeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HomeData>()!;

  @override
  bool updateShouldNotify(HomeData old) =>
      data != old.data || loading != old.loading || error != old.error;
}

class FreelancerHomeLoader extends StatefulWidget {
  final Widget child;
  const FreelancerHomeLoader({super.key, required this.child});
  @override
  State<FreelancerHomeLoader> createState() => _FreelancerHomeLoaderState();
}

class _FreelancerHomeLoaderState extends State<FreelancerHomeLoader>
    with RouteAware {
  FreelancerHomeDto? _dto;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _load();
  }

  @override
  void didPush() {
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });
    final user = SessionService.instance.user;
    if (user == null) {
      setState(() {
        _loading = false;
        _error = true;
      });
      return;
    }
    try {
      final dto = await HomeApi().getHome(user.id);
      if (!mounted) return;
      setState(() {
        _dto = dto;
        _loading = false;
        _error = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return HomeData(
      data: _dto,
      loading: _loading,
      error: _error,
      retry: _load,
      child: widget.child,
    );
  }
}

// Animated subtle moving radial gradients / particles
class _AnimatedBackground extends StatefulWidget {
  const _AnimatedBackground();
  @override
  State<_AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<_AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

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
      final dx =
          size.width * (0.2 + 0.6 * math.sin(progress * math.pi * 2 + i));
      final dy =
          size.height * (0.15 + 0.5 * math.cos(progress * math.pi * 2 + i));
      final radius = size.shortestSide *
          (0.25 + 0.1 * math.sin(progress * math.pi * 2));
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
  bool shouldRepaint(covariant _BgPainter oldDelegate) =>
      oldDelegate.t != t;
}

// Header hero
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
            ],
          ),
        ),
        if (isWide)
          Row(
            children: const [
              _GradientButton(
                  icon: Icons.edit_outlined, label: 'Edit Profile'),
              SizedBox(width: 12),
              _OutlineSoftButton(
                  icon: Icons.notifications_outlined, label: 'Notifications'),
            ],
          )
      ],
    );
  }
}

// Animated stats with icons
class _StatsAndProgress extends StatelessWidget {
  const _StatsAndProgress();
  @override
  Widget build(BuildContext context) {
    final home = HomeData.of(context);
    final d = home.data;
    final loading = home.loading;

    Widget content;
    if (loading || d == null) {
      content = LayoutBuilder(builder: (ctx, c) {
        final isWide = c.maxWidth > 600;
        final placeholders = List.generate(
          4,
              (i) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == 3 ? 0 : 14),
              child: const _SkeletonBar(width: double.infinity, height: 90),
            ),
          ),
        );
        if (isWide) return Row(children: placeholders);
        return Column(
          children: List.generate(
            4,
                (i) => Padding(
              padding: EdgeInsets.only(bottom: i == 3 ? 0 : 14),
              child: const SizedBox(
                height: 90,
                child: _SkeletonBar(width: double.infinity, height: 90),
              ),
            ),
          ),
        );
      });
    } else {
      final tiles = [
        _AnimatedStat(
            icon: Icons.folder_open_outlined,
            label: 'Projects',
            value: d.assignedCount,
            tint: _kIndigo),
        _AnimatedStat(
            icon: Icons.people_outline,
            label: 'Clients',
            value: d.distinctClients,
            tint: _kTeal),
        _AnimatedStat(
            icon: Icons.attach_money,
            label: 'Earnings',
            value: d.totalBudgetCents ~/ 100,
            currency: true,
            tint: _kViolet),
        _AnimatedStat(
            icon: Icons.emoji_events_outlined,
            label: 'Success',
            value: d.successPercent,
            suffix: '%',
            tint: _kIndigo),
      ];
      content = LayoutBuilder(builder: (ctx, c) {
        final isWide = c.maxWidth > 600;
        if (isWide) {
          final rowChildren = <Widget>[];
          for (var i = 0; i < tiles.length; i++) {
            rowChildren.add(Expanded(child: tiles[i]));
            if (i != tiles.length - 1) {
              rowChildren.add(const SizedBox(width: 14));
            }
          }
          return Row(children: rowChildren);
        }
        final col = <Widget>[];
        for (var i = 0; i < tiles.length; i++) {
          col.add(tiles[i]);
          if (i != tiles.length - 1) col.add(const SizedBox(height: 14));
        }
        return Column(children: col);
      });
    }

    return HoverScale(
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Performance Overview',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700, color: _kHeading)),
            const SizedBox(height: 16),
            content
          ],
        ),
      ),
    );
  }
}

class _GlowingAvatar extends StatelessWidget {
  final bool loading;
  const _GlowingAvatar({required this.loading});
  @override
  Widget build(BuildContext context) {
    return Stack(alignment: Alignment.center, children: [
      AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          width: 120,
          height: 120,
          decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(colors: [
                _kTeal,
                _kIndigo,
                _kViolet,
                _kTeal
              ], stops: [
                0,
                .33,
                .66,
                1
              ]),
              boxShadow: [
                BoxShadow(
                    color: Color(0x3300C2A8),
                    blurRadius: 30,
                    offset: Offset(0, 8))
              ])),
      Container(
          width: 108,
          height: 108,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              color: _kTeal.withValues(alpha: .15)),
          child: loading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 3))
              : const Icon(Icons.person, size: 48, color: Colors.white))
    ]);
  }
}

class _AnimatedStarRating extends StatefulWidget {
  final double rating;
  const _AnimatedStarRating({required this.rating});
  @override
  State<_AnimatedStarRating> createState() => _AnimatedStarRatingState();
}

class _AnimatedStarRatingState extends State<_AnimatedStarRating>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final full = widget.rating.floor();
    final half =
        (widget.rating - full) >= 0.25 && (widget.rating - full) < 0.75;
    return Row(
      children: List.generate(5, (i) {
        IconData ic;
        if (i < full) {
          ic = Icons.star;
        } else if (i == full && half) {
          ic = Icons.star_half;
        } else {
          ic = Icons.star_outline;
        }
        return ScaleTransition(
          scale: CurvedAnimation(
              parent: _c,
              curve: Interval(i / 5, 1, curve: Curves.easeOutBack)),
          child: Icon(ic, color: Colors.amber, size: 22),
        );
      }),
    );
  }
}

// Animated stat tile
class _AnimatedStat extends StatefulWidget {
  final IconData icon;
  final String label;
  final int value;
  final String? suffix;
  final String? prefix;
  final bool currency;
  final Color tint;
  const _AnimatedStat({
    required this.icon,
    required this.label,
    required this.value,
    this.suffix,
    this.prefix,
    this.currency = false,
    required this.tint,
  });
  @override
  State<_AnimatedStat> createState() => _AnimatedStatState();
}

class _AnimatedStatState extends State<_AnimatedStat>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;
  late final Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));
    _anim = CurvedAnimation(parent: _ctl, curve: Curves.easeOutCubic);
    _ctl.forward();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  String _format(int v) {
    if (widget.currency) {
      if (v >= 1000) {
        return '\$' + (v / 1000).toStringAsFixed(1) + 'k';
      }
      return '\$' + v.toString();
    }
    return v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark(context);
    return AnimatedBuilder(
      animation: _anim,
      builder: (ctx, _) {
        final val =
        (widget.value * _anim.value).clamp(0, widget.value).round();
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: widget.tint.withValues(alpha: isDark ? 0.22 : 0.08),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.18 : 0.38),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [widget.tint, widget.tint.withValues(alpha: 0.4)],
                  ),
                ),
                child: Icon(widget.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.prefix ?? ''}${_format(val)}${widget.suffix ?? ''}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: _kHeading, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.label,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: _kMuted, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: (val / widget.value).clamp(0, 1),
                      minHeight: 4,
                      backgroundColor: widget.tint.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation(widget.tint),
                    )
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
}

// ---------- ABOUT / CONTACT / ACTIVITY / ACTIONS ----------
class _AboutSection extends StatelessWidget {
  const _AboutSection();
  @override
  Widget build(BuildContext context) {
    return HoverScale(
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('About',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: _kHeading, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'Passionate freelancer building performant apps with delightful UX.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: _kBody),
            ),
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
            Text('Contact',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: _kHeading, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _ContactRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: SessionService.instance.user?.email ?? 'user@example.com'),
            const SizedBox(height: 8),
            const _ContactRow(
                icon: Icons.location_on_outlined,
                label: 'Location',
                value: 'Remote / Worldwide'),
            const SizedBox(height: 8),
            const _ContactRow(
                icon: Icons.language_outlined,
                label: 'Website',
                value: 'portfolio.example.com'),
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
                Text('Recent Activity',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: _kHeading, fontWeight: FontWeight.w600)),
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
                    Expanded(
                      child: Text(a, style: const TextStyle(color: _kBody)),
                    ),
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
            _ActionChip(icon: Icons.send_outlined, label: 'New proposal'),
            _ActionChip(icon: Icons.schedule, label: 'Availability'),
            _ActionChip(
                icon: Icons.account_balance_wallet_outlined, label: 'Withdraw'),
            _ActionChip(
                icon: Icons.ios_share_outlined, label: 'Share card', share: true),
          ],
        ),
      ),
    );
  }
}

// ------------------ RICH, SEGMENTED PORTFOLIO SECTION ------------------
class _PortfolioSection extends StatefulWidget {
  const _PortfolioSection();
  @override
  State<_PortfolioSection> createState() => _PortfolioSectionState();
}

class _PortfolioSectionState extends State<_PortfolioSection> {
  // 0: Images, 1: Videos, 2: Documents
  int _tabIndex = 0;
  bool _loading = true;
  List<HomePortfolioDto> _items = [];
  final List<String> _mediaTypes = ['IMAGE', 'VIDEO', 'DOCUMENT'];

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  void _fetchItems() async {
    setState(() { _loading = true; });
    final home = HomeData.of(context);
    final d = home.data;
    if (d == null) {
      setState(() { _items = []; _loading = false; });
      return;
    }
    try {
      final items = await HomeApi().getPortfolioItems(d.userId, mediaType: _mediaTypes[_tabIndex]);
      if (mounted) setState(() { _items = items; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _items = []; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final home = HomeData.of(context);
    final d = home.data;

    Widget _segmentedTabs() {
      final labels = const ['Images', 'Videos', 'Documents'];
      final gradients = const [
        [ _kIndigo, _kViolet ],
        [ Color(0xFF0EA5E9), _kViolet ],
        [ Color(0xFF22C55E), _kIndigo ],
      ];
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1),
          boxShadow: const [
            BoxShadow(color: Color(0x12000000), blurRadius: 8, offset: Offset(0, 2))
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final selected = i == _tabIndex;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Material(
                color: Colors.transparent,
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: selected
                        ? LinearGradient(
                            colors: gradients[i],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      if (_tabIndex != i) {
                        setState(() { _tabIndex = i; });
                        _fetchItems();
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            labels[i],
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: selected ? Colors.white : _kBody,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: selected ? Colors.white : Colors.white.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              // Show count for current tab only
                              selected ? _items.length.toString() : '',
                              style: TextStyle(
                                color: selected ? _kHeading : _kHeading,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      );
    }

    Widget _grid(List<HomePortfolioDto> list) {
      return LayoutBuilder(builder: (ctx, c) {
        final cols = c.maxWidth > 1100 ? 4 : c.maxWidth > 820 ? 3 : 2;
        const gap = 16.0;
        final w = (c.maxWidth - (cols - 1) * gap) / cols;

        final tiles = <Widget>[];
        tiles.addAll(list.map((pi) {
          final kind = pi.mediaType.toUpperCase() == 'VIDEO'
              ? _MediaKind.video
              : (pi.mediaType.toUpperCase() == 'DOCUMENT'
                  ? _MediaKind.document
                  : _MediaKind.image);
          return SizedBox(
            width: w,
            child: _MediaPortfolioCard(
              title: pi.title.isEmpty ? 'Untitled' : pi.title,
              fileUrl: pi.fileUrl,
              kind: kind,
            ),
          );
        }));

        while (tiles.length < cols * 2) {
          tiles.add(SizedBox(width: w, child: _EmptyPortfolioCard(onTap: () {})));
        }

        return Wrap(spacing: gap, runSpacing: gap, children: tiles);
      });
    }

    Widget _tabBody() {
      if (_loading) {
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: List.generate(6,
                  (i) => const SizedBox(width: 160, height: 120, child: _Shimmer())),
        );
      }
      if (_items.isEmpty) {
        final icons = [Icons.image_outlined, Icons.play_circle_outline, Icons.description_outlined];
        final subtitles = [
          'No images yet. Click “Add Project”.',
          'No videos yet. Click “Add Project”.',
          'No documents yet. Click “Add Project”.',
        ];
        final titles = ['Images', 'Videos', 'Documents'];
        return _EmptyState(
          icon: icons[_tabIndex],
          title: titles[_tabIndex],
          subtitle: subtitles[_tabIndex],
        );
      }
      return _grid(_items);
    }

    return HoverScale(
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(
                  'Portfolio',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700, color: _kHeading),
                ),
                const Spacer(),
                Tooltip(
                  message: 'Add Project',
                  child: _LargeAddProjectButton(onTap: () {
                    // Optionally, after adding a project, call _fetchItems();
                  }),
                ),
              ]),
              const SizedBox(height: 14),
              _segmentedTabs(),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: KeyedSubtree(
                  key: ValueKey(_tabIndex),
                  child: _tabBody(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _MediaKind { image, video, document }

class _MediaPortfolioCard extends StatefulWidget {
  final String title;
  final String? fileUrl;
  final _MediaKind kind;
  const _MediaPortfolioCard({
    required this.title,
    this.fileUrl,
    required this.kind,
  });

  @override
  State<_MediaPortfolioCard> createState() => _MediaPortfolioCardState();
}

class _MediaPortfolioCardState extends State<_MediaPortfolioCard>
    with SingleTickerProviderStateMixin {
  bool _hover = false;
  late final AnimationController _shineCtrl =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
    ..repeat();

  @override
  void dispose() {
    _shineCtrl.dispose();
    super.dispose();
  }

  List<Color> get _grad {
    switch (widget.kind) {
      case _MediaKind.video:
        return const [Color(0xFF0EA5E9), Color(0xFF7C3AED)];
      case _MediaKind.document:
        return const [Color(0xFF22C55E), Color(0xFF3B82F6)];
      case _MediaKind.image:
      default:
        return const [Color(0xFF3B82F6), Color(0xFF7C3AED)];
    }
  }

  IconData get _typeIcon {
    switch (widget.kind) {
      case _MediaKind.video:
        return Icons.play_circle_fill_rounded;
      case _MediaKind.document:
        return Icons.description_rounded;
      case _MediaKind.image:
      default:
        return Icons.image_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(18);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: _hover
              ? const [
            BoxShadow(
                color: Color(0x22000000),
                blurRadius: 20,
                offset: Offset(0, 10))
          ]
              : const [
            BoxShadow(
                color: Color(0x14000000),
                blurRadius: 12,
                offset: Offset(0, 6))
          ],
          gradient: LinearGradient(
            colors: _grad.map((c) => c.withValues(alpha: 0.18)).toList(),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Stack(
            children: [
              // media preview or gradient
              Positioned.fill(
                child: widget.fileUrl != null &&
                    widget.kind != _MediaKind.document
                    ? Image.network(widget.fileUrl!, fit: BoxFit.cover)
                    : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _grad,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),

              // overlay gradient for readability
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.05),
                        Colors.black.withValues(alpha: 0.20),
                        Colors.black.withValues(alpha: 0.45),
                      ],
                    ),
                  ),
                ),
              ),

              // animated shine
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _shineCtrl,
                    builder: (_, __) {
                      final t = _shineCtrl.value;
                      return Transform.translate(
                        offset: Offset((t * 2 - 1) * 200, 0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.0),
                                Colors.white.withValues(alpha: 0.14),
                                Colors.white.withValues(alpha: 0.0),
                              ],
                              stops: const [0.35, 0.5, 0.65],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // top-right type chip
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(_typeIcon, size: 16, color: _kHeading),
                      const SizedBox(width: 6),
                      Text(
                        widget.kind == _MediaKind.image
                            ? 'Image'
                            : widget.kind == _MediaKind.video
                            ? 'Video'
                            : 'Doc',
                        style: const TextStyle(
                          color: _kHeading,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // title + actions
              Positioned(
                left: 12,
                right: 12,
                bottom: 10,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _ActionIcon(
                      icon: Icons.open_in_new_rounded,
                      onTap: () {
                        // TODO: open preview dialog/viewer
                      },
                    ),
                    const SizedBox(width: 6),
                    _ActionIcon(
                      icon: widget.kind == _MediaKind.document
                          ? Icons.download_rounded
                          : Icons.fullscreen_rounded,
                      onTap: () {
                        // TODO: open full screen or download
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ActionIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Material(
        color: Colors.white.withValues(alpha: 0.9),
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(icon, size: 18, color: _kHeading),
          ),
        ),
      ),
    );
  }
}

// ----------------- OTHER SECTIONS -----------------
class _ActiveContracts extends StatelessWidget {
  const _ActiveContracts();
  @override
  Widget build(BuildContext context) {
    final home = HomeData.of(context);
    final d = home.data;
    final loading = home.loading;
    final active =
    (d?.recentAssignedJobs ?? []).where((j) => j.status == 'ASSIGNED').toList();

    return HoverScale(
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionHeader(title: 'Active Contracts', actionLabel: 'View all'),
            const SizedBox(height: 8),
            if (loading)
              ...List.generate(
                2,
                    (i) => Padding(
                  padding: EdgeInsets.only(bottom: i == 1 ? 0 : 12),
                  child: const _SkeletonBar(width: double.infinity, height: 64),
                ),
              )
            else if (active.isEmpty)
              const Text('No active contracts yet', style: TextStyle(color: _kMuted))
            else
              ...active.map(
                    (j) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ContractTile(
                    client: j.clientEmail ?? 'Client',
                    role: j.title,
                    progress: .5,
                    due: '',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Recommendations extends StatelessWidget {
  const _Recommendations();
  @override
  Widget build(BuildContext context) {
    final home = HomeData.of(context);
    final d = home.data;
    final loading = home.loading;
    final recs = d?.recommendedJobs ?? [];
    return HoverScale(
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionHeader(title: 'Recommended for you', actionLabel: 'Refresh'),
            const SizedBox(height: 8),
            if (loading)
              SizedBox(
                height: 170,
                child: Row(
                  children: List.generate(
                    3,
                        (i) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: i == 2 ? 0 : 12),
                        child: const _SkeletonBar(width: double.infinity, height: 170),
                      ),
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                height: 170,
                child: recs.isEmpty
                    ? const Center(child: Text('No recommendations right now'))
                    : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (c, i) {
                    final r = recs[i];
                    final budget = r.budgetCents / 100;
                    return _RecCard(
                      title: r.title,
                      budget: '\$${budget.toStringAsFixed(0)}',
                      tags: (d?.skillsCsv ?? '')
                          .split(',')
                          .where((s) => s.trim().isNotEmpty)
                          .take(3)
                          .toList(),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemCount: recs.length,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Section header used in multiple cards
class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback? onAction;
  const _SectionHeader(
      {required this.title, required this.actionLabel, this.onAction});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700, color: _kHeading),
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
    final upcoming = <String>['Daily stand-up 9:00 AM', 'Client sync 2:30 PM'];
    return HoverScale(
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(title: 'Schedule', actionLabel: 'Open'),
            const SizedBox(height: 8),
            if (loading)
              ...List.generate(
                2,
                    (i) => Padding(
                  padding: EdgeInsets.only(bottom: i == 1 ? 0 : 10),
                  child: const _SkeletonBar(width: double.infinity, height: 46),
                ),
              )
            else if (upcoming.isEmpty)
              const Text('No upcoming events', style: TextStyle(color: _kMuted))
            else
              ...upcoming.map(
                    (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.event_note_outlined,
                          size: 18, color: _kIndigo),
                      const SizedBox(width: 8),
                      Expanded(
                          child:
                          Text(e, style: const TextStyle(color: _kBody))),
                    ],
                  ),
                ),
              ),
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
      onPressed: () {},
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
      label: Ink(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [_kViolet, _kIndigo]),
          borderRadius: BorderRadius.all(Radius.circular(40)),
          boxShadow: [
            BoxShadow(color: Color(0x337C3AED), blurRadius: 16, offset: Offset(0, 6))
          ],
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.add, color: Colors.white),
              SizedBox(width: 8),
              Text('Add Portfolio Item',
                  style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

// --- PLACEHOLDER / SHARED WIDGETS ---
class _GradientButton extends StatelessWidget {
  final IconData icon;
  final String label;
  const _GradientButton({super.key, required this.icon, required this.label});
  @override
  Widget build(BuildContext context) =>
      ElevatedButton.icon(onPressed: () {}, icon: Icon(icon), label: Text(label));
}

class _OutlineSoftButton extends StatelessWidget {
  final IconData icon;
  final String label;
  const _OutlineSoftButton({super.key, required this.icon, required this.label});
  @override
  Widget build(BuildContext context) =>
      OutlinedButton.icon(onPressed: () {}, icon: Icon(icon), label: Text(label));
}

class _SkeletonBar extends StatelessWidget {
  final double width;
  final double height;
  const _SkeletonBar({super.key, required this.width, required this.height});
  @override
  Widget build(BuildContext context) =>
      Container(width: width, height: height, color: Colors.grey.shade300);
}

class _SkeletonRating extends StatelessWidget {
  const _SkeletonRating({super.key});
  @override
  Widget build(BuildContext context) =>
      Row(children: List.generate(5, (i) => Icon(Icons.star, color: Colors.grey.shade300)));
}

class _SkeletonChip extends StatelessWidget {
  const _SkeletonChip({super.key});
  @override
  Widget build(BuildContext context) =>
      Chip(label: Container(width: 40, height: 12, color: Colors.grey.shade300));
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool share;
  const _ActionChip({super.key, required this.icon, required this.label, this.share = false});
  @override
  Widget build(BuildContext context) =>
      ActionChip(label: Text(label), avatar: Icon(icon));
}

class _LargeAddProjectButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LargeAddProjectButton({super.key, required this.onTap});
  @override
  Widget build(BuildContext context) =>
      ElevatedButton.icon(onPressed: onTap, icon: const Icon(Icons.add), label: const Text('Add Project'));
}

class _EmptyPortfolioCard extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyPortfolioCard({super.key, required this.onTap});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 160,
    child: Card(
      child: InkWell(
        onTap: onTap,
        child: const SizedBox(
            width: 100, height: 80, child: Center(child: Icon(Icons.add))),
      ),
    ),
  );
}

class _RecCard extends StatelessWidget {
  final String title;
  final String budget;
  final List<String> tags;
  const _RecCard(
      {super.key, required this.title, required this.budget, required this.tags});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 250,
    child: Card(child: ListTile(title: Text(title), subtitle: Text(budget))),
  );
}

class _ContractTile extends StatelessWidget {
  final String client;
  final String role;
  final double progress;
  final String due;
  const _ContractTile(
      {super.key,
        required this.client,
        required this.role,
        required this.progress,
        required this.due});
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    title: Text(role, style: const TextStyle(fontWeight: FontWeight.w600)),
    subtitle: Text(client),
    trailing: SizedBox(
      width: 140,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: LinearProgressIndicator(value: progress),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right),
        ],
      ),
    ),
  );
}

class _Shimmer extends StatefulWidget {
  const _Shimmer({super.key});
  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))
    ..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(color: Colors.grey.shade200),
              FractionallySizedBox(
                widthFactor: 0.4,
                alignment: Alignment((_c.value * 2) - 1, 0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.7),
                        Colors.transparent
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
        color: Colors.white.withValues(alpha: 0.6),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: _kIndigo),
          const SizedBox(height: 10),
          Text('No $title',
              style:
              const TextStyle(fontWeight: FontWeight.w700, color: _kHeading)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: _kMuted)),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ContactRow(
      {super.key, required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) =>
      Row(children: [Icon(icon), const SizedBox(width: 8), Text('$label: $value')]);
}

// --- STUBS FOR MISSING WIDGETS ---
class _ProfileOverview extends StatelessWidget {
  const _ProfileOverview();
  @override
  Widget build(BuildContext context) {
    final dto = HomeData.of(context).data;
    return ProfilePreviewCard(
      name: dto?.displayName ?? 'Your Name',
      title: dto?.professionalTitle ?? 'Your Title',
      bio: dto?.bio ?? 'Welcome to your freelancer dashboard!',
      skills: (dto?.skillsCsv
          ?.split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList() ??
          ['Skill 1', 'Skill 2']),
      imageUrl: dto?.imageUrl,
    );
  }
}

// ----------- ENHANCED HOVER SCALE & GLASS CARD -----------
class HoverScale extends StatefulWidget {
  final Widget child;
  final double scale;
  final Duration duration;
  const HoverScale({
    required this.child,
    this.scale = 1.02,
    this.duration = const Duration(milliseconds: 140),
    super.key,
  });

  @override
  State<HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<HoverScale> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? widget.scale : 1.0,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  const GlassCard({required this.child});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}
