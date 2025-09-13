import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Clipboard
import 'package:gigmework/sections/user_search_follow.dart';
import '../api/social_api.dart';
import '../models/social_post.dart';
import '../screens/share_card_public.dart';
import '../job_service.dart';
import '../widgets/apply_for_work_cta.dart';
import '../sections/home_feed_preview.dart';
import '../widgets/profile_preview_card.dart'; // GlassCard definition

// Brand palette constants (mirroring freelancer_home)
const _kTeal = Color(0xFF00C2A8);
const _kIndigo = Color(0xFF3B82F6);
const _kViolet = Color(0xFF7C3AED);
const _kHeading = Color(0xFF111827);
const _kMuted = Color(0xFF6B7280);

const _kMaxPageWidth = 1280.0;
const _kDesktopBreakpoint = 1024.0;

class CreatorProfileView extends StatefulWidget {
  final int viewerId;
  final CreatorSuggestion initial;
  const CreatorProfileView({super.key, required this.viewerId, required this.initial});
  @override
  State<CreatorProfileView> createState() => _CreatorProfileViewState();
}

class _CreatorProfileViewState extends State<CreatorProfileView> {
  late CreatorSuggestion _c = widget.initial;
  SocialCounts? _counts;
  bool _loadingCounts = false;
  bool _toggling = false;
  _CreatorPrimaryTab _currentTab = _CreatorPrimaryTab.feed;

  bool get _isSelf => widget.viewerId == _c.userId;

  int? _newJobsCount; bool _loadingJobs = true;

  @override
  void initState() {
    super.initState();
    _loadCounts();
    _loadJobCount();
  }

  Future<void> _loadCounts() async {
    setState(() => _loadingCounts = true);
    try {
      final sc = await SocialApi.instance.getCounts(_c.userId);
      if (mounted) setState(() { _counts = sc; });
    } catch (_) {} finally { if (mounted) setState(() => _loadingCounts = false); }
  }

  Future<void> _loadJobCount() async { try { final c = await JobService().countNewJobs(); if(mounted) setState(()=> _newJobsCount = c); } catch(_){ if(mounted) setState(()=> _newJobsCount = null); } finally { if(mounted) setState(()=> _loadingJobs = false); } }

