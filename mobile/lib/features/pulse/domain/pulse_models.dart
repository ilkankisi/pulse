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
        'isLikedByCurrentUser',
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
      followingCount: _optionalInt(json, const [
        'followingCount',
        'followingsCount',
      ]),
      postCount: _optionalInt(json, const ['postCount', 'postsCount']),
      isFollowing: _optionalBool(json, const [
        'isFollowing',
        'isFollowedByMe',
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
    int? followingCount,
    int? postCount,
    bool? isFollowing,
    bool? isCurrentUser,
  }) {
    return PulseProfile(
      id: id,
      username: username,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
      postCount: postCount ?? this.postCount,
      isFollowing: isFollowing ?? this.isFollowing,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
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
    this.bio,
    this.avatarUrl,
  });

  final String displayName;
  final String? bio;
  final String? avatarUrl;

  Map<String, dynamic> toJson() {
    final trimmedBio = bio?.trim();
    final trimmedAvatarUrl = avatarUrl?.trim();

    // api-contract.md: avatarUrl alanı zorunludur, boş değer null gönderilir.
    return <String, dynamic>{
      'displayName': displayName.trim(),
      'bio': trimmedBio,
      'avatarUrl': trimmedAvatarUrl == null || trimmedAvatarUrl.isEmpty
          ? null
          : trimmedAvatarUrl,
    };
  }
}

dynamic _firstValue(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (json.containsKey(key)) {
      return json[key];
    }
  }

  return null;
}

int _requiredInt(Map<String, dynamic> json, List<String> keys) {
  final value = _firstValue(json, keys);

  if (value is int) {
    return value;
  }

  if (value is num && value.isFinite && value == value.roundToDouble()) {
    return value.toInt();
  }

  throw FormatException('Zorunlu integer alanı bulunamadı: ${keys.first}.');
}

String _requiredString(Map<String, dynamic> json, List<String> keys) {
  final value = _firstValue(json, keys);

  if (value is String && value.isNotEmpty) {
    return value;
  }

  throw FormatException('Zorunlu string alanı bulunamadı: ${keys.first}.');
}

DateTime _requiredDateTime(Map<String, dynamic> json, List<String> keys) {
  final value = _firstValue(json, keys);

  if (value is String) {
    final parsed = DateTime.tryParse(value);

    if (parsed != null) {
      return parsed;
    }
  }

  throw FormatException('Zorunlu tarih alanı bulunamadı: ${keys.first}.');
}

int _optionalInt(Map<String, dynamic> json, List<String> keys) {
  final value = _firstValue(json, keys);

  if (value == null) {
    return 0;
  }

  if (value is int) {
    return value;
  }

  if (value is num && value.isFinite && value == value.roundToDouble()) {
    return value.toInt();
  }

  throw FormatException('Integer alanı geçerli değil: ${keys.first}.');
}

int? _nullableInt(Map<String, dynamic> json, List<String> keys) {
  final value = _firstValue(json, keys);

  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  if (value is num && value.isFinite && value == value.roundToDouble()) {
    return value.toInt();
  }

  throw FormatException('Nullable integer alanı geçerli değil: ${keys.first}.');
}

bool _optionalBool(Map<String, dynamic> json, List<String> keys) {
  final value = _firstValue(json, keys);

  if (value == null) {
    return false;
  }

  if (value is bool) {
    return value;
  }

  throw FormatException('Boolean alanı geçerli değil: ${keys.first}.');
}

String? _optionalString(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is String) {
    return value;
  }

  throw const FormatException('String alanı geçerli değil.');
}
