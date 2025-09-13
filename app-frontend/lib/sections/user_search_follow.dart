// Reconstructed creator search & follow widget.
import 'dart:async';
import 'package:flutter/material.dart';
import '../api/social_api.dart';
import '../models/social_post.dart';

class UserSearchFollow extends StatefulWidget {
  final int viewerId;
  final bool compact;
  const UserSearchFollow({super.key, required this.viewerId, this.compact = false});
  @override
  State<UserSearchFollow> createState() => _UserSearchFollowState();
}

class _UserSearchFollowState extends State<UserSearchFollow> {
  final TextEditingController _ctrl = TextEditingController();
  final List<CreatorSuggestion> _results = [];
  bool _loading = false;
  Timer? _debounce;

  // Mutable list accessor (since _results is final) via getter/setter pattern
  List<CreatorSuggestion> get _list => _results;
  set _list(List<CreatorSuggestion> v) { _results
    ..clear()
    ..addAll(v);
  }

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.removeListener(_onChanged);
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged() {
    // Rebuild to show / hide clear button instantly.
    if (mounted) setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(_ctrl.text));
  }

  Future<void> _search(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      if (mounted) setState(() { _list = const []; });
      return;
    }
    setState(() => _loading = true);
    final r = await SocialApi.instance.searchCreators(q, viewerId: widget.viewerId);
    if (!mounted) return;
    setState(() { _list = r; _loading = false; });
  }

  Future<void> _toggle(CreatorSuggestion c) async {
    final follow = !c.followedByMe;
    setState(() {
      _list = _list.map((x) => x.userId == c.userId ? CreatorSuggestion(
        userId: x.userId,
        name: x.name,
        title: x.title,
        avatarUrl: x.avatarUrl,
        followedByMe: follow,
      ) : x).toList();
    });
    try {
      if (follow) {
        await SocialApi.instance.follow(c.userId, viewerId: widget.viewerId);
      } else {
        await SocialApi.instance.unfollow(c.userId, viewerId: widget.viewerId);
      }
    } catch (_) {
      if (!mounted) return;
      // revert on error
      setState(() {
        _list = _list.map((x) => x.userId == c.userId ? CreatorSuggestion(
          userId: x.userId,
          name: x.name,
          title: x.title,
          avatarUrl: x.avatarUrl,
          followedByMe: !follow,
        ) : x).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(follow ? 'Failed to follow' : 'Failed to unfollow')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(12));
    final verticalSpacing = widget.compact ? 6.0 : 12.0; // denser in compact mode

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _ctrl,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: widget.compact ? 'Search creators' : 'Search creators by @handle or name',
            prefixIcon: const Icon(Icons.search),
            isDense: true,
            border: border,
            enabledBorder: border.copyWith(borderSide: const BorderSide(color: Colors.black12)),
            focusedBorder: border.copyWith(borderSide: const BorderSide(color: Colors.blueAccent)),
            suffixIcon: _ctrl.text.isEmpty ? null : IconButton(
              tooltip: 'Clear',
              icon: const Icon(Icons.clear),
              onPressed: () { _ctrl.clear(); _onChanged(); },
            ),
          ),
          onSubmitted: _search,
        ),
        SizedBox(height: verticalSpacing),
        if (_loading) const LinearProgressIndicator(minHeight: 2),
        if (_list.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _list.map((c) => _CreatorChip(c: c, onTap: () => _toggle(c))).toList(),
          ),
        ] else if (!_loading && _ctrl.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text('No creators found', style: TextStyle(color: Colors.black54)),
        ],
      ],
    );
  }
}

class _CreatorChip extends StatelessWidget {
  final CreatorSuggestion c;
  final VoidCallback onTap;
  const _CreatorChip({required this.c, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InputChip(
      avatar: CircleAvatar(
        backgroundColor: Colors.blueGrey.shade100,
        child: c.avatarUrl == null ? const Icon(Icons.person, size: 16) : null,
      ),
      label: Text('${c.name} • ${c.title.isEmpty ? 'Creator' : c.title}'),
      onPressed: () {},
      deleteIcon: Icon(c.followedByMe ? Icons.check : Icons.add),
      onDeleted: onTap,
      tooltip: c.followedByMe ? 'Unfollow' : 'Follow',
    );
  }
}