  Future<void> _toggleFollow() async {
    if (_toggling || _isSelf) return;
    final follow = !_c.followedByMe;
    setState(() {
      _toggling = true;
      _c = CreatorSuggestion(
        userId: _c.userId,
        name: _c.name,
        title: _c.title,
        avatarUrl: _c.avatarUrl,
        followedByMe: follow,
        followerCount: (_c.followerCount + (follow ? 1 : -1)).clamp(0, 1 << 31),
      );
      if (_counts != null) {
        _counts = SocialCounts(posts: _counts!.posts, followers: (_counts!.followers + (follow ? 1 : -1)).clamp(0, 1 << 31), following: _counts!.following);
      }
    });
    try {
      if (follow) {
        await SocialApi.instance.follow(_c.userId, viewerId: widget.viewerId);
      } else {
        await SocialApi.instance.unfollow(_c.userId, viewerId: widget.viewerId);
      }
    } catch (_) {
      // revert
      setState(() {
        final oldFollow = !follow;
        _c = CreatorSuggestion(
          userId: _c.userId,
          name: _c.name,
          title: _c.title,
          avatarUrl: _c.avatarUrl,
            followedByMe: oldFollow,
          followerCount: (_c.followerCount + (oldFollow ? 1 : -1)).clamp(0, 1 << 31),
        );
        if (_counts != null) {
          _counts = SocialCounts(posts: _counts!.posts, followers: (_counts!.followers + (oldFollow ? 1 : -1)).clamp(0, 1 << 31), following: _counts!.following);
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(follow ? 'Failed to follow' : 'Failed to unfollow')));
      });
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  Future<void> _copyShareCard() async {
    final uid = _c.userId;
    final url = ShareCardPublicPage.buildUrlForUser(uid);
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Share link copied'),
        action: SnackBarAction(
          label: 'Preview',
          onPressed: () => Navigator.of(context).pushNamed(ShareCardPublicPage.routeName, arguments: {'u': uid}),
        ),
      ),
    );
  }

  Widget _selectedSection() {
    switch (_currentTab) {
      case _CreatorPrimaryTab.feed:
        return _FeedSection(viewerId: widget.viewerId);
      case _CreatorPrimaryTab.portfolio:
        return _PortfolioSectionPlaceholder();
      case _CreatorPrimaryTab.jobs:
        return Column(children: const [
          _ActiveContractsPlaceholder(),
          SizedBox(height:16),
          _RecommendationsPlaceholder(),
        ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final followers = _counts?.followers ?? _c.followerCount;
    final posts = _counts?.posts ?? 0;
    final following = _counts?.following ?? 0;
    final width = MediaQuery.of(context).size.width; final isWide = width >= _kDesktopBreakpoint; final isMobile = width < 600;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pop(context, _c);
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        floatingActionButton: (!_isSelf) ? null : (isMobile ? ApplyForWorkCta(initialCount: _newJobsCount, onPressed: (){}, dense: true, showLabel: true,) : null),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const _GmwLogo(markSize: 20, fontSize: 18),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _c),
          ),
          actions: [
            if (_isSelf && !isMobile && _currentTab != _CreatorPrimaryTab.portfolio && !_loadingJobs)
              Padding(
                padding: const EdgeInsets.symmetric(vertical:8,horizontal:8),
                child: ApplyForWorkCta(initialCount: _newJobsCount, onPressed: (){}, dense: true, showLabel: true),
              ),
            IconButton(
              tooltip: 'Copy share card',
              icon: const Icon(Icons.ios_share_outlined),
              onPressed: _copyShareCard,
            ),
            if (!_isSelf)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: _FollowButton(
                  followed: _c.followedByMe,
                  onPressed: _toggling ? null : _toggleFollow,
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed('/profile/user'),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14)),
                ),
              ),
          ],
        ),
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFEEF2FF), Color(0xFFF0FDFA)],
                ),
              ),
            ),
            const _AnimatedBackground(),
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.25),
                      Theme.of(context).colorScheme.secondary.withOpacity(0.18),
                      Theme.of(context).colorScheme.tertiary.withOpacity(0.15),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _kMaxPageWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex:5,
                                child: _IdentityGlassCard(
                                  name: _c.name,
                                  title: _c.title.isEmpty ? 'Creator' : _c.title,
                                  avatarUrl: _c.avatarUrl,
                                  posts: posts,
                                  followers: followers,
                                  following: following,
                                  isSelf: _isSelf,
                                  loadingCounts: _loadingCounts,
                                  followed: _c.followedByMe,
                                  onToggleFollow: _toggling ? null : _toggleFollow,
                                ),
                              ),
                              const SizedBox(width:16),
                              const Expanded(flex:7, child: _StatsAndProgressPlaceholder()),
                            ],
                          )
                        else
                          Column(children:[
                            _IdentityGlassCard(
                              name: _c.name,
                              title: _c.title.isEmpty ? 'Creator' : _c.title,
                              avatarUrl: _c.avatarUrl,
                              posts: posts,
                              followers: followers,
                              following: following,
                              isSelf: _isSelf,
                              loadingCounts: _loadingCounts,
                              followed: _c.followedByMe,
                              onToggleFollow: _toggling ? null : _toggleFollow,
                            ),
                            const SizedBox(height:16),
                            const _StatsAndProgressPlaceholder(),
                          ]),
                        const SizedBox(height: 16),
                        _CreatorPrimaryNavBar(
                          current: _currentTab,
                          jobsBadge: _newJobsCount,
                          onChanged: (t) => setState(() => _currentTab = t),
                        ),
                        const SizedBox(height: 16),
                        _selectedSection(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Creator specific primary tabs
enum _CreatorPrimaryTab { feed, portfolio, jobs }

class _CreatorPrimaryNavBar extends StatelessWidget {
  final _CreatorPrimaryTab current; final ValueChanged<_CreatorPrimaryTab> onChanged; final int? jobsBadge;
  const _CreatorPrimaryNavBar({super.key, required this.current, required this.onChanged, this.jobsBadge});
  int get _index => current == _CreatorPrimaryTab.feed ? 0 : current == _CreatorPrimaryTab.portfolio ? 1 : 2;
  List<Color> _gradFor(_CreatorPrimaryTab t){
    switch(t){
      case _CreatorPrimaryTab.feed: return const [_kIndigo, _kViolet];
      case _CreatorPrimaryTab.portfolio: return const [Color(0xFF0EA5E9), _kViolet];
      case _CreatorPrimaryTab.jobs: return const [Color(0xFF22C55E), _kIndigo];
    }
  }
  Alignment _slotAlignment(int index, int count){ final step = count==1?0.0:2.0/(count-1); return Alignment(-1.0 + index*step, 0); }
  @override
  Widget build(BuildContext context) {
    const labels = ['Feed','Portfolio','Jobs'];
    const icons = [Icons.dynamic_feed_outlined, Icons.work_outline, Icons.business_center];
    return GlassCard(
      child: LayoutBuilder(
        builder: (ctx, c){
          const trackPadding = 6.0; const itemCount = 3; final trackWidth = c.maxWidth - trackPadding*2; final slotWidth = trackWidth/itemCount;
          return ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 56,
              child: Stack(children:[
                // Selected pill
                Padding(
                  padding: const EdgeInsets.all(trackPadding),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    alignment: _slotAlignment(_index, itemCount),
                    child: SizedBox(
                      width: slotWidth,
                      height: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: LinearGradient(colors: _gradFor(current), begin: Alignment.topLeft, end: Alignment.bottomRight),
                          boxShadow: [
                            BoxShadow(
                              color: _gradFor(current).last.withOpacity(.30),
                              blurRadius: 16,
                              offset: const Offset(0,8),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Buttons row
                Padding(
                  padding: const EdgeInsets.all(trackPadding),
                  child: Row(
                    children: List.generate(itemCount, (i){
                      final tab = i==0? _CreatorPrimaryTab.feed : i==1? _CreatorPrimaryTab.portfolio : _CreatorPrimaryTab.jobs;
                      final isSelected = tab == current;
                      final badge = (tab == _CreatorPrimaryTab.jobs && (jobsBadge ?? 0) > 0) ? _CountBadge(count: jobsBadge!) : null;
                      return SizedBox(
                        width: slotWidth,
                        height: double.infinity,
                        child: _CreatorNavButton(
                          icon: icons[i],
                          label: labels[i],
                          selected: isSelected,
                          onTap: () => onChanged(tab),
                          trailingBadge: badge,
                        ),
                      );
                    }),
                  ),
                )
              ]),
            ),
          );
        },
      ),
    );
  }
}

class _CreatorNavButton extends StatefulWidget {
  final IconData icon; final String label; final bool selected; final VoidCallback onTap; final Widget? trailingBadge;
  const _CreatorNavButton({required this.icon, required this.label, required this.selected, required this.onTap, this.trailingBadge});
  @override State<_CreatorNavButton> createState()=>_CreatorNavButtonState();
}
class _CreatorNavButtonState extends State<_CreatorNavButton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync:this, duration: const Duration(milliseconds:220));
  bool _hover=false;
  @override void dispose(){ _c.dispose(); super.dispose(); }
  @override void didUpdateWidget(covariant _CreatorNavButton old){ super.didUpdateWidget(old); if(widget.selected && !old.selected){ _c.forward(from:0);} }
  @override Widget build(BuildContext context){
    final baseColor = widget.selected? Colors.white : _kHeading;
    return MouseRegion(
      onEnter: (_){ setState(()=>_hover=true); },
      onExit: (_){ setState(()=>_hover=false); },
      child: InkWell(
        onTap: widget.onTap,
        child: Stack(
          alignment: Alignment.topRight,
          children:[
            Center(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds:180),
                style: TextStyle(fontSize:13, fontWeight: FontWeight.w600, color: widget.selected? Colors.white : (_hover? _kIndigo : _kMuted)),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children:[
                  Icon(widget.icon, size:20, color: baseColor),
                  const SizedBox(height:4),
                  Text(widget.label),
                ]),
              ),
            ),
            if (widget.trailingBadge != null)
              Positioned(top:6, right:10, child: widget.trailingBadge!),
          ],
        ),
      ),
    );
  }
}

