// lib/sections/user_search_follow.dart
// Enhanced Creator search & follow widget

import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <-- needed for RawKeyEvent / LogicalKeyboardKey
import 'package:gigmework/sections/creator_profile_view.dart';
import '../api/social_api.dart';
import '../models/social_post.dart';

/// Enhanced UserSearchFollow
/// Features:
/// - compact / regular modes
/// - recent searches chips
/// - keyboard navigation (Arrow Up/Down + Enter)
/// - animated follow/unfollow with optimistic update and loading state
/// - accessible semantics and focus handling
/// - improved skeleton while loading
class UserSearchFollow extends StatefulWidget {
  final int viewerId;
  final bool compact;
  const UserSearchFollow({super.key, required this.viewerId, this.compact = false});
  @override
  State<UserSearchFollow> createState() => _UserSearchFollowState();
}

class _UserSearchFollowState extends State<UserSearchFollow> {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<CreatorSuggestion> _results = [];
  final List<String> _recent = []; // simple recent search cache (in-memory)
  bool _loading = false;
  Timer? _debounce;
  int _selectedIndex = -1; // keyboard selection
  final Map<int, bool> _rowLoading = {}; // per-user loading

  // mutable list accessor
  List<CreatorSuggestion> get _list => _results;
  set _list(List<CreatorSuggestion> v) {
    _results
      ..clear()
      ..addAll(v);
  }

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onChanged);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() => _selectedIndex = -1);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.removeListener(_onChanged);
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged() {
    // immediate rebuild so clear icon appears
    if (mounted) setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(_ctrl.text));
  }

  Future<void> _search(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      if (mounted) setState(() { _list = const []; _loading = false; });
      return;
    }

    // record recent without duplicates
    if (q.isNotEmpty) {
      _recent.remove(q);
      _recent.insert(0, q);
      if (_recent.length > 8) _recent.removeLast();
    }

    setState(() { _loading = true; _selectedIndex = -1; });
    try {
      final r = await SocialApi.instance.searchCreators(q, viewerId: widget.viewerId);
      if (!mounted) return;
      setState(() { _list = r; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _list = []; _loading = false; });
      // optional: show error
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Search failed')));
    }
  }

  Future<void> _toggleFollow(CreatorSuggestion c) async {
    // prevent duplicate taps
    if (_rowLoading[c.userId] == true) return;
    final follow = !c.followedByMe;
    // optimistic UI
    setState(() {
      _rowLoading[c.userId] = true;
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
      // revert on error
      if (!mounted) return;
      setState(() {
        _list = _list.map((x) => x.userId == c.userId ? CreatorSuggestion(
          userId: x.userId,
          name: x.name,
          title: x.title,
          avatarUrl: x.avatarUrl,
          followedByMe: !follow,
          followerCount: (x.followerCount + (!follow ? 1 : -1)).clamp(0, 1 << 31),
        ) : x).toList();
        _rowLoading.remove(c.userId);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(follow ? 'Failed to follow' : 'Failed to unfollow')));
      return;
    }

    if (!mounted) return;
    setState(() {
      _rowLoading.remove(c.userId);
    });
  }

  // keyboard handling for list navigation
  void _onKey(RawKeyEvent ev) {
    // Only respond to physical key down events (prevents duplicate handling)
    if (ev is RawKeyDownEvent) {
      final key = ev.logicalKey;
      if (key == LogicalKeyboardKey.arrowDown) {
        if (_list.isEmpty) return;
        setState(() {
          _selectedIndex = (_selectedIndex + 1).clamp(0, _list.length - 1);
        });
      } else if (key == LogicalKeyboardKey.arrowUp) {
        if (_list.isEmpty) return;
        setState(() {
          _selectedIndex = (_selectedIndex - 1).clamp(0, _list.length - 1);
        });
      } else if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.select) {
        if (_selectedIndex >= 0 && _selectedIndex < _list.length) {
          final c = _list[_selectedIndex];
          _openProfile(c);
        } else {
          _search(_ctrl.text);
        }
      }
    }
  }

  Future<void> _openProfile(CreatorSuggestion c) async {
    final updated = await Navigator.of(context).push<CreatorSuggestion>(
      MaterialPageRoute(builder: (_) => CreatorProfileView(viewerId: widget.viewerId, initial: c)),
    );
    if (updated != null && mounted) {
      setState(() {
        final idx = _list.indexWhere((e) => e.userId == updated.userId);
        if (idx != -1) _list[idx] = updated;
      });
    }
  }

  Widget _recentChips() {
    if (_recent.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 8, runSpacing: 8, children: _recent.map((s) {
      return ActionChip(label: Text(s, overflow: TextOverflow.ellipsis), onPressed: () { _ctrl.text = s; _search(s); });
    }).toList());
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(12));
    final verticalSpacing = widget.compact ? 6.0 : 12.0;
    final maxListHeight = widget.compact ? 260.0 : 360.0;

    return RawKeyboardListener(
      focusNode: FocusNode(),
      onKey: _onKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search field
          TextField(
            controller: _ctrl,
            focusNode: _focusNode,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: widget.compact ? 'Search creators' : 'Search creators by @handle or name',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              border: border,
              enabledBorder: border.copyWith(borderSide: const BorderSide(color: Colors.black12)),
              focusedBorder: border.copyWith(borderSide: const BorderSide(color: Colors.blueAccent)),
              suffixIcon: _ctrl.text.isEmpty
                  ? null
                  : IconButton(
                tooltip: 'Clear',
                icon: const Icon(Icons.clear),
                onPressed: () { _ctrl.clear(); _onChanged(); _focusNode.requestFocus(); },
              ),
            ),
            onSubmitted: (_) => _search(_ctrl.text),
            onEditingComplete: () => FocusScope.of(context).unfocus(),
          ),

          const SizedBox(height: 6),
          _recentChips(),

          SizedBox(height: verticalSpacing),

          if (_loading) ...[
            const SizedBox(height: 8),
            _SkeletonSuggestionList(compact: widget.compact, maxHeight: maxListHeight),
          ] else if (_list.isNotEmpty) ...[
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
                  return _CreatorRowEnhanced(
                    c: c,
                    selected: i == _selectedIndex,
                    loading: _rowLoading[c.userId] == true,
                    onToggle: () => _toggleFollow(c),
                    onOpen: () => _openProfile(c),
                    viewerId: widget.viewerId,
                  );
                },
              ),
            ),
          ] else if (!_loading && _ctrl.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('No creators found', style: TextStyle(color: Colors.black54)),
          ],
        ],
      ),
    );
  }
}

