enum ReportTargetType {
  user,
  post;

  String get apiValue => name;

  String get label => switch (this) {
    ReportTargetType.user => 'Kullanıcı',
    ReportTargetType.post => 'Gönderi',
  };

  static ReportTargetType fromApi(String value) {
    return ReportTargetType.values.firstWhere(
      (item) => item.apiValue == value,
      orElse: () => throw FormatException('Geçersiz targetType: $value'),
    );
  }
}

enum ReportReason {
  spam,
  harassment,
  hateSpeech,
  violence,
  sexualContent,
  fakeAccount,
  other;

  String get apiValue => name;

  String get label => switch (this) {
    ReportReason.spam => 'Spam',
    ReportReason.harassment => 'Taciz',
    ReportReason.hateSpeech => 'Nefret söylemi',
    ReportReason.violence => 'Şiddet',
    ReportReason.sexualContent => 'Cinsel içerik',
    ReportReason.fakeAccount => 'Sahte hesap',
    ReportReason.other => 'Diğer',
  };

  static ReportReason fromApi(String value) {
    return ReportReason.values.firstWhere(
      (item) => item.apiValue == value,
      orElse: () => throw FormatException('Geçersiz reason: $value'),
    );
  }
}

enum ModerationStatus {
  pending,
  resolved,
  dismissed;

  String get apiValue => name;

  String get label => switch (this) {
    ModerationStatus.pending => 'Bekliyor',
    ModerationStatus.resolved => 'Çözüldü',
    ModerationStatus.dismissed => 'Reddedildi',
  };

  static ModerationStatus fromApi(String value) {
    return ModerationStatus.values.firstWhere(
      (item) => item.apiValue == value,
      orElse: () => throw FormatException('Geçersiz status: $value'),
    );
  }
}

enum ModerationAction {
  noAction,
  removePost;

  String get apiValue => name;

  String get label => switch (this) {
    ModerationAction.noAction => 'İşlem yapma',
    ModerationAction.removePost => 'Gönderiyi kaldır',
  };

  static ModerationAction fromApi(String value) {
    return ModerationAction.values.firstWhere(
      (item) => item.apiValue == value,
      orElse: () => throw FormatException('Geçersiz action: $value'),
    );
  }
}

class CreateReportRequest {
  const CreateReportRequest({
    required this.targetType,
    required this.targetId,
    required this.reason,
    this.details,
  });

  final ReportTargetType targetType;
  final int targetId;
  final ReportReason reason;
  final String? details;

  Map<String, dynamic> toJson() {
    final normalizedDetails = details?.trim();

    return <String, dynamic>{
      'targetType': targetType.apiValue,
      'targetId': targetId,
      'reason': reason.apiValue,
      'details': normalizedDetails == null || normalizedDetails.isEmpty
          ? null
          : normalizedDetails,
    };
  }
}

class ResolveReportRequest {
  const ResolveReportRequest({required this.action, this.note});

  final ModerationAction action;
  final String? note;

  Map<String, dynamic> toJson() {
    final normalizedNote = note?.trim();

    return <String, dynamic>{
      'action': action.apiValue,
      'note': normalizedNote == null || normalizedNote.isEmpty
          ? null
          : normalizedNote,
    };
  }
}

class BlockResult {
  const BlockResult({
    required this.id,
    required this.username,
    required this.isBlocked,
  });

  final int id;
  final String username;
  final bool isBlocked;

  factory BlockResult.fromJson(Map<String, dynamic> json) {
    return BlockResult(
      id: json['id'] as int,
      username: json['username'] as String,
      isBlocked: json['isBlocked'] as bool,
    );
  }
}

class BlockedUser {
  const BlockedUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.blockedAt,
    this.avatarUrl,
  });

  final int id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final DateTime blockedAt;

  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    return BlockedUser(
      id: json['id'] as int,
      username: json['username'] as String,
      displayName: json['displayName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      blockedAt: DateTime.parse(json['blockedAt'] as String).toUtc(),
    );
  }
}

class ReportRecord {
  const ReportRecord({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.details,
    this.reporterUserId,
    this.reporterUsername,
    this.reviewedAt,
    this.reviewedByUserId,
  });

  final int id;
  final int? reporterUserId;
  final String? reporterUsername;
  final ReportTargetType targetType;
  final int targetId;
  final ReportReason reason;
  final String? details;
  final ModerationStatus status;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final int? reviewedByUserId;

  factory ReportRecord.fromJson(Map<String, dynamic> json) {
    final reviewedAt = json['reviewedAt'] as String?;

    return ReportRecord(
      id: json['id'] as int,
      reporterUserId: json['reporterUserId'] as int?,
      reporterUsername: json['reporterUsername'] as String?,
      targetType: ReportTargetType.fromApi(json['targetType'] as String),
      targetId: json['targetId'] as int,
      reason: ReportReason.fromApi(json['reason'] as String),
      details: json['details'] as String?,
      status: ModerationStatus.fromApi(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
      reviewedAt: reviewedAt == null
          ? null
          : DateTime.parse(reviewedAt).toUtc(),
      reviewedByUserId: json['reviewedByUserId'] as int?,
    );
  }
}

class ResolveReportResult {
  const ResolveReportResult({
    required this.id,
    required this.status,
    required this.action,
    this.resolvedAt,
    this.resolvedByUserId,
  });

  final int id;
  final ModerationStatus status;
  final ModerationAction action;
  final DateTime? resolvedAt;
  final int? resolvedByUserId;

  factory ResolveReportResult.fromJson(Map<String, dynamic> json) {
    final resolvedAt = json['resolvedAt'] as String?;

    return ResolveReportResult(
      id: json['id'] as int,
      status: ModerationStatus.fromApi(json['status'] as String),
      action: ModerationAction.fromApi(json['action'] as String),
      resolvedAt: resolvedAt == null
          ? null
          : DateTime.parse(resolvedAt).toUtc(),
      resolvedByUserId: json['resolvedByUserId'] as int?,
    );
  }
}
