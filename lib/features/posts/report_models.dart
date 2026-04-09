import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportReason {
  spam,
  abuse,
  misinformation,
  hateful,
  nsfw,
  irrelevant,
  other,
}

extension ReportReasonExtension on ReportReason {
  String get displayName {
    switch (this) {
      case ReportReason.spam:
        return 'Spam';
      case ReportReason.abuse:
        return 'Abuse';
      case ReportReason.misinformation:
        return 'Misinformation';
      case ReportReason.hateful:
        return 'Hateful Content';
      case ReportReason.nsfw:
        return 'NSFW Content';
      case ReportReason.irrelevant:
        return 'Irrelevant';
      case ReportReason.other:
        return 'Other';
    }
  }

  String get description {
    switch (this) {
      case ReportReason.spam:
        return 'Repetitive or promotional content';
      case ReportReason.abuse:
        return 'Harassment or bullying';
      case ReportReason.misinformation:
        return 'False or misleading information';
      case ReportReason.hateful:
        return 'Hateful or discriminatory content';
      case ReportReason.nsfw:
        return 'Sexually explicit or graphic content';
      case ReportReason.irrelevant:
        return 'Not related to the location';
      case ReportReason.other:
        return 'Something else';
    }
  }
}

class PostReport {
  final String id;
  final String postId;
  final String postOwnerId;
  final String reportedBy;
  final ReportReason reason;
  final String message;
  final DateTime reportedAt;
  final String status; // pending, reviewing, resolved, dismissed

