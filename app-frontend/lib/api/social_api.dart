import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../env.dart';
import '../models/social_post.dart';

/// Social / Creator feed API
class SocialApi {
  static final SocialApi instance = SocialApi._();
  SocialApi._();

  String get _base => EnvConfig.apiBaseUrl;

  Future<SocialCounts> getCounts(int userId) async {
    try {
      final uri = Uri.parse('$_base/api/social/counts').replace(queryParameters: {'userId': userId.toString()});
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json is Map<String,dynamic>) return SocialCounts.fromJson(json);
      }
      // fallback: attempt to infer posts count from feed page metadata if provided
      final feedUri = Uri.parse('$_base/api/feed/posts').replace(queryParameters: {
        'page': '0',
        'size': '1',
        'viewerId': userId.toString(),
      });
      final feedRes = await http.get(feedUri);
      if (feedRes.statusCode == 200) {
        final data = jsonDecode(feedRes.body);
        if (data is Map<String,dynamic>) {
          final total = (data['totalElements'] ?? data['total'] ?? 0) as int;
          return SocialCounts(posts: total, followers: 0, following: 0);
        }
      }
    } catch (_) {}
    return const SocialCounts(posts: 0, followers: 0, following: 0);
  }

  Future<List<SocialPost>> listFeed({
    required int viewerId,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final uri = Uri.parse('$_base/api/feed/posts').replace(queryParameters: {
        'page': (page - 1).toString(),
        'size': pageSize.toString(),
        'viewerId': viewerId.toString(),
      });
      final res = await http.get(uri);
      if (res.statusCode != 200) throw Exception('bad status ${res.statusCode}');
      final data = jsonDecode(res.body) as Map<String,dynamic>;
      final content = (data['content'] as List).cast<Map<String,dynamic>>();
      return content.map(_postFromJson).toList();
    } catch (_) {
      // fallback mock (keeps UI functioning offline)
      final now = DateTime.now();
      return List.generate(pageSize, (i) {
        final id = (page - 1) * pageSize + i + 1;
        return SocialPost(
          id: id,
          authorId: 100 + (id % 4),
          authorName: ['Alex', 'Maya', 'Rohit', 'Sofia'][id % 4],
            authorAvatarUrl: null,
          content: [
            'Shipped a responsive dashboard for a SaaS 👀',
            'Experimenting with a new color system for mobile.',
            'Short demo of the invoicing flow – thoughts?',
            'Sketching wireframes for a travel planner app.'
          ][id % 4],
          createdAt: now.subtract(Duration(minutes: id * 7)),
          likeCount: 4 * (id % 6),
          commentCount: id % 3,
          likedByMe: id % 5 == 0,
          mediaUrls: const [],
          mediaItems: const [],
        );
      });
    }
  }

  Future<SocialPost> createPost({
    required int authorId,
    required String content,
    List<SocialMediaItem> media = const [],
  }) async {
    final body = jsonEncode({
      'authorId': authorId,
      'content': content,
      'media': media.map((m) => m.toJson()).toList(),
    });
    final res = await http.post(Uri.parse('$_base/api/feed/posts'), headers: {'Content-Type':'application/json'}, body: body);
    if (res.statusCode != 200) {
      throw Exception('Failed to create post');
    }
    final json = jsonDecode(res.body) as Map<String,dynamic>;
    return _postFromJson(json);
  }

  Future<void> like(int postId, {required bool like, required int userId}) async {
    final uri = Uri.parse('$_base/api/feed/posts/$postId/like').replace(queryParameters: {'userId': userId.toString()});
    final res = like ? await http.post(uri) : await http.delete(uri);
    if (res.statusCode != 200) throw Exception('Failed like op');
  }

  Future<List<CreatorSuggestion>> suggestions(int userId) async {
    // placeholder
    return const [];
  }

  Future<void> follow(int targetUserId) async {}
  Future<void> unfollow(int targetUserId) async {}

  SocialPost _postFromJson(Map<String,dynamic> j) {
    final media = (j['media'] as List? ?? []).cast<Map<String,dynamic>>().map(SocialMediaItem.fromJson).toList();
    return SocialPost(
      id: j['id'],
      authorId: j['authorId'],
      authorName: j['authorName'] ?? 'User',
      authorAvatarUrl: null,
      content: j['content'] ?? '',
      createdAt: DateTime.parse(j['createdAt']).toLocal(),
      likeCount: (j['likeCount'] ?? 0) as int,
      commentCount: (j['commentCount'] ?? 0) as int,
      likedByMe: j['likedByMe'] ?? false,
      mediaUrls: media.map((m) => m.url).toList(),
      mediaItems: media,
    );
  }
}

// Removed duplicate SocialCounts class (use the one from models/social_post.dart)
