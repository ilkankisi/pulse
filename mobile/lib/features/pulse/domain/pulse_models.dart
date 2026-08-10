class PulseAuthor {
  const PulseAuthor({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
  });

  final int id;
  final String username;
  final String displayName;
  final String? avatarUrl;

  factory PulseAuthor.fromJson(Map<String, dynamic> json) {
    return PulseAuthor(
      id: _requiredInt(json, const ['id', 'userId']),
      username: _requiredString(json, const ['username', 'userName']),
      displayName: _requiredString(json, const ['displayName', 'name']),
      avatarUrl: _optionalString(json['avatarUrl']),
    );
  }
}

class PulsePost {
  const PulsePost({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.author,
    required this.likeCount,
    required this.replyCount,
    required this.isLiked,
    required this.canDelete,
    this.replyToPostId,
  });

  final int id;
  final String content;
  final DateTime createdAt;
  final PulseAuthor author;
  final int likeCount;
  final int replyCount;
  final bool isLiked;
  final bool canDelete;
  final int? replyToPostId;

  factory PulsePost.fromJson(Map<String, dynamic> json) {
    final authorValue = json['author'] ?? json['user'];
    if (authorValue is! Map) {
      throw const FormatException('Gönderi yazarı bulunamadı.');
    }

    return PulsePost(
      id: _requiredInt(json, const ['id', 'postId']),
      content: _requiredString(json, const ['content', 'text']),
      createdAt: _requiredDateTime(json, const [
        'createdAt',
        'publishedAt',
        'date',
      ]),
      author: PulseAuthor.fromJson(Map<String, dynamic>.from(authorValue)),
      likeCount: _optionalInt(json, const ['likeCount', 'likesCount']),
      replyCount: _optionalInt(json, const ['replyCount', 'repliesCount']),
      isLiked: _optionalBool(json, const [
        'isLikedByMe',
        'isLiked',
        'likedByCurrentUser',
      ]),
      canDelete: _optionalBool(json, const [
        'canDelete',
        'isOwnedByCurrentUser',
        'isMine',
      ]),
      replyToPostId: _nullableInt(json, const [
        'replyToPostId',
        'parentPostId',
      ]),
    );
  }

  PulsePost copyWith({int? likeCount, int? replyCount, bool? isLiked}) {
    return PulsePost(
      id: id,
      content: content,
      createdAt: createdAt,
      author: author,
      likeCount: likeCount ?? this.likeCount,
      replyCount: replyCount ?? this.replyCount,
      isLiked: isLiked ?? this.isLiked,
      canDelete: canDelete,
      replyToPostId: replyToPostId,
    );
  }
}

class PulseFeed {
  const PulseFeed({required this.posts});

  final List<PulsePost> posts;

  factory PulseFeed.fromJson(dynamic data) {
    dynamic items = data;

    if (data is Map) {
      final json = Map<String, dynamic>.from(data);
      items = json['items'] ?? json['posts'] ?? json['data'];
    }

    if (items is! List) {
      throw const FormatException('Akış yanıtı geçerli değil.');
    }

    final posts = <PulsePost>[];
    for (final item in items) {
      if (item is! Map) {
        throw const FormatException('Gönderi verisi geçerli değil.');
      }

      posts.add(PulsePost.fromJson(Map<String, dynamic>.from(item)));
    }

    return PulseFeed(posts: List<PulsePost>.unmodifiable(posts));
  }
}

class PulseProfile {
  const PulseProfile({
    required this.id,
    required this.username,
    required this.displayName,
    required this.followerCount,
    required this.followingCount,
    required this.postCount,
    required this.isFollowing,
    required this.isCurrentUser,
    this.bio,
    this.avatarUrl,
  });

  final int id;
  final String username;
  final String displayName;
  final String? bio;
  final String? avatarUrl;
  final int followerCount;
  final int followingCount;
  final int postCount;
  final bool isFollowing;
  final bool isCurrentUser;

  factory PulseProfile.fromJson(Map<String, dynamic> json) {
    return PulseProfile(
      id: _requiredInt(json, const ['id', 'userId']),
      username: _requiredString(json, const ['username', 'userName']),
      displayName: _requiredString(json, const ['displayName', 'name']),
      bio: _optionalString(json['bio']),
      avatarUrl: _optionalString(json['avatarUrl']),
      followerCount: _optionalInt(json, const [
        'followerCount',
        'followersCount',
      ]),
      followingCount: _optionalInt(json, const ['followingCount']),
      postCount: _optionalInt(json, const ['postCount', 'postsCount']),
      isFollowing: _optionalBool(json, const [
        'isFollowing',
        'followedByCurrentUser',
      ]),
      isCurrentUser: _optionalBool(json, const ['isCurrentUser', 'isMe']),
    );
  }

  PulseProfile copyWith({
    String? displayName,
    String? bio,
    String? avatarUrl,
    int? followerCount,
    bool? isFollowing,
  }) {
    return PulseProfile(
      id: id,
      username: username,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount,
      postCount: postCount,
      isFollowing: isFollowing ?? this.isFollowing,
      isCurrentUser: isCurrentUser,
    );
  }
}

class CreatePostRequest {
  const CreatePostRequest({required this.content});

  final String content;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'content': content.trim()};
  }
}

class CreateReplyRequest {
  const CreateReplyRequest({required this.content});

  final String content;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'content': content.trim()};
  }
}

class UpdateProfileRequest {
  const UpdateProfileRequest({
    required this.displayName,
    required this.bio,
    required this.avatarUrl,
  });

  final String displayName;
  final String bio;
  final String avatarUrl;

  Map<String, dynamic> toJson() {
    final trimmedBio = bio.trim();
    final trimmedAvatarUrl = avatarUrl.trim();

    final json = <String, dynamic>{
      'displayName': displayName.trim(),
      'bio': trimmedBio.isEmpty ? null : trimmedBio,
    };

    if (trimmedAvatarUrl.isNotEmpty) {
      json['avatarUrl'] = trimmedAvatarUrl;
    }

    return json;
  }
}

String _requiredString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
  }

  throw FormatException('Zorunlu metin alanı bulunamadı: ${keys.join(', ')}');
}

int _requiredInt(Map<String, dynamic> json, List<String> keys) {
  final value = _nullableInt(json, keys);
  if (value == null) {
    throw FormatException(
      'Zorunlu sayısal alan bulunamadı: ${keys.join(', ')}',
    );
  }

  return value;
}

int _optionalInt(Map<String, dynamic> json, List<String> keys) {
  return _nullableInt(json, keys) ?? 0;
}

int? _nullableInt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
  }

  return null;
}

bool _optionalBool(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is bool) {
      return value;
    }
  }

  return false;
}

DateTime _requiredDateTime(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
  }

  throw FormatException('Geçerli tarih alanı bulunamadı: ${keys.join(', ')}');
}

String? _optionalString(dynamic value) {
  if (value is! String) {
    return null;
  }

  final trimmedValue = value.trim();
  return trimmedValue.isEmpty ? null : trimmedValue;
}
