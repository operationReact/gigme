// lib/widgets/social_post_card.dart
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/social_post.dart';
import '../api/social_api.dart';
import '../services/session_service.dart';

/// Rich SocialPostCard
/// - Double-tap heart animation
/// - Inline lazy video player
/// - Thumbnail strip + page indicator
/// - Read-more collapse
/// - Cached images + hero full-screen viewer
class SocialPostCard extends StatefulWidget {
  final SocialPost post;
  const SocialPostCard({super.key, required this.post});

  @override
  State<SocialPostCard> createState() => _SocialPostCardState();
}

class _SocialPostCardState extends State<SocialPostCard> with TickerProviderStateMixin {
  late SocialPost _p = widget.post;
  final PageController _pageController = PageController();
  int _page = 0;

  // double-tap heart
  bool _showHeart = false;
  late final AnimationController _heartCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  late final Animation<double> _heartScale = CurvedAnimation(parent: _heartCtrl, curve: Curves.elasticOut);

  // like button animation
  late final AnimationController _likeIconCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 160));

  // inline video players keyed by media index - lazy init when tapped
  final Map<int, VideoPlayerController> _videoControllers = {};
  final Map<int, ChewieController> _chewieControllers = {};
  final Set<int> _playingInline = {}; // indexes that are currently showing inline player

  // read-more
  bool _expanded = false;

  @override
  void dispose() {
    _heartCtrl.dispose();
    _likeIconCtrl.dispose();
    _pageController.dispose();
    for (final vc in _videoControllers.values) {
      try {
        vc.pause();
        vc.dispose();
      } catch (_) {}
    }
    for (final cc in _chewieControllers.values) {
      try {
        cc.dispose();
      } catch (_) {}
    }
    super.dispose();
  }

  bool get _isSample => _p.id < 0;

  // ---------- Helpers ----------
  Future<void> _toggleLike({bool animate = true}) async {
    final like = !_p.likedByMe;
    setState(() {
      _p = _p.copyWith(
        likedByMe: like,
        likeCount: like ? _p.likeCount + 1 : (_p.likeCount - 1).clamp(0, 1 << 31),
      );
    });
    if (animate) {
      if (like) {
        _likeIconCtrl.forward(from: 0);
      } else {
        _likeIconCtrl.reverse();
      }
    }
    final userId = SessionService.instance.user?.id;
    if (userId != null) {
      try {
        await SocialApi.instance.like(_p.id, like: like, userId: userId);
      } catch (_) {
        // revert on error
        if (!mounted) return;
        setState(() {
          _p = _p.copyWith(
            likedByMe: !like,
            likeCount: like ? (_p.likeCount - 1).clamp(0, 1 << 31) : _p.likeCount + 1,
          );
        });
      }
    }
  }

  Future<void> _onDoubleTapLike() async {
    setState(() => _showHeart = true);
    _heartCtrl.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) setState(() => _showHeart = false);
    if (!_p.likedByMe) await _toggleLike();
  }

  String _timeAgo(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    return '${d.inDays}d';
  }

  // ---------- Inline video helpers ----------
  Future<void> _initInlineVideo(int index, String url) async {
    if (_videoControllers.containsKey(index)) return;
    try {
      final vc = VideoPlayerController.network(url);
      await vc.initialize();
      final cc = ChewieController(
        videoPlayerController: vc,
        autoPlay: true,
        looping: true,
        showControls: false,
        allowPlaybackSpeedChanging: false,
      );
      _videoControllers[index] = vc;
      _chewieControllers[index] = cc;
    } catch (_) {
      // ignore: don't crash the card on video init error
    }
  }

  Future<void> _disposeInlineVideo(int index) async {
    try {
      _chewieControllers[index]?.dispose();
    } catch (_) {}
    try {
      await _videoControllers[index]?.pause();
      _videoControllers[index]?.dispose();
    } catch (_) {}
    _chewieControllers.remove(index);
    _videoControllers.remove(index);
  }

  Future<void> _onTapVideoInline(int index, SocialMediaItem m) async {
    // If already showing inline, toggle play/pause
    if (_playingInline.contains(index)) {
      final vc = _videoControllers[index];
      if (vc != null) {
        vc.value.isPlaying ? await vc.pause() : await vc.play();
      }
      return;
    }

    // Lazy init and set to inline playing
    await _initInlineVideo(index, m.url);
    if (!mounted) return;
    setState(() => _playingInline.add(index));
  }

  // show full-screen image viewer
  Future<void> _openImageFullScreen(String url, String heroTag) async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            color: Colors.black,
            child: Center(
              child: Hero(
                tag: heroTag,
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const SizedBox(),
                    errorWidget: (_, __, ___) => const Icon(Icons.broken_image, size: 80, color: Colors.white70),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // dispose any inline videos to free memory when leaving
    for (final idx in _playingInline.toList()) {
      await _disposeInlineVideo(idx);
    }
    _playingInline.clear();
  }

  // ---------- UI pieces ----------
  Widget _avatarHeader() {
    final sessionUserId = SessionService.instance.user?.id;
    final isMine = sessionUserId != null && sessionUserId == _p.authorId;

    return Row(
      children: [
        // Avatar with ring when sample/verified
        Stack(
          alignment: Alignment.center,
          children: [
            if (_isSample)
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF3B82F6)]),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(2.5),
                child: Container(),
              )
            else
              Container(width: 46, height: 46),
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey.shade100,
              child: ClipOval(
                child: _p.authorAvatarUrl == null
                    ? const Icon(Icons.person, size: 20)
                    : CachedNetworkImage(
                  imageUrl: _p.authorAvatarUrl!,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const SizedBox(),
                  errorWidget: (_, __, ___) => const Icon(Icons.person),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text(_p.authorName, style: const TextStyle(fontWeight: FontWeight.w700))),
              const SizedBox(width: 8),
              if (isMine)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                  child: const Text('You', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.blue)),
                ),
              if (_isSample)
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(6)),
                  child: const Text('Sample', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.deepPurple)),
                ),
            ]),
            const SizedBox(height: 2),
            Text(_timeAgo(_p.createdAt), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ]),
        ),
        IconButton(onPressed: () => _showPostActions(), icon: const Icon(Icons.more_horiz)),
      ],
    );
  }

  void _showPostActions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(children: [
          ListTile(leading: const Icon(Icons.share), title: const Text('Share'), onTap: () => Navigator.of(context).pop()),
          ListTile(leading: const Icon(Icons.bookmark_border), title: const Text('Save'), onTap: () => Navigator.of(context).pop()),
          ListTile(leading: const Icon(Icons.report), title: const Text('Report'), onTap: () => Navigator.of(context).pop()),
        ]),
      ),
    );
  }

  Widget _buildMediaItem(SocialMediaItem m, {required int index}) {
    final heroTag = 'post_${_p.id}_media_$index';
    if (m.isVideo) {
      // If inline is playing for this index, show the player
      if (_playingInline.contains(index) && _videoControllers.containsKey(index) && _chewieControllers.containsKey(index)) {
        final cc = _chewieControllers[index]!;
        final vc = _videoControllers[index]!;
        return AspectRatio(
          aspectRatio: vc.value.isInitialized && vc.value.aspectRatio > 0 ? vc.value.aspectRatio : 16 / 9,
          child: Stack(children: [
            Chewie(controller: cc),
            // overlay controls (small)
            Positioned(bottom: 8, left: 8, child: _smallOverlayControls(index)),
            Positioned(top: 8, right: 8, child: _collapseInlineButton(index)),
          ]),
        );
      }

      // Video tile with thumbnail + play overlay
      return GestureDetector(
        onTap: () => _onTapVideoInline(index, m),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: m.thumbnailUrl ?? m.url,
                fit: BoxFit.cover,
                placeholder: (_, __) => const _MediaSkeleton(),
                errorWidget: (_, __, ___) => Container(color: Colors.black12, child: const Center(child: Icon(Icons.videocam, size: 44))),
              ),
              Positioned.fill(
                child: Container(alignment: Alignment.center, child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
                )),
              )
            ],
          ),
        ),
      );
    }

    // Image tile with double-tap heart + hero preview
    return GestureDetector(
      onDoubleTap: _onDoubleTapLike,
      onTap: () => _openImageFullScreen(m.url, heroTag),
      child: Hero(
        tag: heroTag,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: m.url,
                fit: BoxFit.cover,
                placeholder: (_, __) => const _MediaSkeleton(),
                errorWidget: (_, __, ___) => Container(color: Colors.grey.shade200, child: const Center(child: Icon(Icons.broken_image))),
              ),
              // heart animation
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _heartCtrl,
                      builder: (_, __) => Opacity(
                        opacity: _showHeart ? (1.0 - (_heartCtrl.value * 0.8)) : 0.0,
                        child: Transform.scale(
                          scale: _showHeart ? (0.8 + _heartScale.value * 1.2) : 0.0,
                          child: const Icon(Icons.favorite, size: 110, color: Colors.white70),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _smallOverlayControls(int index) {
    final vc = _videoControllers[index];
    if (vc == null) return const SizedBox.shrink();
    return Row(children: [
      GestureDetector(
        onTap: () async {
          vc.value.isPlaying ? await vc.pause() : await vc.play();
          setState(() {});
        },
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(8)),
          child: Icon(vc.value.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
        ),
      ),
      const SizedBox(width: 8),
      GestureDetector(
        onTap: () {
          // open fullscreen player dialog
          final cc = _chewieControllers[index];
          if (cc != null) {
            showDialog(context: context, builder: (_) => Dialog(
              backgroundColor: Colors.black,
              insetPadding: const EdgeInsets.all(12),
              child: AspectRatio(
                aspectRatio: vc.value.isInitialized && vc.value.aspectRatio > 0 ? vc.value.aspectRatio : 16/9,
                child: Chewie(controller: cc),
              ),
            ));
          }
        },
        child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.fullscreen, color: Colors.white)),
      ),
    ]);
  }

  Widget _collapseInlineButton(int index) {
    return GestureDetector(
      onTap: () async {
        // stop and collapse
        final vc = _videoControllers[index];
        if (vc != null && vc.value.isPlaying) await vc.pause();
        await _disposeInlineVideo(index);
        setState(() => _playingInline.remove(index));
      },
      child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.close, color: Colors.white)),
    );
  }

  Widget _mediaGallery() {
    if (_p.mediaItems.isEmpty) return const SizedBox.shrink();
    if (_p.mediaItems.length == 1) return AspectRatio(aspectRatio: 16/9, child: _buildMediaItem(_p.mediaItems.first, index: 0));

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: _p.mediaItems.length,
            itemBuilder: (_, i) => _buildMediaItem(_p.mediaItems[i], index: i),
          ),
        ),
        const SizedBox(height: 8),
        // thumbnail strip
        SizedBox(
          height: 72,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemCount: _p.mediaItems.length,
            itemBuilder: (_, i) {
              final item = _p.mediaItems[i];
              final thumb = item.thumbnailUrl ?? item.url;
              return GestureDetector(
                onTap: () => _pageController.animateToPage(i, duration: const Duration(milliseconds: 260), curve: Curves.easeOut),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 96,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _page == i ? Colors.blueAccent : Colors.transparent, width: 2),
                    color: Colors.grey.shade200,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: thumb,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const _MediaSkeleton(),
                      errorWidget: (_, __, ___) => const Center(child: Icon(Icons.broken_image)),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _actionRow() {
    return Row(children: [
      // like with animation
      GestureDetector(
        onTap: () => _toggleLike(),
        child: AnimatedBuilder(
          animation: _likeIconCtrl,
          builder: (_, __) {
            final scale = 1.0 + (_likeIconCtrl.value * 0.12);
            return Transform.scale(
              scale: scale,
              child: Icon(_p.likedByMe ? Icons.favorite : Icons.favorite_border, color: _p.likedByMe ? Colors.redAccent : Colors.black87),
            );
          },
        ),
      ),
      const SizedBox(width: 8),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (w, a) => ScaleTransition(scale: a, child: w),
        child: Text('${_p.likeCount}', key: ValueKey<int>(_p.likeCount), style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      const SizedBox(width: 14),
      IconButton(onPressed: () => _openComments(), icon: const Icon(Icons.mode_comment_outlined)),
      Text('${_p.commentCount}', style: const TextStyle(fontWeight: FontWeight.w700)),
      const Spacer(),
      IconButton(onPressed: () => _sharePost(), icon: const Icon(Icons.share_outlined)),
    ]);
  }

  Future<void> _openComments() async {
    // show a bottom sheet with comments preview and composer - stubbed minimal UI
    await showModalBottomSheet(context: context, isScrollControlled: true, builder: (ctx) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (_, controller) => Column(
          children: [
            Container(height: 6, width: 64, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: 4,
                itemBuilder: (_, i) => ListTile(leading: const CircleAvatar(child: Icon(Icons.person)), title: Text('User ${i+1}'), subtitle: const Text('Nice post!')),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Row(children: [
                Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12.0), child: TextField(decoration: const InputDecoration(hintText: 'Write a comment')))),
                IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.send))
              ]),
            )
          ],
        ),
      );
    });
  }

  void _sharePost() {
    // stubbed share behaviour
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Share dialog (stub)')));
  }

  // ---------- Build ----------
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          // soft glass-like background
          gradient: LinearGradient(colors: [Colors.white.withOpacity(0.6), Colors.white.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _avatarHeader(),
            const SizedBox(height: 12),
            // content with read-more
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 24),
              child: AnimatedCrossFade(
                crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 260),
                firstChild: _buildCollapsedText(),
                secondChild: _buildExpandedText(),
              ),
            ),
            if (_p.mediaItems.isNotEmpty) ...[
              const SizedBox(height: 10),
              _mediaGallery(),
            ],
            const SizedBox(height: 12),
            _actionRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsedText() {
    // show up to 3 lines
    final txt = Text(
      _p.content,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 14),
    );
    if (_p.content.length < 220) {
      return txt;
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      txt,
      const SizedBox(height: 8),
      GestureDetector(onTap: () => setState(() => _expanded = true), child: const Text('Read more', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w600))),
    ]);
  }

  Widget _buildExpandedText() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_p.content, style: const TextStyle(fontSize: 14)),
      const SizedBox(height: 8),
      GestureDetector(onTap: () => setState(() => _expanded = false), child: const Text('Show less', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w600))),
    ]);
  }
}

// ---------- Small skeleton widget ----------
class _MediaSkeleton extends StatelessWidget {
  const _MediaSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(child: SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2))),
    );
  }
}
