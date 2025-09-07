import 'package:flutter/material.dart';
import '../models/social_post.dart';
import '../api/social_api.dart';

class SocialPostCard extends StatefulWidget {
  final SocialPost post;
  const SocialPostCard({super.key, required this.post});

  @override
  State<SocialPostCard> createState() => _SocialPostCardState();
}

class _SocialPostCardState extends State<SocialPostCard> {
  late SocialPost _p = widget.post;

  Future<void> _toggleLike() async {
    final like = !_p.likedByMe;
    setState(() {
      _p = _p.copyWith(
        likedByMe: like,
        likeCount: like ? _p.likeCount + 1 : (_p.likeCount - 1).clamp(0, 1 << 31),
      );
    });
    await SocialApi.instance.like(_p.id, like: like);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // header
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  child: _p.authorAvatarUrl == null
                      ? const Icon(Icons.person)
                      : ClipOval(child: Image.network(_p.authorAvatarUrl!, fit: BoxFit.cover)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_p.authorName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        _timeAgo(_p.createdAt),
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
            const SizedBox(height: 8),
            // content
            Text(_p.content),
            if (_p.mediaUrls.isNotEmpty) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(_p.mediaUrls.first, fit: BoxFit.cover),
                ),
              ),
            ],
            const SizedBox(height: 8),
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
                Text('${_p.likeCount}'),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.mode_comment_outlined),
                ),
                Text('${_p.commentCount}'),
                const Spacer(),
                IconButton(onPressed: () {}, icon: const Icon(Icons.share_outlined)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    return '${d.inDays}d';
  }
}
