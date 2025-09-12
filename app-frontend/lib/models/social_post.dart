class SocialMediaItem {
  final String url;
  final String mediaType; // IMAGE or VIDEO
  final int? width;
  final int? height;
  final int? durationSeconds;
  final String? thumbnailUrl;
  const SocialMediaItem({
    required this.url,
    required this.mediaType,
    this.width,
    this.height,
    this.durationSeconds,
    this.thumbnailUrl,
  });
  factory SocialMediaItem.fromJson(Map<String,dynamic> j) => SocialMediaItem(
    url: j['url'],
    mediaType: j['mediaType'],
    width: j['width'],
    height: j['height'],
    durationSeconds: j['durationSeconds'],
    thumbnailUrl: j['thumbnailUrl'],
  );
  Map<String,dynamic> toJson()=>{
    'url':url,
    'mediaType':mediaType,
    'width':width,
    'height':height,
    'durationSeconds':durationSeconds,
    'thumbnailUrl':thumbnailUrl,
  };
  bool get isVideo => mediaType == 'VIDEO';
}

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
  final List<SocialMediaItem> mediaItems;

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
    required this.mediaItems,
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
      mediaItems: mediaItems,
    );
  }
}

class SocialCounts {
  final int posts;
  final int followers;
  final int following;
  const SocialCounts({required this.posts, required this.followers, required this.following});
  factory SocialCounts.fromJson(Map<String,dynamic> j)=> SocialCounts(
    posts: (j['posts'] ?? 0) as int,
    followers: (j['followers'] ?? 0) as int,
    following: (j['following'] ?? 0) as int,
  );
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