// ---------- Enhanced Row ----------
class _CreatorRowEnhanced extends StatelessWidget {
  final CreatorSuggestion c;
  final bool selected;
  final bool loading;
  final VoidCallback onToggle;
  final VoidCallback onOpen;
  final int viewerId;

  const _CreatorRowEnhanced({required this.c, required this.selected, required this.loading, required this.onToggle, required this.onOpen, required this.viewerId});

  String _fmt(int v) {
    if (v >= 1000000) return (v / 1000000).toStringAsFixed(1) + 'M';
    if (v >= 1000) return (v / 1000).toStringAsFixed(1) + 'k';
    return v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600);
    final bg = selected ? Theme.of(context).colorScheme.primary.withOpacity(0.06) : Colors.transparent;

    return Material(
      color: bg,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Row(
            children: [
              _AvatarEnhanced(url: c.avatarUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Flexible(child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 6),
                      if (c.title.isNotEmpty) Container(padding: const EdgeInsets.symmetric(horizontal:6, vertical:2), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)), child: Text(c.title, style: const TextStyle(fontSize: 11))),
                    ]),
                    const SizedBox(height: 4),
                    Row(children: [
                      Text('${_fmt(c.followerCount)} followers', style: titleStyle),
                    ])
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _FollowButtonEnhanced(followed: c.followedByMe, loading: loading, onPressed: onToggle),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarEnhanced extends StatelessWidget {
  final String? url;
  const _AvatarEnhanced({this.url});
  @override
  Widget build(BuildContext context) {
    final placeholder = CircleAvatar(radius: 22, backgroundColor: Colors.blueGrey.shade100, child: const Icon(Icons.person, color: Colors.white70));
    if (url == null || url!.isEmpty) return placeholder;
    return CircleAvatar(
      radius: 22,
      backgroundColor: Colors.grey.shade200,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: url!,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          placeholder: (_, __) => placeholder,
          errorWidget: (_, __, ___) => placeholder,
        ),
      ),
    );
  }
}

class _FollowButtonEnhanced extends StatelessWidget {
  final bool followed;
  final bool loading;
  final VoidCallback onPressed;
  const _FollowButtonEnhanced({required this.followed, required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    if (loading) return SizedBox(width: 92, height: 36, child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))));

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
      child: followed
          ? OutlinedButton(
        key: const ValueKey('following'),
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(minimumSize: const Size(92, 36)),
        child: const Text('Following'),
      )
          : FilledButton(
        key: const ValueKey('follow'),
        onPressed: onPressed,
        style: FilledButton.styleFrom(minimumSize: const Size(92, 36)),
        child: const Text('Follow'),
      ),
    );
  }
}

// Keep skeletons from original file (reused)
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
    final items = widget.compact ? 4 : 6;
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
              Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: double.infinity, height: 12, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(6))),
                const SizedBox(height: 8),
                Container(width: 120, height: 10, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(6))),
              ])),
              const SizedBox(width: 12),
              Container(width: 92, height: 36, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(18))),
            ],
          ),
        );
      },
    );
  }
}
