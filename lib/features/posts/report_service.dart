import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'report_models.dart';

class ReportAndReputationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  

  /// Report a post for violating community guidelines
  Future<void> reportPost({
    required String postId,
    required String postOwnerId,
    required ReportReason reason,
    required String message,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User must be logged in');

    try {
      final reportId = _firestore.collection('posts').doc().id;
      final batch = _firestore.batch();

      // Create the report
      batch.set(
        _firestore
            .collection('moderation')
            .doc('reports')
            .collection('items')
            .doc(reportId),
        {
          'id': reportId,
          'postId': postId,
          'postOwnerId': postOwnerId,
          'reportedBy': currentUser.uid,
          'reason': reason.toString().split('.').last,
          'message': message,
          'reportedAt': FieldValue.serverTimestamp(),
          'status': 'pending',
        },
      );

      // Increment report count on post
      batch.update(
        _firestore.collection('posts').doc(postId),
        {'reportCount': FieldValue.increment(1)},
      );

      // Auto-remove if 5+ reports
      final postSnap = await _firestore.collection('posts').doc(postId).get();
      final reportCount = (postSnap.data()?['reportCount'] ?? 0) as int;

      if (reportCount >= 5) {
        batch.update(
          _firestore.collection('posts').doc(postId),
          {
            'isRemoved': true,
            'removalReason': 'Auto-removed: Multiple community reports',
            'removedAt': FieldValue.serverTimestamp(),
          },
        );

        // Increment user's postsRemoved
        batch.set(
          _firestore.collection('users').doc(postOwnerId).collection('reputation').doc('data'),
          {
            'postsRemoved': FieldValue.increment(1),
          },
          SetOptions(merge: true),
        );

        // Check if user should be flagged
        await _updateUserBadges(postOwnerId, batch);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to report post: $e');
    }
  }

  /// Get reports for a specific post
  Future<List<PostReport>> getPostReports(String postId) async {
    try {
      final snap = await _firestore
          .collection('moderation')
          .doc('reports')
          .collection('items')
          .where('postId', isEqualTo: postId)
          .orderBy('reportedAt', descending: true)
          .get();

      return snap.docs
          .map((doc) => PostReport.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get user's report history
  Future<List<PostReport>> getUserReports(String userId) async {
    try {
      final snap = await _firestore
          .collection('moderation')
          .doc('reports')
          .collection('items')
          .where('reportedBy', isEqualTo: userId)
          .orderBy('reportedAt', descending: true)
          .get();

      return snap.docs
          .map((doc) => PostReport.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ========== APPEAL FEATURE ==========

  /// Submit an appeal for a removed post
  Future<void> submitAppeal({
    required String postId,
    required String appealReason,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User must be logged in');

    try {
      final appealId = _firestore.collection('posts').doc().id;
      final batch = _firestore.batch();

      // Create the appeal
      batch.set(
        _firestore
            .collection('moderation')
            .doc('appeals')
            .collection('items')
            .doc(appealId),
        {
          'id': appealId,
          'postId': postId,
          'userId': currentUser.uid,
          'appealReason': appealReason,
          'appealedAt': FieldValue.serverTimestamp(),
          'status': 'pending',
          'rejectionReason': null,
          'reviewedAt': null,
        },
      );

      // Increment user's appealsSubmitted
      batch.set(
        _firestore.collection('users').doc(currentUser.uid).collection('reputation').doc('data'),
        {
          'appealsSubmitted': FieldValue.increment(1),
        },
        SetOptions(merge: true),
      );

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to submit appeal: $e');
    }
  }

  /// Get appeals for a specific post
  Future<List<PostAppeal>> getPostAppeals(String postId) async {
    try {
      final snap = await _firestore
          .collection('moderation')
          .doc('appeals')
          .collection('items')
          .where('postId', isEqualTo: postId)
          .orderBy('appealedAt', descending: true)
          .get();

      return snap.docs
          .map((doc) => PostAppeal.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get user's appeal history
  Future<List<PostAppeal>> getUserAppeals(String userId) async {
    try {
      final snap = await _firestore
          .collection('moderation')
          .doc('appeals')
          .collection('items')
          .where('userId', isEqualTo: userId)
          .orderBy('appealedAt', descending: true)
          .get();

      return snap.docs
          .map((doc) => PostAppeal.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get pending appeals count (for admin dashboard)
Future<int> getPendingAppealsCount() async {
  try {
    final snap = await _firestore
        .collection('moderation')
        .doc('appeals')
        .collection('items')
        .where('status', isEqualTo: 'pending')
        .get();
    return snap.docs.length;
  } catch (e) {
    return 0;
  }
}

  // ========== REPUTATION FEATURE ==========

  /// Get or create user reputation
  Future<UserReputation> getUserReputation(String userId) async {
    try {
      final snap = await _firestore
          .collection('users')
          .doc(userId)
          .collection('reputation')
          .doc('data')
          .get();

      if (snap.exists) {
        return UserReputation.fromMap(snap.data()!);
      } else {
        // Create new reputation record
        final createdAt = DateTime.now();
        final reputation = UserReputation(
          userId: userId,
          createdAt: createdAt,
        );

        await _firestore
            .collection('users')
            .doc(userId)
            .collection('reputation')
            .doc('data')
            .set(reputation.toMap());

        return reputation;
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update user badges based on activity
  Future<void> _updateUserBadges(
    String userId,
    WriteBatch? batch,
  ) async {
    try {
      final reputation = await getUserReputation(userId);
      final newBadges = <UserBadge>[];

      // Check if user is new (account < 30 days)
      final accountAge = DateTime.now().difference(reputation.createdAt).inDays;
      if (accountAge < 30) {
        newBadges.add(UserBadge.newUser);
      }

      // Check if user is trusted (0 posts removed, high score)
      if (reputation.postsRemoved == 0 && reputation.score >= 100) {
        newBadges.add(UserBadge.trusted);
      }

      // Check if user is flagged (multiple posts removed)
      if (reputation.postsRemoved >= 2) {
        newBadges.add(UserBadge.flagged);
      }

      // Check if user is community helper (appeals approved)
      if (reputation.appealsApproved >= 2) {
        newBadges.add(UserBadge.communityHelper);
      }

      // Update badges
      final updateData = {
        'badges': newBadges.map((b) => b.toString().split('.').last).toList(),
      };

      if (batch != null) {
        batch.set(
          _firestore.collection('users').doc(userId).collection('reputation').doc('data'),
          updateData,
          SetOptions(merge: true),
        );
      } else {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('reputation')
            .doc('data')
            .set(updateData, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error updating user badges: $e');
    }
  }

  /// Update badges for a user
  Future<void> updateUserBadges(String userId) async {
    await _updateUserBadges(userId, null);
  }

  /// Get badge for display
  String getUserBadgeDisplay(UserReputation reputation) {
    return reputation.badgeDisplay;
  }

  /// Increment user score (used by other services)
  Future<void> incrementUserScore(String userId, int points) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update({'score': FieldValue.increment(points)});

      // Update badges after score change
      await updateUserBadges(userId);
    } catch (e) {
      throw Exception('Failed to increment user score: $e');
    }
  }

  /// Increment warning count and handle suspension/ban
  Future<void> issueWarning(String userId) async {
    try {
      final batch = _firestore.batch();
      const maxWarnings = 3;

      // Increment warning count
      batch.set(
        _firestore.collection('users').doc(userId).collection('reputation').doc('data'),
        {
          'warningCount': FieldValue.increment(1),
        },
        SetOptions(merge: true),
      );

      // Check warning count
      final reputation = await getUserReputation(userId);
      final newWarningCount = reputation.warningCount + 1;

      if (newWarningCount >= maxWarnings) {
        // Ban user
        batch.set(
          _firestore.collection('users').doc(userId).collection('reputation').doc('data'),
          {
            'isBanned': true,
            'bannedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      } else if (newWarningCount == 2) {
        // Suspend for 24 hours
        batch.set(
          _firestore.collection('users').doc(userId).collection('reputation').doc('data'),
          {
            'isSuspended': true,
            'suspendedUntil':
                Timestamp.fromDate(DateTime.now().add(const Duration(hours: 24))),
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to issue warning: $e');
    }
  }

  /// Get moderation history for a user
  Future<Map<String, dynamic>> getUserModerationHistory(String userId) async {
    try {
      final reports = await getUserReports(userId);
      final appeals = await getUserAppeals(userId);
      final reputation = await getUserReputation(userId);

      return {
        'reputation': reputation,
        'postsReported': reports.length,
        'reportsSubmitted': reports.length,
        'appealsSubmitted': appeals.length,
        'appealsApproved': reputation.appealsApproved,
        'appealsRejected': appeals.where((a) => a.status == AppealStatus.rejected).length,
      };
    } catch (e) {
      rethrow;
    }
  }
}
