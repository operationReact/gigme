import 'package:flutter/material.dart';
import '../api/social_api.dart';
import '../models/social_post.dart';

class WhoToFollow extends StatefulWidget {
  final int userId;
  const WhoToFollow({super.key, required this.userId});

  @override
  State<WhoToFollow> createState() => _WhoToFollowState();
}

class _WhoToFollowState extends State<WhoToFollow> {
  List<CreatorSuggestion> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final s = await SocialApi.instance.suggestions(widget.userId);
    if (mounted) setState(() { _list = s; _loading = false; });
  }

  Future<void> _toggle(CreatorSuggestion c) async {
    final follow = !c.followedByMe;
    setState(() {
      _list = _list.map((x) => x.userId == c.userId ? CreatorSuggestion(
          userId: x.userId, name: x.name, title: x.title, avatarUrl: x.avatarUrl, followedByMe: follow
      ) : x).toList();
    });
    if (follow) await SocialApi.instance.follow(c.userId);
    else await SocialApi.instance.unfollow(c.userId);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Wrap(spacing: 8, children: [Chip(label: Text('…')), Chip(label: Text('…'))]);
    }
    if (_list.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _list.map((c) {
        return InputChip(
          avatar: const CircleAvatar(child: Icon(Icons.person, size: 16)),
          label: Text('${c.name} • ${c.title}'),
          onPressed: () {},
          deleteIcon: Icon(c.followedByMe ? Icons.check : Icons.add),
          onDeleted: () => _toggle(c),
        );
      }).toList(),
    );
  }
}
