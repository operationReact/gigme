import 'package:flutter/material.dart';
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
    final data = await SocialApi.instance.listFeed(viewerId: widget.viewerId, page: 1, pageSize: 3);
    if (mounted) setState(() { _posts = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Creator Feed', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed(SocialFeedScreen.route),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('See all'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            PostComposer(onCreated: _load),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_posts.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No posts yet. Say hi 👋'),
              )
            else
              ..._posts.map((p) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SocialPostCard(post: p),
              )),
          ],
        ),
      ),
    );
  }
}
