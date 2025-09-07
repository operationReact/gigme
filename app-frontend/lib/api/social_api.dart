import 'dart:async';
import '../models/social_post.dart';

/// Replace these later with real HTTP calls to your backend.
/// For now they return mock data so your UI compiles & works.
class SocialApi {
  static final SocialApi instance = SocialApi._();
  SocialApi._();

  Future<SocialCounts> getCounts(int userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const SocialCounts(posts: 12, followers: 87, following: 44);
  }

  Future<List<SocialPost>> listFeed({
    required int viewerId,
    int page = 1,
    int pageSize = 10,
  }) async {
    await Future.delayed(const Duration(milliseconds: 350));
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
        mediaUrls: id % 2 == 0 ? [] : [],
      );
    });
  }

  Future<SocialPost> createPost({
    required int authorId,
    required String content,
    List<String> mediaUrls = const [],
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return SocialPost(
      id: DateTime.now().millisecondsSinceEpoch,
      authorId: authorId,
      authorName: 'You',
      authorAvatarUrl: null,
      content: content,
      createdAt: DateTime.now(),
      likeCount: 0,
      commentCount: 0,
      likedByMe: false,
      mediaUrls: mediaUrls,
    );
  }

  Future<void> like(int postId, {required bool like}) async {
    await Future.delayed(const Duration(milliseconds: 120));
  }

  Future<List<CreatorSuggestion>> suggestions(int userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const [
      CreatorSuggestion(userId: 301, name: 'Amara Khan', title: 'Product Designer', avatarUrl: null, followedByMe: false),
      CreatorSuggestion(userId: 302, name: 'Chris Tan', title: 'Mobile Dev', avatarUrl: null, followedByMe: false),
      CreatorSuggestion(userId: 303, name: 'Elena G', title: 'Full-stack', avatarUrl: null, followedByMe: true),
    ];
  }

  Future<void> follow(int targetUserId) async {
    await Future.delayed(const Duration(milliseconds: 120));
  }

  Future<void> unfollow(int targetUserId) async {
    await Future.delayed(const Duration(milliseconds: 120));
  }
}
