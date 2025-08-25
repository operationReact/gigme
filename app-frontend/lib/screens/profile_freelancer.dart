import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api/profile_api.dart';
import '../services/session_service.dart';
import 'dart:ui' as ui;

enum PortfolioCategory { videos, photos, documents }

class ProfileFreelancerPage extends StatefulWidget {
  static const routeName = '/profile/freelancer';
  const ProfileFreelancerPage({super.key});

  @override
  State<ProfileFreelancerPage> createState() => _ProfileFreelancerPageState();
}

class _ProfileFreelancerPageState extends State<ProfileFreelancerPage> with SingleTickerProviderStateMixin {
  // Mock data
  double get averageRating => 4.6;
  int get reviewCount => 31;

  final List<_PortfolioItem> portfolio = const [
    _PortfolioItem(
      name: 'Landing Page Redesign',
      url: 'https://example.com/portfolio/landing_redesign.png',
    ),
    _PortfolioItem(
      name: 'Promo Video',
      url: 'https://example.com/portfolio/promo_video.mp4',
    ),
    _PortfolioItem(
      name: 'Case Study PDF',
      url: 'https://example.com/portfolio/case_study.pdf',
    ),
    _PortfolioItem(
      name: 'App Screens',
      url: 'https://example.com/portfolio/app_screens.jpg',
    ),
  ];

  PortfolioCategory _selected = PortfolioCategory.photos;

  late final AnimationController _introCtl;

  Animation<double> _seg(int index) {
    final start = (index * 0.12).clamp(0.0, 1.0);
    final end = (start + 0.6).clamp(0.0, 1.0);
    return CurvedAnimation(parent: _introCtl, curve: Interval(start, end, curve: Curves.easeOut));
  }

  @override
  void initState() {
    super.initState();
    _introCtl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
    _load();
  }

  FreelancerProfileDto? _profile;
  bool _loading = true;
  String? _error;

  Future<void> _load() async {
    final user = SessionService.instance.user;
    if (user == null) {
      setState(() => {_loading = false, _error = 'Not authenticated'});
      return;
    }
    try {
      final dto = await ProfileApi().getFreelancer(user.id);
      if (!mounted) return;
      if (dto == null) {
        // No profile yet -> navigate to create screen
        Navigator.of(context).pushReplacementNamed('/freelancerProfile');
        return;
      }
      setState(() => {_profile = dto, _loading = false, _error = null});
    } catch (e) {
      if (!mounted) return;
      setState(() => {_error = 'Failed to load profile', _loading = false});
    }
  }

  List<String> get _skillsList {
    final csv = _profile?.skillsCsv;
    if (csv == null || csv.trim().isEmpty) return const [];
    return csv.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  List<_PortfolioItem> get _filteredItems {
    return portfolio.where((item) {
      final url = item.url.toLowerCase();
      final isImage = url.endsWith('.png') || url.endsWith('.jpg') || url.endsWith('.jpeg') || url.endsWith('.gif');
      final isVideo = url.endsWith('.mp4') || url.endsWith('.mov') || url.endsWith('.webm');
      switch (_selected) {
        case PortfolioCategory.photos:
          return isImage;
        case PortfolioCategory.videos:
          return isVideo;
        case PortfolioCategory.documents:
          return !isImage && !isVideo;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(appBar: AppBar(title: const Text('Freelancer Profile')), body: const Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Freelancer Profile')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () { setState(() => _loading = true); _load(); },
                child: const Text('Retry'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushReplacementNamed('/freelancerProfile'),
                child: const Text('Create / Edit Profile'),
              ),
            ],
          ),
        ),
      );
    }
    final p = _profile!;
    final sessionUser = SessionService.instance.user;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      extendBodyBehindAppBar: true,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pushNamed('/freelancerProfile'),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Edit Profile'),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Freelancer Profile'),
        actions: [IconButton(onPressed: _load, tooltip: 'Refresh', icon: const Icon(Icons.refresh))],
      ),
      body: Stack(
        children: [
          // Animated gradient hero backdrop (simple subtle)
          Container(
            height: 260,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cs.secondary.withValues(alpha: 0.35),
                  cs.tertiary.withValues(alpha: 0.28),
                  cs.primary.withValues(alpha: 0.15),
                ],
              ),
            ),
          ),
          // Content
            SafeArea(
              child: LayoutBuilder(
                builder: (ctx, constraints) {
                  final isWide = constraints.maxWidth >= 980;
                  final sidePad = isWide ? 40.0 : 16.0;
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(sidePad, 24, sidePad, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Portfolio & Presence', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 28),
                        if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 5,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _GlassCard(child: _ProfileHeaderBlock(profile: p, skills: _skillsList, rating: averageRating, count: reviewCount)),
                                    const SizedBox(height: 20),
                                    _GlassCard(child: _AboutContactBlock(profile: p, email: sessionUser?.email)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 28),
                              Expanded(
                                flex: 7,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _GlassCard(child: _StatsRow()),
                                    const SizedBox(height: 20),
                                    _GlassCard(child: _PortfolioPlaceholder()),
                                  ],
                                ),
                              ),
                            ],
                          )
                        else ...[
                          _GlassCard(child: _ProfileHeaderBlock(profile: p, skills: _skillsList, rating: averageRating, count: reviewCount)),
                          const SizedBox(height: 20),
                          _GlassCard(child: _StatsRow()),
                          const SizedBox(height: 20),
                          _GlassCard(child: _PortfolioPlaceholder()),
                          const SizedBox(height: 20),
                          _GlassCard(child: _AboutContactBlock(profile: p, email: sessionUser?.email)),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _introCtl.dispose();
    super.dispose();
  }
}

