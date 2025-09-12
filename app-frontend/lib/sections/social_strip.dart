import 'package:flutter/material.dart';
import '../api/social_api.dart';
import '../models/social_post.dart';
import '../screens/social_feed.dart';

class SocialStrip extends StatefulWidget {
  final int userId;
  const SocialStrip({super.key, required this.userId});

  @override
  State<SocialStrip> createState() => _SocialStripState();
}

class _SocialStripState extends State<SocialStrip> {
  SocialCounts? _counts;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final c = await SocialApi.instance.getCounts(widget.userId);
    if (mounted) setState(() { _counts = c; _loading = false; });
  }

  Widget _pill(String label, int value, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text('$value $label'),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _counts == null) {
      return Wrap(
        spacing: 8,
        children: const [
          Chip(label: Text('···')),
          Chip(label: Text('···')),
          Chip(label: Text('···')),
        ],
      );
    }
    return Row(
      children: [
        _pill('Posts', _counts!.posts, Icons.article_outlined),
        const SizedBox(width: 8),
        _pill('Followers', _counts!.followers, Icons.group_outlined),
        const SizedBox(width: 8),
        _pill('Following', _counts!.following, Icons.person_add_alt_1_outlined),
        const Spacer(),
        TextButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SocialFeedScreen()),
          ),
          icon: const Icon(Icons.dynamic_feed_outlined),
          label: const Text('Open feed'),
        )
      ],
    );
  }
}
