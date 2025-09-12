import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../api/social_api.dart';
import '../models/social_post.dart';
import '../services/media_upload_service.dart';
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
  final List<_LocalMedia> _attachments = [];
  double? _uploadProgress; // 0-1 while uploading

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: [
        'jpg',
        'jpeg',
        'png',
        'gif',
        'webp',
        'mp4',
        'mov',
        'm4v',
        'webm'
      ],
    );
    if (result == null) return;
    for (final f in result.files) {
      if (f.path == null) continue; // skip unsupported (web bytes w/out path)
      final ext = f.extension?.toLowerCase();
      final isVideo = ['mp4', 'mov', 'm4v', 'webm'].contains(ext);
      if (_attachments.length >= 4) break; // simple cap
      _attachments.add(
          _LocalMedia(File(f.path!), isVideo ? 'VIDEO' : 'IMAGE'));
    }
    setState(() {});
  }

  void _removeAttachment(int i) {
    setState(() => _attachments.removeAt(i));
  }

  Future<List<SocialMediaItem>> _uploadAll() async {
    if (_attachments.isEmpty) return [];
    final out = <SocialMediaItem>[];
    for (int i = 0; i < _attachments.length; i++) {
      final itm = _attachments[i];
      setState(() => _uploadProgress = i / _attachments.length);
      final up = await MediaUploadService.instance
          .uploadFile(itm.file, folder: 'feed');
      out.add(SocialMediaItem(url: up.url, mediaType: itm.mediaType));
    }
    setState(() => _uploadProgress = 1);
    return out;
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if ((text.isEmpty && _attachments.isEmpty) || _posting) return;
    setState(() => _posting = true);
    try {
      final me = SessionService.instance.user;
      if (me == null) throw Exception('Not signed in');
      final mediaItems = await _uploadAll();
      await SocialApi.instance
          .createPost(authorId: me.id, content: text, media: mediaItems);
      _controller.clear();
      _attachments.clear();
      _uploadProgress = null;
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

  Widget _attachmentsRow() {
    if (_attachments.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (int i = 0; i < _attachments.length; i++)
          _attachmentThumb(i, _attachments[i]),
      ],
    );
  }

  Widget _attachmentThumb(int i, _LocalMedia m) {
    final icon = m.mediaType == 'VIDEO' ? Icons.videocam : Icons.image;
    return Stack(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: .25)),
            image: m.mediaType == 'IMAGE'
                ? DecorationImage(image: FileImage(m.file), fit: BoxFit.cover)
                : null,
            color: m.mediaType == 'VIDEO' ? Colors.black12 : null,
          ),
          alignment: Alignment.center,
          child: m.mediaType == 'VIDEO' ? Icon(icon, color: Colors.white70) : null,
        ),
        Positioned(
          right: -6,
          top: -6,
          child: IconButton(
            style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
                padding: EdgeInsets.zero,
                minimumSize: const Size(28, 28)),
            icon: const Icon(Icons.close, size: 16, color: Colors.white),
            onPressed: () => _removeAttachment(i),
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
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
                IconButton(
                    onPressed: _posting ? null : _pickFiles,
                    icon: const Icon(Icons.attach_file)),
                FilledButton(
                  onPressed: _posting ? null : _submit,
                  child: _posting
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, value: _uploadProgress),
                        )
                      : const Text('Post'),
                ),
              ],
            ),
            if (_attachments.isNotEmpty) ...[
              const SizedBox(height: 8),
              _attachmentsRow(),
            ]
          ],
        ),
      ),
    );
  }
}

class _LocalMedia {
  final File file;
  final String mediaType; // IMAGE or VIDEO
  _LocalMedia(this.file, this.mediaType);
}
