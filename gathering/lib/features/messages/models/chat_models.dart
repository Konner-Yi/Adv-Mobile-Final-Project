import 'package:cloud_firestore/cloud_firestore.dart';

class ChatUser {
  const ChatUser({
    required this.uid,
    required this.username,
    required this.email,
    required this.realName,
    required this.photoUrl,
    required this.bio,
    required this.pronouns,
    required this.country,
    required this.tags,
  });

  final String uid;
  final String username;
  final String email;
  final String realName;
  final String photoUrl;
  final String bio;
  final String pronouns;
  final String country;
  final List<String> tags;

  String get primaryLabel => username.isNotEmpty ? username : realName;
  String get secondaryLabel {
    if (realName.isNotEmpty && realName != username) {
      return realName;
    }
    return email;
  }

  String get avatarText {
    final source = primaryLabel.trim();
    if (source.isEmpty) return '?';
    return source[0].toUpperCase();
  }

  Map<String, dynamic> toParticipantMap() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'realName': realName,
      'photoUrl': photoUrl,
      'bio': bio,
      'pronouns': pronouns,
      'country': country,
      'tags': tags,
    };
  }

  factory ChatUser.fromMap(Map<String, dynamic> map) {
    return ChatUser(
      uid: map['uid'] as String? ?? '',
      username: map['username'] as String? ?? '',
      email: map['email'] as String? ?? '',
      realName: map['realName'] as String? ?? '',
      photoUrl: map['photoUrl'] as String? ?? '',
      bio: map['bio'] as String? ?? '',
      pronouns: map['pronouns'] as String? ?? '',
      country: map['country'] as String? ?? '',
      tags: (map['tags'] as List<dynamic>? ?? const [])
          .map((tag) => tag.toString())
          .toList(),
    );
  }

  factory ChatUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return ChatUser.fromMap(doc.data() ?? <String, dynamic>{});
  }
}

class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.memberIds,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.lastMessageSenderId,
    required this.unreadCounts,
  });

  final String id;
  final List<String> memberIds;
  final Map<String, ChatUser> participants;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final String? lastMessageSenderId;
  final Map<String, int> unreadCounts;

  ChatUser? otherParticipant(String currentUid) {
    for (final entry in participants.entries) {
      if (entry.key != currentUid) {
        return entry.value;
      }
    }
    return null;
  }

  int unreadFor(String uid) => unreadCounts[uid] ?? 0;

  factory ChatConversation.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final participantsMap =
        Map<String, dynamic>.from(data['participants'] as Map? ?? {});
    final unreadMap = Map<String, dynamic>.from(data['unreadCounts'] as Map? ?? {});
    final timestamp = data['lastMessageAt'];

    return ChatConversation(
      id: doc.id,
      memberIds: (data['memberIds'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      participants: participantsMap.map(
        (key, value) => MapEntry(
          key,
          ChatUser.fromMap(Map<String, dynamic>.from(value as Map)),
        ),
      ),
      lastMessage: data['lastMessage'] as String? ?? '',
      lastMessageAt: timestamp is Timestamp ? timestamp.toDate() : null,
      lastMessageSenderId: data['lastMessageSenderId'] as String?,
      unreadCounts: unreadMap.map(
        (key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0),
      ),
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String senderId;
  final String text;
  final DateTime createdAt;

  factory ChatMessage.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final createdAt = data['createdAt'];

    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
    );
  }
}
