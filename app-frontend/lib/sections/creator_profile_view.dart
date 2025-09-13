import 'package:flutter/material.dart';
import '../api/social_api.dart';
import '../models/social_post.dart';

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

  bool get _isSelf => widget.viewerId == _c.userId;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    setState(() => _loadingCounts = true);
    try {
      final sc = await SocialApi.instance.getCounts(_c.userId);
      if (mounted) setState(() { _counts = sc; });
    } catch (_) {} finally { if (mounted) setState(() => _loadingCounts = false); }
  }

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

  String _fmt(int v) {
    if (v >= 1000000) return (v / 1000000).toStringAsFixed(1) + 'M';
    if (v >= 1000) return (v / 1000).toStringAsFixed(1) + 'k';
    return v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final followers = _counts?.followers ?? _c.followerCount;
    final posts = _counts?.posts ?? 0;
    final following = _counts?.following ?? 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pop(context, _c);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_c.name, overflow: TextOverflow.ellipsis),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _c),
          ),
          actions: [
            if (!_isSelf)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: _FollowButton(
                  followed: _c.followedByMe,
                  onPressed: _toggling ? null : _toggleFollow,
                ),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundImage: _c.avatarUrl != null ? NetworkImage(_c.avatarUrl!) : null,
                backgroundColor: Colors.blueGrey.shade100,
                child: _c.avatarUrl == null ? const Icon(Icons.person, size: 42) : null,
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.verified, size: 18, color: Colors.blueAccent),
                ],
              ),
              const SizedBox(height: 6),
              Text(_c.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              if (_c.title.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(_c.title, style: const TextStyle(color: Colors.grey)),
                ),
              const SizedBox(height: 16),
              _loadingCounts ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Metric(label: 'Posts', value: _fmt(posts)),
                    _Divider(),
                    _Metric(label: 'Followers', value: _fmt(followers)),
                    _Divider(),
                    _Metric(label: 'Following', value: _fmt(following)),
                  ],
                ),
              const SizedBox(height: 24),
              if (!_isSelf)
                _FollowButton(
                  followed: _c.followedByMe,
                  onPressed: _toggling ? null : _toggleFollow,
                ),
              const SizedBox(height: 40),
              const Text('Recent posts coming soon...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label; final String value;
  const _Metric({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
    ],
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 18),
    width: 1, height: 30, color: Colors.grey.shade300,
  );
}

class _FollowButton extends StatelessWidget {
  final bool followed; final VoidCallback? onPressed;
  const _FollowButton({required this.followed, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    if (followed) {
      return OutlinedButton(onPressed: onPressed, child: const Text('Following'));
    }
    return FilledButton(onPressed: onPressed, child: const Text('Follow'));
  }
}
