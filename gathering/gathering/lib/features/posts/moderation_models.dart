import 'package:cloud_firestore/cloud_firestore.dart';

/// dislike/moderation action on a post
class PostDislike {
  final String userId;
  final String postId;
  final DateTime dislikedAt;
  final String? reason; // optional reason for dislike

  PostDislike({
    required this.userId,
    required this.postId,
    required this.dislikedAt,
    this.reason,
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'postId': postId,
    'dislikedAt': dislikedAt,
    'reason': reason,
  };

  factory PostDislike.fromMap(Map<String, dynamic> map) => PostDislike(
    userId: map['userId'] ?? '',
    postId: map['postId'] ?? '',
    dislikedAt: (map['dislikedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    reason: map['reason'],
  );
}

///user block relationship
class UserBlock {
  final String blockerId; // user doing the blocking
  final String blockedUserId; // user being blocked
  final DateTime blockedAt;
  final String? reason;

  UserBlock({
    required this.blockerId,
    required this.blockedUserId,
    required this.blockedAt,
    this.reason,
  });

  Map<String, dynamic> toMap() => {
    'blockerId': blockerId,
    'blockedUserId': blockedUserId,
    'blockedAt': blockedAt,
    'reason': reason,
  };

  factory UserBlock.fromMap(Map<String, dynamic> map) => UserBlock(
    blockerId: map['blockerId'] ?? '',
    blockedUserId: map['blockedUserId'] ?? '',
    blockedAt: (map['blockedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    reason: map['reason'],
  );
}

///flagged/removed post
class FlaggedPost {
  final String postId;
  final String reason;
  final int dislikeCount;
  final DateTime flaggedAt;
  final bool isRemoved;
  final String? removalReason;

  FlaggedPost({
    required this.postId,
    required this.reason,
    required this.dislikeCount,
    required this.flaggedAt,
    this.isRemoved = false,
    this.removalReason,
  });

  Map<String, dynamic> toMap() => {
    'postId': postId,
    'reason': reason,
    'dislikeCount': dislikeCount,
    'flaggedAt': flaggedAt,
    'isRemoved': isRemoved,
    'removalReason': removalReason,
  };

  factory FlaggedPost.fromMap(Map<String, dynamic> map) => FlaggedPost(
    postId: map['postId'] ?? '',
    reason: map['reason'] ?? '',
    dislikeCount: map['dislikeCount'] ?? 0,
    flaggedAt: (map['flaggedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    isRemoved: map['isRemoved'] ?? false,
    removalReason: map['removalReason'],
  );
}
