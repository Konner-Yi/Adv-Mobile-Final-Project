import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'moderation_models.dart';

class ModerationService {
  static const int DISLIKE_THRESHOLD = 5; 
  static const String COLLECTION_POSTS = 'posts';
  static const String COLLECTION_USERS = 'users';
  static const String COLLECTION_MODERATION = 'moderation';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  
  Future<bool> toggleDislike(String postId, String? reason) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User must be logged in');

    final userId = currentUser.uid;
    final postRef = _firestore.collection(COLLECTION_POSTS).doc(postId);
    final dislikeRef = postRef.collection('dislikes').doc(userId);

    final dislikeDoc = await dislikeRef.get();
    final batch = _firestore.batch();

    try {
      if (dislikeDoc.exists) {
        
        batch.delete(dislikeRef);
        batch.update(postRef, {'dislikes': FieldValue.increment(-1)});
        await batch.commit();
        return false;
      } else {
        
        batch.set(dislikeRef, {
          'userId': userId,
          'dislikedAt': FieldValue.serverTimestamp(),
          'reason': reason,
        });
        batch.update(postRef, {'dislikes': FieldValue.increment(1)});

        
        await batch.commit();
        await _checkAndRemovePostIfThresholdMet(postId);
        return true;
      }
    } catch (e) {
      throw Exception('Failed to toggle dislike: $e');
    }
  }

  
  Future<void> _checkAndRemovePostIfThresholdMet(String postId) async {
    try {
      final postSnap =
          await _firestore.collection(COLLECTION_POSTS).doc(postId).get();
      final dislikeCount = (postSnap.data()?['dislikes'] ?? 0) as int;

      if (dislikeCount >= DISLIKE_THRESHOLD) {
        await removePost(
          postId,
          'Auto-removed: Exceeded dislike threshold ($dislikeCount dislikes)',
        );
      }
    } catch (e) {
      print('Error checking dislike threshold: $e');
    }
  }

 
  Future<void> removePost(String postId, String removalReason) async {
    try {
      final batch = _firestore.batch();

      // Update post status
      batch.update(
        _firestore.collection(COLLECTION_POSTS).doc(postId),
        {
          'isRemoved': true,
          'removalReason': removalReason,
          'removedAt': FieldValue.serverTimestamp(),
        },
      );

      // Log moderation action
      batch.set(
        _firestore.doc('moderation/removed_posts').collection('logs').doc(postId),
        {
          'postId': postId,
          'reason': removalReason,
          'removedAt': FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to remove post: $e');
    }
  }

  /// block a user
  Future<void> blockUser(String blockedUserId, {String? reason}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User must be logged in');

    if (currentUser.uid == blockedUserId) {
      throw Exception('Cannot block yourself');
    }

    try {
      final batch = _firestore.batch();

      // Add to current user's block list
      batch.set(
        _firestore
            .collection(COLLECTION_USERS)
            .doc(currentUser.uid)
            .collection('blockedUsers')
            .doc(blockedUserId),
        {
          'blockedUserId': blockedUserId,
          'blockedAt': FieldValue.serverTimestamp(),
          'reason': reason,
        },
      );

      // Log the block action
      batch.set(
        _firestore.doc('moderation/user_blocks').collection('logs').doc('${currentUser.uid}_$blockedUserId'),
        {
          'blockerId': currentUser.uid,
          'blockedUserId': blockedUserId,
          'blockedAt': FieldValue.serverTimestamp(),
          'reason': reason,
        },
      );

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to block user: $e');
    }
  }

  /// Unblock a user
  Future<void> unblockUser(String blockedUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User must be logged in');

    try {
      await _firestore
          .collection(COLLECTION_USERS)
          .doc(currentUser.uid)
          .collection('blockedUsers')
          .doc(blockedUserId)
          .delete();
    } catch (e) {
      throw Exception('Failed to unblock user: $e');
    }
  }

  /// Check if current user has blocked another user
  Future<bool> isUserBlocked(String userId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      final doc = await _firestore
          .collection(COLLECTION_USERS)
          .doc(currentUser.uid)
          .collection('blockedUsers')
          .doc(userId)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Get list of blocked users
  Future<List<String>> getBlockedUsers() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return [];

    try {
      final snapshot = await _firestore
          .collection(COLLECTION_USERS)
          .doc(currentUser.uid)
          .collection('blockedUsers')
          .get();

      return snapshot.docs
          .map((doc) => doc.id)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get dislike count for a post
  Future<int> getDislikeCount(String postId) async {
    try {
      final postSnap =
          await _firestore.collection(COLLECTION_POSTS).doc(postId).get();
      return (postSnap.data()?['dislikes'] ?? 0) as int;
    } catch (e) {
      return 0;
    }
  }

  /// Check if current user has disliked a post
  Future<bool> hasUserDisliked(String postId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      final doc = await _firestore
          .collection(COLLECTION_POSTS)
          .doc(postId)
          .collection('dislikes')
          .doc(currentUser.uid)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Stream to check if a post is removed
  Stream<bool> isPostRemoved(String postId) {
    return _firestore
        .collection(COLLECTION_POSTS)
        .doc(postId)
        .snapshots()
        .map((snap) => (snap.data()?['isRemoved'] ?? false) as bool);
  }

  /// Stream to check if current user has blocked the post owner
  Stream<bool> isPostOwnerBlocked(String postOwnerId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(false);
    }

    return _firestore
        .collection(COLLECTION_USERS)
        .doc(currentUser.uid)
        .collection('blockedUsers')
        .doc(postOwnerId)
        .snapshots()
        .map((snap) => snap.exists);
  }

  
  Future<List<PostDislike>> getDislikesForPost(String postId) async {
    try {
      final snapshot = await _firestore
          .collection(COLLECTION_POSTS)
          .doc(postId)
          .collection('dislikes')
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            return PostDislike(
              userId: doc.id,
              postId: postId,
              dislikedAt:
                  (data['dislikedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              reason: data['reason'],
            );
          })
          .toList();
    } catch (e) {
      return [];
    }
  }
}