// Brand logo (compact) used in AppBar similar to freelancer_home
class _GmwLogo extends StatelessWidget {
  final double markSize; final double fontSize; const _GmwLogo({this.markSize=26, this.fontSize=20});
  @override
  Widget build(BuildContext context) {
    final wordmark = Text.rich(TextSpan(children: const [
      TextSpan(text:'Gig', style: TextStyle(color:_kHeading, fontWeight: FontWeight.w800)),
      TextSpan(text:'Me', style: TextStyle(color:_kTeal, fontWeight: FontWeight.w800)),
      TextSpan(text:'Work', style: TextStyle(color:_kHeading, fontWeight: FontWeight.w800)),
    ]), style: TextStyle(fontSize: fontSize, height:1));
    return Row(mainAxisSize: MainAxisSize.min, children:[_GmwMark(size: markSize), const SizedBox(width:8), wordmark]);
  }
}
class _GmwMark extends StatelessWidget { final double size; const _GmwMark({required this.size}); @override Widget build(BuildContext context){ final h=size; final w=size*1.7; return SizedBox(width:w,height:h,child:Stack(alignment:Alignment.center,children:[Align(alignment:Alignment.centerLeft,child:Container(width:h,height:h,decoration: const BoxDecoration(color:_kTeal, shape: BoxShape.circle))),Align(alignment:Alignment.centerRight,child:Container(width:h,height:h,decoration: const BoxDecoration(color:_kViolet, shape: BoxShape.circle))),Container(width:w*0.74,height:h*0.34,decoration:BoxDecoration(color:_kIndigo,borderRadius: BorderRadius.circular(h), border: Border.all(color: Colors.white, width: h*0.10)))])); }}
class _FeedSectionPlaceholder extends StatelessWidget { @override Widget build(BuildContext context)=> GlassCard(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [Text('Creator feed', style: TextStyle(fontSize:16,fontWeight: FontWeight.w700)), SizedBox(height:14), Text('Feed content coming soon...', style: TextStyle(color: Colors.grey))]))); }
class _PortfolioSectionPlaceholder extends StatelessWidget { @override Widget build(BuildContext context)=> GlassCard(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [Text('Portfolio', style: TextStyle(fontSize:16,fontWeight: FontWeight.w700)), SizedBox(height:14), Text('Portfolio items coming soon...', style: TextStyle(color: Colors.grey))]))); }
class _ActiveContractsPlaceholder extends StatelessWidget { const _ActiveContractsPlaceholder(); @override Widget build(BuildContext context)=> GlassCard(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [Text('Active Contracts', style: TextStyle(fontSize:16,fontWeight: FontWeight.w700)), SizedBox(height:14), Text('No active contracts yet.', style: TextStyle(color: Colors.grey))]))); }
class _RecommendationsPlaceholder extends StatelessWidget { const _RecommendationsPlaceholder(); @override Widget build(BuildContext context)=> GlassCard(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [Text('Job Recommendations', style: TextStyle(fontSize:16,fontWeight: FontWeight.w700)), SizedBox(height:14), Text('Recommendations appearing soon...', style: TextStyle(color: Colors.grey))]))); }
class _StatsAndProgressPlaceholder extends StatelessWidget { const _StatsAndProgressPlaceholder(); @override Widget build(BuildContext context){ return GlassCard(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[ Text('Performance Overview', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: _kHeading)), const SizedBox(height:16), LayoutBuilder(builder:(ctx,c){ final wide=c.maxWidth>600; final tiles=[_PerfTile(icon:Icons.folder_open_outlined,label:'Projects',value:'--'), _PerfTile(icon:Icons.people_outline,label:'Clients',value:'--'), _PerfTile(icon:Icons.attach_money,label:'Earnings',value:'--'), _PerfTile(icon:Icons.emoji_events_outlined,label:'Success',value:'--')]; if(wide){ return Row(children:[for(int i=0;i<tiles.length;i++) ...[ Expanded(child: tiles[i]), if(i!=tiles.length-1) const SizedBox(width:14)]]);} return Column(children:[ for(int i=0;i<tiles.length;i++) ...[ tiles[i], if(i!=tiles.length-1) const SizedBox(height:14)]] ); }) ]))); }}
class _PerfTile extends StatelessWidget { final IconData icon; final String label; final String value; const _PerfTile({required this.icon, required this.label, required this.value}); @override Widget build(BuildContext context){ return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white), boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius:8, offset: Offset(0,2))]), child: Row(children:[ Icon(icon, size:28, color:_kIndigo), const SizedBox(width:12), Column(crossAxisAlignment: CrossAxisAlignment.start, children:[ Text(value, style: const TextStyle(fontSize:20,fontWeight: FontWeight.w800, color:_kHeading)), Text(label, style: const TextStyle(color:_kMuted,fontWeight: FontWeight.w600))]) ])); }}
class _CountBadge extends StatelessWidget { final int count; const _CountBadge({required this.count}); String _fmt(int v)=> v>99? '99+':'$v'; @override Widget build(BuildContext context){ return Container(padding: const EdgeInsets.symmetric(horizontal:8, vertical:2), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white), boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius:8, offset: Offset(0,2))]), child: Text(_fmt(count), style: const TextStyle(color: _kHeading, fontWeight: FontWeight.w800, fontSize:12))); }}
class _FeedSection extends StatelessWidget {
  final int viewerId; const _FeedSection({required this.viewerId});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Find creators', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: _kHeading)),
                const SizedBox(height: 8),
                UserSearchFollow(viewerId: viewerId, compact: true),
              ],
            ),
          ),
        ),
        const SizedBox(height:16),
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Creator feed', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: _kHeading)),
                const SizedBox(height: 12),
                HomeFeedPreview(viewerId: viewerId),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _IdentityGlassCard extends StatelessWidget {
  final String name;
  final String title;
  final String? avatarUrl; // made nullable
  final int posts;
  final int followers;
  final int following;
  final bool isSelf;
  final bool loadingCounts;
  final bool followed;
  final VoidCallback? onToggleFollow;

  const _IdentityGlassCard({
    super.key,
    required this.name,
    required this.title,
    required this.avatarUrl, // nullable param
    required this.posts,
    required this.followers,
    required this.following,
    required this.isSelf,
    required this.loadingCounts,
    required this.followed,
    this.onToggleFollow,
  });

  @override
  Widget build(BuildContext context) {
    final profileViews = 0; // placeholder like freelancer_home
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: (avatarUrl != null && avatarUrl!.isNotEmpty)
                  ? Image.network(
                      avatarUrl!,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, _, __) => Container(width:64,height:64,color: Colors.grey[200], child: const Icon(Icons.person, color: Colors.white54)),
                    )
                  : Container(
                      width: 64,
                      height: 64,
                      color: Colors.grey[200],
                      child: const Icon(Icons.person, color: Colors.white54),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6B7280), fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    const _TinyBadge(icon: Icons.verified, label: 'Pro'),
                    const SizedBox(width: 6),
                    const _TinyBadge(icon: Icons.star_border_rounded, label: 'Creator'),
                    if (loadingCounts) ...[
                      const SizedBox(width: 8),
                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    ],
                  ]),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (ctx, c) {
                      final wide = c.maxWidth > 460;
                      final pills = [
                        _MetricPill(count: posts, label: 'Posts', icon: Icons.article_outlined),
                        _MetricPill(count: followers, label: 'Followers', icon: Icons.group_outlined),
                        _MetricPill(count: following, label: 'Following', icon: Icons.person_add_alt_1_outlined),
                        _MetricPill(count: profileViews, label: 'Profile views', icon: Icons.visibility_outlined),
                      ];
                      return wide ? Row(children: [for (int i=0;i<pills.length;i++) ...[if (i>0) const SizedBox(width: 10), Expanded(child: pills[i])]])
                                   : Wrap(spacing: 10, runSpacing: 10, children: pills.map((w)=>SizedBox(width: 140, child: w)).toList());
                    },
                  ),
                  const SizedBox(height: 14),
                  if (!isSelf)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: followed
                          ? OutlinedButton(onPressed: onToggleFollow, child: const Text('Following'))
                          : FilledButton(onPressed: onToggleFollow, child: const Text('Follow')),
                    )
                  else
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text('Open feed'),
                      style: TextButton.styleFrom(foregroundColor: _kIndigo, padding: EdgeInsets.zero),
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