class _RatingCard extends StatelessWidget {
  final double average;
  final int count;
  const _RatingCard({required this.average, required this.count});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            _StarRow(rating: average),
            const SizedBox(width: 12),
            Text('${average.toStringAsFixed(1)}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: 8),
            Text('($count reviews)', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final double rating; // 0..5
  const _StarRow({required this.rating});

  @override
  Widget build(BuildContext context) {
    final fullStars = rating.floor();
    final hasHalf = (rating - fullStars) >= 0.5 && fullStars < 5;
    final emptyStars = 5 - fullStars - (hasHalf ? 1 : 0);
    final color = Theme.of(context).colorScheme.secondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < fullStars; i++) Icon(Icons.star, color: color),
        if (hasHalf) Icon(Icons.star_half, color: color),
        for (var i = 0; i < emptyStars; i++) Icon(Icons.star_border, color: color),
      ],
    );
  }
}

class _PortfolioItem {
  final String name;
  final String url; // can be image, video, document or any file
  const _PortfolioItem({required this.name, required this.url});
}

class _PortfolioGrid extends StatelessWidget {
  final List<_PortfolioItem> items;
  const _PortfolioGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Portfolio', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3 / 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _PortfolioTile(item: item);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PortfolioTile extends StatelessWidget {
  final _PortfolioItem item;
  const _PortfolioTile({required this.item});

  bool get _isImage => item.url.toLowerCase().endsWith('.png') || item.url.toLowerCase().endsWith('.jpg') || item.url.toLowerCase().endsWith('.jpeg') || item.url.toLowerCase().endsWith('.gif');
  bool get _isVideo => item.url.toLowerCase().endsWith('.mp4') || item.url.toLowerCase().endsWith('.mov') || item.url.toLowerCase().endsWith('.webm');

  Future<void> _open() async {
    final uri = Uri.parse(item.url);
    if (!await launchUrl(uri, mode: LaunchMode.platformDefault)) {
      // ignore: avoid_print
      print('Could not launch ${item.url}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _open,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildPreview(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (_isImage) {
      return Container(
        color: cs.secondary.withValues(alpha: 0.08),
        child: Image.network(
          item.url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => _IconPreview(icon: Icons.image_not_supported_outlined),
        ),
      );
    } else if (_isVideo) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Container(color: cs.secondary.withValues(alpha: 0.08)),
          const Center(child: Icon(Icons.videocam_outlined, size: 40)),
        ],
      );
    } else {
      return const _IconPreview(icon: Icons.description_outlined);
    }
  }
}

class _IconPreview extends StatelessWidget {
  final IconData icon;
  const _IconPreview({required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.secondary.withValues(alpha: 0.08),
      child: Icon(icon, size: 40, color: cs.primary),
    );
  }
}

