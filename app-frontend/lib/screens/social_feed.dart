import 'package:flutter/material.dart';
import '../api/social_api.dart';
import '../models/social_post.dart';
import '../widgets/post_composer.dart';
import '../widgets/social_post_card.dart';
import '../services/session_service.dart';

class SocialFeedScreen extends StatefulWidget {
  static const route = '/social/feed';
  const SocialFeedScreen({super.key});

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  final _posts = <SocialPost>[];
  final _controller = ScrollController();
  bool _loading = true;
  bool _loadingMore = false;
  int _page = 1;
  bool _done = false;

  int get _viewerId => SessionService.instance.user?.id ?? 0;

  @override
  void initState() {
    super.initState();
    _load();
    _controller.addListener(() {
      if (_controller.position.pixels > _controller.position.maxScrollExtent - 400) {
        _loadMore();
      }
    });
  }

  Future<void> _load() async {
    setState(() { _loading = true; _done = false; _page = 1; _posts.clear(); });
    final batch = await SocialApi.instance.listFeed(viewerId: _viewerId, page: _page);
    setState(() {
      _posts.addAll(batch);
      _loading = false;
      _done = batch.isEmpty;
    });
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || _done) return;
    setState(() => _loadingMore = true);
    final next = _page + 1;
    final batch = await SocialApi.instance.listFeed(viewerId: _viewerId, page: next);
    setState(() {
      _page = next;
      _posts.addAll(batch);
      _loadingMore = false;
      if (batch.isEmpty) _done = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Feed')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          controller: _controller,
          padding: const EdgeInsets.all(16),
          itemCount: _posts.length + 2,
          itemBuilder: (context, i) {
            if (i == 0) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PostComposer(onCreated: _load),
                  const SizedBox(height: 12),
                ],
              );
            }
            if (i - 1 < _posts.length) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SocialPostCard(post: _posts[i - 1]),
              );
            }
            // loader/footer
            if (_loading || _loadingMore) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return const SizedBox(height: 60);
          },
        ),
      ),
    );
  }
}
