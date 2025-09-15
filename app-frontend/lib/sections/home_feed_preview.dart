import 'package:flutter/material.dart';
import 'dart:ui';
import '../api/social_api.dart';
import '../models/social_post.dart';
import '../widgets/post_composer.dart';
import '../widgets/social_post_card.dart';
import '../screens/social_feed.dart';

class HomeFeedPreview extends StatefulWidget {
  final int viewerId;
  const HomeFeedPreview({super.key, required this.viewerId});

  @override
  State<HomeFeedPreview> createState() => _HomeFeedPreviewState();
}

class _HomeFeedPreviewState extends State<HomeFeedPreview> {
  bool _loading = true;
  List<SocialPost> _posts = [];
  bool _showMine = false; // new toggle state
  // NEW: my posts state
  bool _loadingMine = false;
  List<SocialPost> _myPostsCache = [];

  // computed list of my posts (including injected samples if needed)
  List<SocialPost> get _myPosts => _showMine ? _myPostsCache : _posts.where((p) => p.authorId == widget.viewerId).toList();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // fetch more posts so we likely include the user's own posts
      final data = await SocialApi.instance.listFeed(viewerId: widget.viewerId, page: 1, pageSize: 20);
      if (!mounted) return;
      setState(() {
        _posts = data;
        _maybeInjectSamplePostsForUser3();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _maybeInjectSamplePostsForUser3() {
    if (widget.viewerId != 3) return;
    final hasMine = _posts.any((p) => p.authorId == 3);
    if (hasMine) return; // don't inject if real data exists
    final now = DateTime.now();
    final sampleImage = SocialPost(
      id: -1,
      authorId: 3,
      authorName: 'You',
      authorAvatarUrl: null,
      content: 'Sample image post – replace me by creating your own first post! ✨',
      createdAt: now.subtract(const Duration(minutes: 5)),
      likeCount: 0,
      commentCount: 0,
      likedByMe: false,
      mediaUrls: const ['https://picsum.photos/seed/user3image/800/600'],
      mediaItems: const [
        SocialMediaItem(
          url: 'https://picsum.photos/seed/user3image/800/600',
          mediaType: 'IMAGE',
          width: 800,
          height: 600,
          thumbnailUrl: null,
        ),
      ],
    );
    final sampleVideo = SocialPost(
      id: -2,
      authorId: 3,
      authorName: 'You',
      authorAvatarUrl: null,
      content: 'Sample video post – tap play to preview. Upload your own to replace this.',
      createdAt: now.subtract(const Duration(minutes: 8)),
      likeCount: 0,
      commentCount: 0,
      likedByMe: false,
      mediaUrls: const ['https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4'],
      mediaItems: const [
        SocialMediaItem(
          url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
          mediaType: 'VIDEO',
          width: 1280,
          height: 720,
          durationSeconds: 10,
          thumbnailUrl: 'https://picsum.photos/seed/user3video/800/450',
        ),
      ],
    );
    // Prepend so they show prominently under My Posts & Feed
    _posts = [sampleImage, sampleVideo, ..._posts];
  }

  Future<void> _loadMine() async {
    if (_loadingMine) return;
    setState(() => _loadingMine = true);
    try {
      final mine = await SocialApi.instance.listUserPosts(authorId: widget.viewerId, viewerId: widget.viewerId, page: 1, pageSize: 60);
      if (!mounted) return;
      setState(() { _myPostsCache = mine; _loadingMine = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingMine = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget header() => Row(
      children: [
        ShaderMask(
          shaderCallback: (r) => LinearGradient(
            colors: [cs.primary, cs.secondary],
          ).createShader(r),
          blendMode: BlendMode.srcIn,
          child: Text(
            'Posts',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -.5),
          ),
        ),
        const SizedBox(width: 8),
        if (!_loading)
          _SegmentedSmall(
            value: _showMine ? 1 : 0,
            labels: const ['Feed', 'My Posts'],
            onChanged: (v) async {
              setState(() => _showMine = v == 1);
              if (v == 1 && _myPostsCache.isEmpty) {
                await _loadMine();
              }
            },
          ),
        const Spacer(),
        IconButton(
          tooltip: 'Refresh',
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
        IconButton(
          tooltip: 'Open full feed',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SocialFeedScreen()),
          ),
          icon: const Icon(Icons.open_in_new_rounded),
        )
      ],
    );

    Widget stories() {
      return SizedBox(
        height: 90,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemBuilder: (_, i) {
            final highlight = i == 0;
            return GestureDetector(
              onTap: () {},
              child: Column(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: highlight ? [cs.primary, cs.secondary] : [cs.secondary, cs.tertiary]),
                      boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: .30), blurRadius: 12, offset: const Offset(0,5))],
                    ),
                    padding: const EdgeInsets.all(3),
                    child: ClipOval(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [cs.surface, cs.surfaceContainerHighest.withValues(alpha: .6)]),
                        ),
                        child: Icon(highlight ? Icons.add : Icons.person, color: cs.primary, size: 26),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(highlight ? 'Add' : 'Creator', style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
                ],
              ),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemCount: 8,
        ),
      );
    }

    Widget quickActions() {
      final actions = [
        (Icons.image_outlined, 'Image'),
        (Icons.link_outlined, 'Link'),
        (Icons.poll_outlined, 'Poll'),
      ];
      return Wrap(
        spacing: 10,
        children: actions.map((a) => ActionChip(
          avatar: Icon(a.$1, size: 18, color: cs.primary),
          label: Text(a.$2),
          onPressed: () {},
          shape: StadiumBorder(side: BorderSide(color: cs.primary.withValues(alpha: .25))),
          backgroundColor: cs.surfaceContainerHighest.withValues(alpha: .35),
        )).toList(),
      );
    }

    Widget composer() => Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withValues(alpha: .15)),
        color: cs.surface.withValues(alpha: .65),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PostComposer(onCreated: _load),
          const SizedBox(height: 10),
          quickActions(),
        ],
      ),
    );

    Widget skeletonPost() => _FeedSkeleton(cs: cs);

    Widget postsList() {
      if (_showMine) {
        // My Posts grid variant
        if (_loadingMine) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (_myPostsCache.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(Icons.grid_on, size: 40, color: cs.primary),
                const SizedBox(height: 12),
                Text('You have no posts yet', style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface)),
                const SizedBox(height: 6),
                Text('Create a post above – media appears here.', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
              ],
            ),
          );
        }
        // Grid layout similar to Instagram
        return LayoutBuilder(
          builder: (ctx, c) {
            final width = c.maxWidth;
            int cross = 3;
            if (width > 760) cross = 5; else if (width > 520) cross = 4;
            final spacing = 4.0;
            final itemW = (width - (cross - 1) * spacing) / cross;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final p in _myPostsCache) _PostGridTile(post: p, size: itemW),
              ],
            );
          },
        );
      }
      final list = _showMine ? _myPosts : _posts;
      if (_loading) {
        return Column(
          children: List.generate(3, (i) => Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
            child: skeletonPost(),
          )),
        );
      }
      if (list.isEmpty) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 40),
          alignment: Alignment.center,
          child: Column(
            children: [
              Icon(Icons.feed_outlined, size: 40, color: cs.primary),
              const SizedBox(height: 12),
              Text(_showMine ? 'You have no posts yet' : 'No posts in your feed', style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface)),
              const SizedBox(height: 6),
              Text(_showMine ? 'Create your first post using the composer above.' : 'Follow more creators to populate your feed.', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
            ],
          ),
        );
      }
      return Column(
        children: [
          for (int i = 0; i < list.length; i++) ...[
            AnimatedSlide(
              duration: Duration(milliseconds: 300 + i * 50),
              curve: Curves.easeOutCubic,
              offset: const Offset(0, 0),
              child: AnimatedOpacity(
                duration: Duration(milliseconds: 380 + i * 60),
                opacity: 1,
                curve: Curves.easeOut,
                child: Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
                  child: SocialPostCard(post: list[i], key: ValueKey(list[i].id)),
                ),
              ),
            ),
          ]
        ],
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          // Glass gradient background
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cs.primary.withValues(alpha: .10),
                      cs.secondary.withValues(alpha: .08),
                      cs.tertiary.withValues(alpha: .06),
                    ],
                  ),
                ),
              ),
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withValues(alpha: .55)),
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: .08),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    header(),
                    const SizedBox(height: 12),
                    stories(),
                    const SizedBox(height: 14),
                    composer(),
                    const SizedBox(height: 18),
                    postsList(),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Small segmented control widget for header toggle