  PostReport({
    required this.id,
    required this.postId,
    required this.postOwnerId,
    required this.reportedBy,
    required this.reason,
    required this.message,
    required this.reportedAt,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'postId': postId,
    'postOwnerId': postOwnerId,
    'reportedBy': reportedBy,
    'reason': reason.toString().split('.').last,
    'message': message,
    'reportedAt': reportedAt,
    'status': status,
  };

  factory PostReport.fromMap(Map<String, dynamic> map, String docId) {
    return PostReport(
      id: docId,
      postId: map['postId'] ?? '',
      postOwnerId: map['postOwnerId'] ?? '',
      reportedBy: map['reportedBy'] ?? '',
      reason: _parseReportReason(map['reason']),
      message: map['message'] ?? '',
      reportedAt: (map['reportedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'pending',
    );
  }

  static ReportReason _parseReportReason(String? reasonStr) {
    switch (reasonStr) {
      case 'spam':
        return ReportReason.spam;
      case 'abuse':
        return ReportReason.abuse;
      case 'misinformation':
        return ReportReason.misinformation;
      case 'hateful':
        return ReportReason.hateful;
      case 'nsfw':
        return ReportReason.nsfw;
      case 'irrelevant':
        return ReportReason.irrelevant;
      case 'other':
        return ReportReason.other;
      default:
        return ReportReason.other;
    }
  }
}

// Appeal models
enum AppealStatus {
  pending,
  approved,
  rejected,
}

extension AppealStatusExtension on AppealStatus {
  String get displayName {
    switch (this) {
      case AppealStatus.pending:
        return 'Pending Review';
      case AppealStatus.approved:
        return 'Approved';
      case AppealStatus.rejected:
        return 'Rejected';
    }
  }
}

class PostAppeal {
  final String id;
  final String postId;
  final String userId;
  final String appealReason;
  final DateTime appealedAt;
  final AppealStatus status;
  final String? rejectionReason;
  final DateTime? reviewedAt;

  PostAppeal({
    required this.id,
    required this.postId,
    required this.userId,
    required this.appealReason,
    required this.appealedAt,
    this.status = AppealStatus.pending,
    this.rejectionReason,
    this.reviewedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'postId': postId,
    'userId': userId,
    'appealReason': appealReason,
    'appealedAt': appealedAt,
    'status': status.toString().split('.').last,
    'rejectionReason': rejectionReason,
    'reviewedAt': reviewedAt,
  };

  factory PostAppeal.fromMap(Map<String, dynamic> map, String docId) {
    return PostAppeal(
      id: docId,
      postId: map['postId'] ?? '',
      userId: map['userId'] ?? '',
      appealReason: map['appealReason'] ?? '',
      appealedAt: (map['appealedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: _parseAppealStatus(map['status']),
      rejectionReason: map['rejectionReason'],
      reviewedAt: (map['reviewedAt'] as Timestamp?)?.toDate(),
    );
  }

  static AppealStatus _parseAppealStatus(String? statusStr) {
    switch (statusStr) {
      case 'pending':
        return AppealStatus.pending;
      case 'approved':
        return AppealStatus.approved;
      case 'rejected':
        return AppealStatus.rejected;
      default:
        return AppealStatus.pending;
    }
  }
}

// Reputation models
enum UserBadge {
  none,
  newUser,
  trusted,
  flagged,
  communityHelper,
}

extension UserBadgeExtension on UserBadge {
  String get displayName {
    switch (this) {
      case UserBadge.newUser:
        return 'New User';
      case UserBadge.trusted:
        return 'Trusted';
      case UserBadge.flagged:
        return 'Flagged';
      case UserBadge.communityHelper:
        return 'Community Helper';
      case UserBadge.none:
        return '';
    }
  }

  String get emoji {
    switch (this) {
      case UserBadge.newUser:
        return '✨';
      case UserBadge.trusted:
        return '✓';
      case UserBadge.flagged:
        return '⚠️';
      case UserBadge.communityHelper:
        return '🤝';
      case UserBadge.none:
        return '';
    }
  }

  String get description {
    switch (this) {
      case UserBadge.newUser:
        return 'Account less than 30 days old';
      case UserBadge.trusted:
        return 'Consistently high-quality contributions';
      case UserBadge.flagged:
        return 'Multiple posts removed or reports';
      case UserBadge.communityHelper:
        return 'Helpful reports and appeals';
      case UserBadge.none:
        return '';
    }
  }
}

class UserReputation {
  final String userId;
  final int score;
  final List<UserBadge> badges;
  final int postsRemoved;
  final int appealsSubmitted;
  final int appealsApproved;
  final int warningCount;
  final bool isSuspended;
  final bool isBanned;
  final DateTime? suspendedUntil;
  final DateTime createdAt;

  UserReputation({
    required this.userId,
    this.score = 0,
    this.badges = const [],
    this.postsRemoved = 0,
    this.appealsSubmitted = 0,
    this.appealsApproved = 0,
    this.warningCount = 0,
    this.isSuspended = false,
    this.isBanned = false,
    this.suspendedUntil,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'score': score,
    'badges': badges.map((b) => b.toString().split('.').last).toList(),
    'postsRemoved': postsRemoved,
    'appealsSubmitted': appealsSubmitted,
    'appealsApproved': appealsApproved,
    'warningCount': warningCount,
    'isSuspended': isSuspended,
    'isBanned': isBanned,
    'suspendedUntil': suspendedUntil,
    'createdAt': createdAt,
  };

  factory UserReputation.fromMap(Map<String, dynamic> map) {
    final badgeStrings = List<String>.from(map['badges'] ?? []);
    final badges = badgeStrings
        .map((b) => _parseBadge(b))
        .where((b) => b != UserBadge.none)
        .toList();

    return UserReputation(
      userId: map['userId'] ?? '',
      score: map['score'] ?? 0,
      badges: badges,
      postsRemoved: map['postsRemoved'] ?? 0,
      appealsSubmitted: map['appealsSubmitted'] ?? 0,
      appealsApproved: map['appealsApproved'] ?? 0,
      warningCount: map['warningCount'] ?? 0,
      isSuspended: map['isSuspended'] ?? false,
      isBanned: map['isBanned'] ?? false,
      suspendedUntil: (map['suspendedUntil'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static UserBadge _parseBadge(String badgeStr) {
    switch (badgeStr) {
      case 'newUser':
        return UserBadge.newUser;
      case 'trusted':
        return UserBadge.trusted;
      case 'flagged':
        return UserBadge.flagged;
      case 'communityHelper':
        return UserBadge.communityHelper;
      default:
        return UserBadge.none;
    }
  }

  String get badgeDisplay {
    if (badges.isEmpty) return '';
    return badges.map((b) => '${b.emoji} ${b.displayName}').join(' ');
  }

  bool get isNewUser => badges.contains(UserBadge.newUser);
  bool get isTrusted => badges.contains(UserBadge.trusted);
  bool get isFlagged => badges.contains(UserBadge.flagged);
  bool get isCommunityHelper => badges.contains(UserBadge.communityHelper);
}