class _TinyBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TinyBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: _kTeal),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: _kTeal, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _MetricPill extends StatelessWidget {
  final int count;
  final String label;
  final IconData icon;

  const _MetricPill({required this.count, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: _kIndigo),
            const SizedBox(width: 8),
            Text('$count', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kHeading)),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 14, color: _kMuted, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// Lightweight follow button (duplicate of private version in user_search_follow.dart)
class _FollowButton extends StatelessWidget {
  final bool followed;
  final VoidCallback? onPressed;
  const _FollowButton({required this.followed, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    if (followed) {
      return OutlinedButton(
        style: OutlinedButton.styleFrom(minimumSize: const Size(80, 36), padding: const EdgeInsets.symmetric(horizontal: 16)),
        onPressed: onPressed,
        child: const Text('Following'),
      );
    }
    return FilledButton(
      style: FilledButton.styleFrom(minimumSize: const Size(72, 36), padding: const EdgeInsets.symmetric(horizontal: 16)),
      onPressed: onPressed,
      child: const Text('Follow'),
    );
  }
}

// Animated subtle moving radial gradients / particles (replicated from freelancer_home.dart)
class _AnimatedBackground extends StatefulWidget {
  const _AnimatedBackground();
  @override
  State<_AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<_AnimatedBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat();
  @override
  void dispose(){ _c.dispose(); super.dispose(); }
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
  bool shouldRepaint(covariant _BgPainter old) => old.t != t;
}
