import 'package:cloud_firestore/cloud_firestore.dart';

class FriendsService {
  FriendsService._();
  static final FriendsService instance = FriendsService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Future<void> sendFriendRequest({
    required String currentUserId,
    required String otherUserId,
  }) async {
    if (currentUserId.isEmpty || otherUserId.isEmpty) {
      throw Exception('User ids cannot be empty.');
    }

    if (currentUserId == otherUserId) {
      throw Exception('You cannot send a request to yourself.');
    }

    final currentRef = _users.doc(currentUserId);
    final otherRef = _users.doc(otherUserId);

    await _firestore.runTransaction((transaction) async {
      final currentSnap = await transaction.get(currentRef);
      final otherSnap = await transaction.get(otherRef);

      if (!currentSnap.exists) {
        throw Exception('Current user profile does not exist.');
      }

      if (!otherSnap.exists) {
        throw Exception('Other user profile does not exist.');
      }

      final currentData = currentSnap.data() ?? {};
      final otherData = otherSnap.data() ?? {};

      final currentFriends = (currentData['friends'] is List)
          ? (currentData['friends'] as List).map((e) => e.toString()).toList()
          : <String>[];

      final currentOutgoing = (currentData['outgoingFriendRequests'] is List)
          ? (currentData['outgoingFriendRequests'] as List)
              .map((e) => e.toString())
              .toList()
          : <String>[];

      final currentIncoming = (currentData['incomingFriendRequests'] is List)
          ? (currentData['incomingFriendRequests'] as List)
              .map((e) => e.toString())
              .toList()
          : <String>[];

      if (currentFriends.contains(otherUserId)) {
        throw Exception('You are already friends.');
      }

      if (currentOutgoing.contains(otherUserId)) {
        throw Exception('Friend request already sent.');
      }

      if (currentIncoming.contains(otherUserId)) {
        throw Exception('This user already sent you a request.');
      }

      transaction.update(currentRef, {
        'outgoingFriendRequests': FieldValue.arrayUnion([otherUserId]),
      });

      transaction.update(otherRef, {
        'incomingFriendRequests': FieldValue.arrayUnion([currentUserId]),
      });
    });
  }

  Future<void> cancelFriendRequest({
    required String currentUserId,
    required String otherUserId,
  }) async {
    if (currentUserId.isEmpty || otherUserId.isEmpty) {
      throw Exception('User ids cannot be empty.');
    }

    if (currentUserId == otherUserId) {
      throw Exception('Invalid user ids.');
    }

    final currentRef = _users.doc(currentUserId);
    final otherRef = _users.doc(otherUserId);

    await _firestore.runTransaction((transaction) async {
      final currentSnap = await transaction.get(currentRef);
      final otherSnap = await transaction.get(otherRef);

      if (!currentSnap.exists) {
        throw Exception('Current user profile does not exist.');
      }

      if (!otherSnap.exists) {
        throw Exception('Other user profile does not exist.');
      }

      transaction.update(currentRef, {
        'outgoingFriendRequests': FieldValue.arrayRemove([otherUserId]),
      });

      transaction.update(otherRef, {
        'incomingFriendRequests': FieldValue.arrayRemove([currentUserId]),
      });
    });
  }

  Future<void> acceptFriendRequest({
    required String currentUserId,
    required String otherUserId,
  }) async {
    if (currentUserId.isEmpty || otherUserId.isEmpty) {
      throw Exception('User ids cannot be empty.');
    }

    if (currentUserId == otherUserId) {
      throw Exception('Invalid user ids.');
    }

    final currentRef = _users.doc(currentUserId);
    final otherRef = _users.doc(otherUserId);

    await _firestore.runTransaction((transaction) async {
      final currentSnap = await transaction.get(currentRef);
      final otherSnap = await transaction.get(otherRef);

      if (!currentSnap.exists) {
        throw Exception('Current user profile does not exist.');
      }

      if (!otherSnap.exists) {
        throw Exception('Other user profile does not exist.');
      }

      transaction.update(currentRef, {
        'incomingFriendRequests': FieldValue.arrayRemove([otherUserId]),
        'friends': FieldValue.arrayUnion([otherUserId]),
      });

      transaction.update(otherRef, {
        'outgoingFriendRequests': FieldValue.arrayRemove([currentUserId]),
        'friends': FieldValue.arrayUnion([currentUserId]),
      });
    });
  }

  Future<void> declineFriendRequest({
    required String currentUserId,
    required String otherUserId,
  }) async {
    if (currentUserId.isEmpty || otherUserId.isEmpty) {
      throw Exception('User ids cannot be empty.');
    }

    if (currentUserId == otherUserId) {
      throw Exception('Invalid user ids.');
    }

    final currentRef = _users.doc(currentUserId);
    final otherRef = _users.doc(otherUserId);

    await _firestore.runTransaction((transaction) async {
      final currentSnap = await transaction.get(currentRef);
      final otherSnap = await transaction.get(otherRef);

      if (!currentSnap.exists) {
        throw Exception('Current user profile does not exist.');
      }

      if (!otherSnap.exists) {
        throw Exception('Other user profile does not exist.');
      }

      transaction.update(currentRef, {
        'incomingFriendRequests': FieldValue.arrayRemove([otherUserId]),
      });

      transaction.update(otherRef, {
        'outgoingFriendRequests': FieldValue.arrayRemove([currentUserId]),
      });
    });
  }

