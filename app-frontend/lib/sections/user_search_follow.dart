// Reconstructed creator search & follow widget.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gigmework/sections/creator_profile_view.dart';
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
        followerCount: (x.followerCount + (follow ? 1 : -1)).clamp(0, 1 << 31),
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
          followerCount: (x.followerCount + (!follow ? 1 : -1)).clamp(0, 1 << 31),
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
    final maxListHeight = widget.compact ? 260.0 : 360.0; // limit height like Instagram suggestions panel

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
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxListHeight),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemCount: _list.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (ctx, i) {
                final c = _list[i];
                return _CreatorRow(
                  c: c,
                  onToggle: () => _toggle(c),
                  viewerId: widget.viewerId,
                  onOpenedResult: (updated) {
                    // update the list with the returned data
                    setState(() {
                      _list[_list.indexWhere((element) => element.userId == updated.userId)] = updated;
                    });
                  },
                );
              },
            ),
          ),
        ] else if (!_loading && _ctrl.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text('No creators found', style: TextStyle(color: Colors.black54)),
        ],
      ],
    );
  }
}

class _CreatorRow extends StatelessWidget {
  final CreatorSuggestion c;
  final VoidCallback onToggle;
  final int viewerId;
  final ValueChanged<CreatorSuggestion> onOpenedResult;
  const _CreatorRow({required this.c, required this.onToggle, required this.viewerId, required this.onOpenedResult});

  String _fmt(int v) {
    if (v >= 1000000) return (v / 1000000).toStringAsFixed(1) + 'M';
    if (v >= 1000) return (v / 1000).toStringAsFixed(1) + 'k';
    return v.toString();
  }
  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600);
    return InkWell(
      onTap: () async {
        final updated = await Navigator.of(context).push<CreatorSuggestion>(
          MaterialPageRoute(builder: (_) => CreatorProfileView(viewerId: viewerId, initial: c)),
        );
        if (updated != null) onOpenedResult(updated);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            _Avatar(url: c.avatarUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          c.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, size: 16, color: Colors.blueAccent),
                    ],
                  ),
                  if (c.title.trim().isNotEmpty)
                    Text(c.title, style: titleStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(_fmt(c.followerCount) + ' followers', style: titleStyle),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _FollowButton(
              followed: c.followedByMe,
              onPressed: onToggle,
            )
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  const _Avatar({this.url});
  @override
  Widget build(BuildContext context) {
    final placeholder = CircleAvatar(
      radius: 20,
      backgroundColor: Colors.blueGrey.shade100,
      child: const Icon(Icons.person, color: Colors.white70),
    );
    if (url == null || url!.isEmpty) return placeholder;
    return CircleAvatar(
      radius: 20,
      backgroundImage: NetworkImage(url!),
      backgroundColor: Colors.grey.shade200,
      onBackgroundImageError: (_, __) {},
    );
  }
}

class _FollowButton extends StatelessWidget {
  final bool followed;
  final VoidCallback onPressed;
  const _FollowButton({required this.followed, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    if (followed) {
      return OutlinedButton(
        style: OutlinedButton.styleFrom(minimumSize: const Size(88, 36), padding: const EdgeInsets.symmetric(horizontal: 16)),
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

// (Legacy chip widget kept in case other screens reference it)
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

class _SkeletonSuggestionList extends StatefulWidget {
  final bool compact;
  final double maxHeight;
  const _SkeletonSuggestionList({required this.compact, required this.maxHeight});
  @override
  State<_SkeletonSuggestionList> createState() => _SkeletonSuggestionListState();
}

class _SkeletonSuggestionListState extends State<_SkeletonSuggestionList> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final items = widget.compact ? 5 : 7;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: widget.maxHeight),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: items,
        itemBuilder: (_, i) => _ShimmerRow(anim: _c),
      ),
    );
  }
}

class _ShimmerRow extends StatelessWidget {
  final Animation<double> anim;
  const _ShimmerRow({required this.anim});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.grey.shade300,
                      Colors.grey.shade100,
                      Colors.grey.shade300,
                    ],
                    stops: [0, (anim.value * .5) + .25, 1],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bar(widthFactor: .6, anim: anim),
                    const SizedBox(height: 6),
                    _bar(widthFactor: .4, anim: anim),
                    const SizedBox(height: 4),
                    _bar(widthFactor: .3, anim: anim),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 88,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    colors: [
                      Colors.grey.shade300,
                      Colors.grey.shade100,
                      Colors.grey.shade300,
                    ],
                    stops: [0, (anim.value * .5) + .25, 1],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  Widget _bar({required double widthFactor, required Animation<double> anim}) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: 10,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          gradient: LinearGradient(
            colors: [
              Colors.grey.shade300,
              Colors.grey.shade100,
              Colors.grey.shade300,
            ],
            stops: [0, (anim.value * .5) + .25, 1],
          ),
        ),
      ),
    );
  }
}
