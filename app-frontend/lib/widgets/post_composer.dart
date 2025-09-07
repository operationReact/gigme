import 'package:flutter/material.dart';
import '../api/social_api.dart';
import '../services/session_service.dart';

class PostComposer extends StatefulWidget {
  final VoidCallback? onCreated;
  const PostComposer({super.key, this.onCreated});

  @override
  State<PostComposer> createState() => _PostComposerState();
}

class _PostComposerState extends State<PostComposer> {
  final _controller = TextEditingController();
  bool _posting = false;

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _posting) return;
    setState(() => _posting = true);
    try {
      final me = SessionService.instance.user;
      if (me == null) throw Exception('Not signed in');
      await SocialApi.instance.createPost(authorId: me.id, content: text);
      _controller.clear();
      widget.onCreated?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Posted')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to post')),
        );
      }
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const CircleAvatar(radius: 16, child: Icon(Icons.person)),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: "Share an update…",
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _posting ? null : _submit,
              child: _posting ? const SizedBox(
                width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2),
              ) : const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }
}
