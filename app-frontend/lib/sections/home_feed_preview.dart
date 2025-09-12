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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await SocialApi.instance.listFeed(viewerId: widget.viewerId, page: 1, pageSize: 4);
      if (!mounted) return;
      setState(() { _posts = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
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
            'Creator Feed',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -.5),
          ),
        ),
        const SizedBox(width: 8),
        if (_posts.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: .65),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('${_posts.length} new', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onPrimaryContainer)),
          ),
        const Spacer(),
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
      if (_loading) {
        return Column(
          children: List.generate(3, (i) => Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
            child: skeletonPost(),
          )),
        );
      }
      if (_posts.isEmpty) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 32),
          alignment: Alignment.center,
          child: Text('No posts yet. Say hi 👋', style: TextStyle(color: cs.onSurfaceVariant)),
        );
      }
      return Column(
        children: [
          for (int i = 0; i < _posts.length; i++) ...[
            AnimatedSlide(
              duration: Duration(milliseconds: 300 + i * 60),
              curve: Curves.easeOutCubic,
              offset: Offset(0, 0),
              child: AnimatedOpacity(
                duration: Duration(milliseconds: 400 + i * 70),
                opacity: 1,
                curve: Curves.easeOut,
                child: Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
                  child: SocialPostCard(post: _posts[i]),
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
