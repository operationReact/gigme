import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/social_post.dart';
import '../api/social_api.dart';
import '../services/session_service.dart';

class SocialPostCard extends StatefulWidget {
  final SocialPost post;
  const SocialPostCard({super.key, required this.post});

  @override
  State<SocialPostCard> createState() => _SocialPostCardState();
}

class _SocialPostCardState extends State<SocialPostCard> {
  late SocialPost _p = widget.post;
  final PageController _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _isSample => _p.id < 0; // injected demo content

  Widget _mediaGallery() {
    if (_p.mediaItems.isEmpty) return const SizedBox.shrink();
    if (_p.mediaItems.length == 1) {
      final m = _p.mediaItems.first;
      return _buildMediaItem(m, index: 0);
    }
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16/9,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (i)=> setState(()=> _page = i),
            itemCount: _p.mediaItems.length,
            itemBuilder: (_, i) => _buildMediaItem(_p.mediaItems[i], index: i),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < _p.mediaItems.length; i++) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _page == i ? 14 : 6,
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: (_page == i ? Colors.blueAccent : Colors.blueAccent.withValues(alpha: .30)),
                ),
              )
            ]
          ],
        )
      ],
    );
  }

  Future<void> _playVideo(SocialMediaItem m) async {
    try {
      final vc = VideoPlayerController.networkUrl(Uri.parse(m.url));
      await vc.initialize();
      final cc = ChewieController(videoPlayerController: vc, autoPlay: true, looping: false);
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: .85),
        builder: (_) => Dialog(
          backgroundColor: Colors.black,
            insetPadding: const EdgeInsets.all(12),
            child: AspectRatio(
              aspectRatio: vc.value.aspectRatio == 0 ? 16/9 : vc.value.aspectRatio,
              child: Chewie(controller: cc),
            )),
      );
      // Pause & dispose controllers safely
      if (vc.value.isPlaying) { await vc.pause(); }
      await vc.dispose();
      cc.dispose();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Video failed to load')));
      }
    }
  }

  Widget _buildMediaItem(SocialMediaItem m, {required int index}) {
    if (m.isVideo) {
      return GestureDetector(
        onTap: () => _playVideo(m),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: m.thumbnailUrl != null
                    ? Image.network(m.thumbnailUrl!, fit: BoxFit.cover)
                    : const Center(
                        child: Icon(Icons.videocam, size: 42),
                      )),
            Positioned.fill(
              child: Container(
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            )
          ],
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: (m.width != null && m.height != null && m.height! > 0)
            ? (m.width! / m.height!)
            : 16 / 9,
        child: Image.network(m.url, fit: BoxFit.cover),
      ),
    );
  }

  Future<void> _toggleLike() async {
    final like = !_p.likedByMe;
    setState(() {
      _p = _p.copyWith(
        likedByMe: like,
        likeCount: like ? _p.likeCount + 1 : (_p.likeCount - 1).clamp(0, 1 << 31),
      );
    });
    int? userId = SessionService.instance.user?.id; // safe retrieval
    if (userId != null) {
      try { await SocialApi.instance.like(_p.id, like: like, userId: userId); } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionUserId = SessionService.instance.user?.id;
    final isMine = sessionUserId != null && sessionUserId == _p.authorId;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  child: _p.authorAvatarUrl == null
                      ? const Icon(Icons.person)
                      : ClipOval(
                          child: Image.network(
                            _p.authorAvatarUrl!,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(_p.authorName,
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                          if (isMine) ...[
                            const SizedBox(width: 6),
                            _MiniTag(label: 'You'),
                          ],
                          if (_isSample) ...[
                            const SizedBox(width: 6),
                            _MiniTag(label: 'Sample', color: Colors.deepPurple),
                          ]
                        ],
                      ),
                      Text(
                        _timeAgo(_p.createdAt),
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 10),
            // content
            Text(_p.content),
            if (_p.mediaItems.isNotEmpty) ...[
              const SizedBox(height: 10),
              _mediaGallery(),
            ],
            const SizedBox(height: 10),
            // actions
            Row(
              children: [
                IconButton(
                  onPressed: _toggleLike,
                  icon: Icon(
                    _p.likedByMe ? Icons.favorite : Icons.favorite_border,
                    color: _p.likedByMe ? Colors.redAccent : null,
                  ),
                ),
                Text('${_p.likeCount}', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.mode_comment_outlined),
                ),
                Text('${_p.commentCount}', style: const TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.share_outlined)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String label;
  final Color? color;
  const _MiniTag({required this.label, this.color});
  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.blueAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.withValues(alpha: .5)),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c)),
    );
  }
}

String _timeAgo(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'now';
  if (d.inMinutes < 60) return '${d.inMinutes}m';
  if (d.inHours < 24) return '${d.inHours}h';
  return '${d.inDays}d';
}