// ===== New glass / layout helper widgets for revamped profile page =====
class _GlassCard extends StatelessWidget {
  final Widget child; final EdgeInsetsGeometry padding; final double radius;
  const _GlassCard({required this.child, this.padding = const EdgeInsets.all(20), this.radius = 24});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            color: Colors.white.withAlpha((0.15 * 255).toInt()),
            border: Border.all(color: Colors.white.withAlpha((0.4 * 255).toInt()), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.10 * 255).toInt()),
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ProfileHeaderBlock extends StatelessWidget {
  final FreelancerProfileDto profile; final List<String> skills; final double rating; final int count;
  const _ProfileHeaderBlock({required this.profile, required this.skills, required this.rating, required this.count});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children:[
            CircleAvatar(radius: 48, backgroundColor: cs.secondary.withValues(alpha:0.25), child: Icon(Icons.person_outline, size: 48, color: cs.onSurface)),
            Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, boxShadow:[BoxShadow(color: cs.secondary.withValues(alpha: 0.55), blurRadius: 36, spreadRadius: -6)])))
          ]),
          const SizedBox(width: 20),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
            Text(profile.displayName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            if(profile.professionalTitle!=null) ...[
              const SizedBox(height:4),
              Text(profile.professionalTitle!, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70)),
            ],
            const SizedBox(height:10),
            _StarRatingAnimated(rating: rating),
            const SizedBox(height:6),
            Text('${rating.toStringAsFixed(1)} / 5.0  •  $count reviews', style: Theme.of(context).textTheme.bodySmall),
          ]))
        ]),
        const SizedBox(height: 16),
        if(skills.isNotEmpty) Wrap(spacing:10, runSpacing:10, children: skills.map((s)=>Chip(label: Text(s))).toList()),
      ],
    );
  }
}

class _StarRatingAnimated extends StatefulWidget { final double rating; const _StarRatingAnimated({required this.rating}); @override State<_StarRatingAnimated> createState()=>_StarRatingAnimatedState(); }
class _StarRatingAnimatedState extends State<_StarRatingAnimated> with SingleTickerProviderStateMixin { late final AnimationController _c; @override void initState(){ super.initState(); _c=AnimationController(vsync:this, duration: const Duration(milliseconds: 700))..forward(); }
  @override void dispose(){ _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context){ final full = widget.rating.floor(); final half = (widget.rating-full)>=0.25 && (widget.rating-full)<0.85; return Row(children: List.generate(5, (i){ IconData ic; if(i<full) ic=Icons.star; else if(i==full && half) ic=Icons.star_half; else ic=Icons.star_outline; return ScaleTransition(scale: CurvedAnimation(parent:_c, curve: Interval(i/5,1, curve: Curves.easeOutBack)), child: Icon(ic, color: Colors.amber, size:22)); })); }
}

class _AboutContactBlock extends StatelessWidget {
  final FreelancerProfileDto profile; final String? email; const _AboutContactBlock({required this.profile, required this.email});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('About', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
      const SizedBox(height:8),
      Text(profile.bio==null || profile.bio!.isEmpty ? 'No bio added yet.' : profile.bio!),
      const SizedBox(height:20),
      Text('Contact', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
      const SizedBox(height:8),
      Row(children:[ const Icon(Icons.email_outlined, size:18), const SizedBox(width:8), Expanded(child: Text(email ?? 'Unknown')) ]),
    ]);
  }
}

class _StatsRow extends StatelessWidget { @override Widget build(BuildContext context){
  return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children:[
    Text('Stats', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
    const SizedBox(height:12),
    LayoutBuilder(builder:(ctx,c){ final wide=c.maxWidth>560; final tiles=[ _MiniStat(label:'Projects', value:'24'), _MiniStat(label:'Clients', value:'11'), _MiniStat(label:'Earnings', value:'18.2k'), _MiniStat(label:'Success', value:'96%') ]; if(wide){ return Row(children: tiles.expand((t)=>[Expanded(child:t), const SizedBox(width:14)]).toList()..removeLast()); } return Column(children: tiles.expand((t)=>[t, const SizedBox(height:14)]).toList()..removeLast()); }),
  ]);
}}
class _MiniStat extends StatelessWidget { final String label; final String value; const _MiniStat({required this.label, required this.value}); @override Widget build(BuildContext context){ return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: Colors.white.withValues(alpha:0.08), border: Border.all(color: Colors.white.withValues(alpha:0.14))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[ Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height:4), Text(label, style: Theme.of(context).textTheme.bodySmall) ])); }}

class _PortfolioPlaceholder extends StatelessWidget { @override Widget build(BuildContext context){ return Column(crossAxisAlignment: CrossAxisAlignment.start, children:[ Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[ Text('Portfolio', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)), TextButton.icon(onPressed: (){}, icon: const Icon(Icons.add), label: const Text('Add')) ]), const SizedBox(height:12), Text('Portfolio feature coming soon. Add examples of your work to stand out.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: Colors.white70)) ]); }}