class _SegmentedSmall extends StatelessWidget {
  final int value;
  final List<String> labels;
  final ValueChanged<int> onChanged;
  const _SegmentedSmall({required this.value, required this.labels, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: .6),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: cs.primary.withValues(alpha: .25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < labels.length; i++) ...[
            GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: i == value ? cs.primary : Colors.transparent,
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: i == value ? cs.onPrimary : cs.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            if (i != labels.length - 1) const SizedBox(width: 4),
          ]
        ],
      ),
    );
  }
}

class _FeedSkeleton extends StatelessWidget {
  final ColorScheme cs;
  const _FeedSkeleton({required this.cs});
  @override
  Widget build(BuildContext context) {
    Widget bar(double w, double h, {double r = 10}) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: .5),
        borderRadius: BorderRadius.circular(r),
        gradient: LinearGradient(
          colors: [
            cs.surfaceContainerHighest.withValues(alpha: .55),
            cs.surfaceContainerHighest.withValues(alpha: .35),
            cs.surfaceContainerHighest.withValues(alpha: .55),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
    );

    return AnimatedOpacity(
      opacity: 1,
      duration: const Duration(milliseconds: 600),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: cs.surface.withValues(alpha: .55),
          border: Border.all(color: cs.primary.withValues(alpha: .08)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 20, backgroundColor: cs.primary.withValues(alpha: .25)),
                const SizedBox(width: 12),
                Expanded(child: bar(double.infinity, 14)),
              ],
            ),
            const SizedBox(height: 14),
            bar(double.infinity, 12),
            const SizedBox(height: 8),
            bar(220, 12),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [cs.primary.withValues(alpha: .15), cs.secondary.withValues(alpha: .15)]),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// NEW: grid tile for My Posts view
class _PostGridTile extends StatelessWidget {
  final SocialPost post;
  final double size;
  const _PostGridTile({required this.post, required this.size});
  @override
  Widget build(BuildContext context) {
    final media = post.mediaItems.isNotEmpty ? post.mediaItems.first : null;
    final isVideo = media?.isVideo == true;
    return GestureDetector(
      onTap: () => _open(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Container(
              width: size,
              height: size,
              color: Colors.grey.shade200,
              child: media == null
                  ? Center(
                      child: Text(
                        post.content.isEmpty ? 'Post' : post.content.substring(0, post.content.length.clamp(0, 28)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    )
                  : Image.network(media.thumbnailUrl ?? media.url, fit: BoxFit.cover),
            ),
            if (isVideo)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .55),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.play_arrow_rounded, size: 18, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: .85),
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Material(
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: SocialPostCard(post: post),
            ),
          ),
        ),
      ),
    );
  }
}
