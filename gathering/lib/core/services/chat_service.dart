import 'package:cloud_firestore/cloud_firestore.dart';

import '../../features/messages/models/chat_models.dart';
import 'auth_service.dart';

class ChatService {
  ChatService._();

  static final ChatService instance = ChatService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<ChatUser?> getCurrentChatUser() async {
    final profile = await AuthService.instance.getUserProfile();
    final authUser = AuthService.instance.currentUser;
    if (authUser == null) return null;

    return ChatUser.fromMap({
      'uid': authUser.uid,
      'username': profile?['username'] ?? authUser.displayName ?? '',
      'email': profile?['email'] ?? authUser.email ?? '',
      'realName': profile?['realName'] ?? '',
      'photoUrl': profile?['photoUrl'] ?? authUser.photoURL ?? '',
      'bio': profile?['bio'] ?? '',
      'pronouns': profile?['pronouns'] ?? '',
      'country': profile?['country'] ?? '',
      'tags': profile?['tags'] ?? const <String>[],
    });
  }

  Stream<List<ChatConversation>> streamRecentConversations(String currentUid) {
    // Log the UID and the query
    print('[Firestore Debug] streamRecentConversations called with currentUid: $currentUid');

    final query = _db
        .collection('conversations')
        .where('memberIds', arrayContains: currentUid);

    print('[Firestore Debug] Firestore query: $query');

    return _db
        .collection('conversations')
        .where('memberIds', arrayContains: currentUid)
        .snapshots()
        .map((snapshot) {
      final conversations = snapshot.docs
          .map(ChatConversation.fromFirestore)
          .toList()
        ..sort((left, right) {
          final leftTime = left.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final rightTime = right.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return rightTime.compareTo(leftTime);
        });
      return conversations;
    });
  }

  Stream<List<ChatMessage>> streamMessages(String conversationId) {
    return _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(ChatMessage.fromFirestore).toList());
  }

  Future<List<ChatUser>> searchUsersByUsername({
    required String query,
    required String currentUid,
  }) async {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return const [];
    }

    final snapshot = await _db.collection('users').limit(75).get();
    final scoredUsers = <({ChatUser user, int score})>[];

    for (final doc in snapshot.docs) {
      final user = ChatUser.fromFirestore(doc);
      if (user.uid.isEmpty || user.uid == currentUid) {
        continue;
      }

      final score = _scoreUsername(user.username, normalizedQuery);
      if (score > 0) {
        scoredUsers.add((user: user, score: score));
      }
    }

    scoredUsers.sort((left, right) {
      if (left.score != right.score) {
        return right.score.compareTo(left.score);
      }
      return left.user.username.toLowerCase().compareTo(right.user.username.toLowerCase());
    });

    return scoredUsers.take(5).map((entry) => entry.user).toList();
  }

  Future<ChatConversation> createOrGetConversation({
    required ChatUser currentUser,
    required ChatUser otherUser,
  }) async {
    final conversationId = _conversationIdFor(currentUser.uid, otherUser.uid);
    final docRef = _db.collection('conversations').doc(conversationId);
    final existing = await docRef.get();

    if (!existing.exists) {
      final now = Timestamp.now();
      await docRef.set({
        'memberIds': [currentUser.uid, otherUser.uid]..sort(),
        'participants': {
          currentUser.uid: currentUser.toParticipantMap(),
          otherUser.uid: otherUser.toParticipantMap(),
        },
        'lastMessage': '',
        'lastMessageAt': now,
        'lastMessageSenderId': null,
        'createdAt': now,
        'updatedAt': now,
        'unreadCounts': {
          currentUser.uid: 0,
          otherUser.uid: 0,
        },
      });
    }

    return ChatConversation.fromFirestore(await docRef.get());
  }

  Future<void> sendMessage({
    required String conversationId,
    required ChatUser currentUser,
    required ChatUser otherUser,
    required String text,
  }) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      return;
    }

    final now = Timestamp.now();
    final conversationRef = _db.collection('conversations').doc(conversationId);
    final messageRef = conversationRef.collection('messages').doc();
    final batch = _db.batch();

    batch.set(messageRef, {
      'senderId': currentUser.uid,
      'text': trimmedText,
      'createdAt': now,
    });

    batch.set(conversationRef, {
      'memberIds': [currentUser.uid, otherUser.uid]..sort(),
      'participants': {
        currentUser.uid: currentUser.toParticipantMap(),
        otherUser.uid: otherUser.toParticipantMap(),
      },
      'lastMessage': trimmedText,
      'lastMessageAt': now,
      'lastMessageSenderId': currentUser.uid,
      'updatedAt': now,
    }, SetOptions(merge: true));

    batch.update(conversationRef, {
      'unreadCounts.${currentUser.uid}': 0,
      'unreadCounts.${otherUser.uid}': FieldValue.increment(1),
    });

    await batch.commit();
  }

  Future<void> markConversationRead({
    required String conversationId,
    required String currentUid,
  }) async {
    await _db.collection('conversations').doc(conversationId).update({
      'unreadCounts.$currentUid': 0,
    });
  }

  String _conversationIdFor(String firstUid, String secondUid) {
    final ids = [firstUid, secondUid]..sort();
    return ids.join('_');
  }

  int _scoreUsername(String username, String query) {
    final candidate = username.trim().toLowerCase();
    if (candidate.isEmpty) {
      return 0;
    }
    if (candidate == query) {
      return 1000;
    }

    final prefixLength = _commonPrefixLength(candidate, query);
    final containsIndex = candidate.indexOf(query);
    var score = 0;

    if (candidate.startsWith(query)) {
      score += 700;
    }
    if (containsIndex >= 0) {
      score += 350 - (containsIndex * 10);
    }
    if (_isSubsequence(query, candidate)) {
      score += 120;
    }
    score += prefixLength * 35;
    score -= (candidate.length - query.length).abs() * 4;

    return score > 0 ? score : 0;
  }

  int _commonPrefixLength(String left, String right) {
    final limit = left.length < right.length ? left.length : right.length;
    var index = 0;
    while (index < limit && left[index] == right[index]) {
      index++;
    }
    return index;
  }

  bool _isSubsequence(String needle, String haystack) {
    var needleIndex = 0;
    for (var haystackIndex = 0; haystackIndex < haystack.length; haystackIndex++) {
      if (needleIndex < needle.length && haystack[haystackIndex] == needle[needleIndex]) {
        needleIndex++;
      }
    }
    return needleIndex == needle.length;
  }
}