  Future<void> removeFriend({
    required String currentUserId,
    required String friendUserId,
  }) async {
    if (currentUserId.isEmpty || friendUserId.isEmpty) {
      throw Exception('User ids cannot be empty.');
    }

    if (currentUserId == friendUserId) {
      throw Exception('You cannot remove yourself.');
    }

    final currentRef = _users.doc(currentUserId);
    final friendRef = _users.doc(friendUserId);

    await _firestore.runTransaction((transaction) async {
      final currentSnap = await transaction.get(currentRef);
      final friendSnap = await transaction.get(friendRef);

      if (!currentSnap.exists) {
        throw Exception('Current user profile does not exist.');
      }

      if (!friendSnap.exists) {
        throw Exception('Friend user profile does not exist.');
      }

      transaction.update(currentRef, {
        'friends': FieldValue.arrayRemove([friendUserId]),
      });

      transaction.update(friendRef, {
        'friends': FieldValue.arrayRemove([currentUserId]),
      });
    });
  }

  Stream<List<Map<String, dynamic>>> streamFriends(String currentUserId) {
    return _users.doc(currentUserId).snapshots().asyncMap((userSnap) async {
      if (!userSnap.exists) return <Map<String, dynamic>>[];

      final userData = userSnap.data() ?? {};
      final rawFriends = userData['friends'];

      final friendIds = rawFriends is List
          ? rawFriends
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList()
          : <String>[];

      if (friendIds.isEmpty) return <Map<String, dynamic>>[];

      final futures = friendIds.map((id) => _users.doc(id).get()).toList();
      final friendDocs = await Future.wait(futures);

      final friends = <Map<String, dynamic>>[];

      for (final doc in friendDocs) {
        if (!doc.exists) continue;

        final data = doc.data() ?? {};
        friends.add({
          'uid': doc.id,
          ...data,
        });
      }

      friends.sort((a, b) {
        final aName = (a['username'] ?? '').toString().toLowerCase();
        final bName = (b['username'] ?? '').toString().toLowerCase();
        return aName.compareTo(bName);
      });

      return friends;
    });
  }

  Stream<bool> isFriend({
    required String currentUserId,
    required String otherUserId,
  }) {
    return _users.doc(currentUserId).snapshots().map((snap) {
      if (!snap.exists) return false;

      final data = snap.data() ?? {};
      final rawFriends = data['friends'];

      if (rawFriends is! List) return false;

      return rawFriends.map((e) => e.toString()).contains(otherUserId);
    });
  }

  Stream<String> streamRelationshipStatus({
    required String currentUserId,
    required String otherUserId,
  }) {
    return _users.doc(currentUserId).snapshots().map((snap) {
      if (!snap.exists) return 'none';

      final data = snap.data() ?? {};

      final friends = (data['friends'] is List)
          ? (data['friends'] as List).map((e) => e.toString()).toList()
          : <String>[];

      final incoming = (data['incomingFriendRequests'] is List)
          ? (data['incomingFriendRequests'] as List)
              .map((e) => e.toString())
              .toList()
          : <String>[];

      final outgoing = (data['outgoingFriendRequests'] is List)
          ? (data['outgoingFriendRequests'] as List)
              .map((e) => e.toString())
              .toList()
          : <String>[];

      if (friends.contains(otherUserId)) return 'friends';
      if (incoming.contains(otherUserId)) return 'incoming';
      if (outgoing.contains(otherUserId)) return 'outgoing';
      return 'none';
    });
  }

  Future<int> getMutualFriendsCount({
    required String currentUserId,
    required String otherUserId,
  }) async {
    final currentSnap = await _users.doc(currentUserId).get();
    final otherSnap = await _users.doc(otherUserId).get();

    final currentFriends = (currentSnap.data()?['friends'] as List?)
            ?.map((e) => e.toString())
            .toSet() ??
        {};

    final otherFriends = (otherSnap.data()?['friends'] as List?)
            ?.map((e) => e.toString())
            .toSet() ??
        {};

    return currentFriends.intersection(otherFriends).length;
  }

  Future<List<Map<String, dynamic>>> getMutualFriends({
    required String currentUserId,
    required String otherUserId,
  }) async {
    final currentSnap = await _users.doc(currentUserId).get();
    final otherSnap = await _users.doc(otherUserId).get();

    final currentFriends = (currentSnap.data()?['friends'] as List?)
            ?.map((e) => e.toString())
            .toSet() ??
        {};

    final otherFriends = (otherSnap.data()?['friends'] as List?)
            ?.map((e) => e.toString())
            .toSet() ??
        {};

    final mutualIds = currentFriends.intersection(otherFriends).toList();

    if (mutualIds.isEmpty) return [];

    final futures = mutualIds.map((id) => _users.doc(id).get()).toList();
    final docs = await Future.wait(futures);

    final users = <Map<String, dynamic>>[];

    for (final doc in docs) {
      if (!doc.exists) continue;
      users.add({
        'uid': doc.id,
        ...?doc.data(),
      });
    }

    users.sort((a, b) {
      final aName = (a['username'] ?? '').toString().toLowerCase();
      final bName = (b['username'] ?? '').toString().toLowerCase();
      return aName.compareTo(bName);
    });

    return users;
  }
}