import 'package:flutter/foundation.dart';

class SocialPost {
  final int id;
  final int authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String content;
  final DateTime createdAt;
  final int likeCount;
  final int commentCount;
  final bool likedByMe;
  final List<String> mediaUrls;

  const SocialPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.content,
    required this.createdAt,
    required this.likeCount,
    required this.commentCount,
    required this.likedByMe,
    required this.mediaUrls,
  });

  SocialPost copyWith({
    int? likeCount,
    bool? likedByMe,
  }) {
    return SocialPost(
      id: id,
      authorId: authorId,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      content: content,
      createdAt: createdAt,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount,
      likedByMe: likedByMe ?? this.likedByMe,
      mediaUrls: mediaUrls,
    );
  }
}

class SocialCounts {
  final int posts;
  final int followers;
  final int following;
  const SocialCounts({required this.posts, required this.followers, required this.following});
}

class CreatorSuggestion {
  final int userId;
  final String name;
  final String title;
  final String? avatarUrl;
  final bool followedByMe;
  const CreatorSuggestion({
    required this.userId,
    required this.name,
    required this.title,
    required this.avatarUrl,
    required this.followedByMe,
  });
}
