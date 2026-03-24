import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/friends_service.dart';
import '../profile/profile_page.dart';

class FriendsPage extends StatelessWidget {
  const FriendsPage({super.key});

  static const Color blue = Color(0xFF1E88E5);
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey900 = Color(0xFF212121);

  Stream<List<Map<String, dynamic>>> _streamIncomingRequests(String currentUid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(currentUid)
        .snapshots()
        .asyncMap((userSnap) async {
      if (!userSnap.exists) return <Map<String, dynamic>>[];

      final data = userSnap.data() ?? {};
      final rawIncoming = data['incomingFriendRequests'];

      final requestIds = rawIncoming is List
          ? rawIncoming
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList()
          : <String>[];

      if (requestIds.isEmpty) return <Map<String, dynamic>>[];

      final futures = requestIds
          .map((id) => FirebaseFirestore.instance.collection('users').doc(id).get())
          .toList();

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
    });
  }

  Stream<List<Map<String, dynamic>>> _streamOutgoingRequests(String currentUid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(currentUid)
        .snapshots()
        .asyncMap((userSnap) async {
      if (!userSnap.exists) return <Map<String, dynamic>>[];

      final data = userSnap.data() ?? {};
      final rawOutgoing = data['outgoingFriendRequests'];

      final requestIds = rawOutgoing is List
          ? rawOutgoing
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList()
          : <String>[];

      if (requestIds.isEmpty) return <Map<String, dynamic>>[];

      final futures = requestIds
          .map((id) => FirebaseFirestore.instance.collection('users').doc(id).get())
          .toList();

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
    });
  }

  Future<void> _acceptRequest({
    required String currentUid,
    required String otherUid,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final currentRef = firestore.collection('users').doc(currentUid);
    final otherRef = firestore.collection('users').doc(otherUid);

    await firestore.runTransaction((transaction) async {
      final currentSnap = await transaction.get(currentRef);
      final otherSnap = await transaction.get(otherRef);

      if (!currentSnap.exists) {
        throw Exception('Current user profile does not exist.');
      }

      if (!otherSnap.exists) {
        throw Exception('Requesting user profile does not exist.');
      }

      transaction.update(currentRef, {
        'incomingFriendRequests': FieldValue.arrayRemove([otherUid]),
        'friends': FieldValue.arrayUnion([otherUid]),
      });

      transaction.update(otherRef, {
        'outgoingFriendRequests': FieldValue.arrayRemove([currentUid]),
        'friends': FieldValue.arrayUnion([currentUid]),
      });
    });
  }

  Future<void> _declineRequest({
    required String currentUid,
    required String otherUid,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final currentRef = firestore.collection('users').doc(currentUid);
    final otherRef = firestore.collection('users').doc(otherUid);

    await firestore.runTransaction((transaction) async {
      final currentSnap = await transaction.get(currentRef);
      final otherSnap = await transaction.get(otherRef);

      if (!currentSnap.exists) {
        throw Exception('Current user profile does not exist.');
      }

      if (!otherSnap.exists) {
        throw Exception('Requesting user profile does not exist.');
      }

      transaction.update(currentRef, {
        'incomingFriendRequests': FieldValue.arrayRemove([otherUid]),
      });

      transaction.update(otherRef, {
        'outgoingFriendRequests': FieldValue.arrayRemove([currentUid]),
      });
    });
  }

  Future<void> _cancelRequest({
    required String currentUid,
    required String otherUid,
  }) async {
    await FriendsService.instance.cancelFriendRequest(
      currentUserId: currentUid,
      otherUserId: otherUid,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = AuthService.instance.currentUser?.uid;

    if (currentUid == null) {
      return const Scaffold(
        backgroundColor: grey50,
        body: Center(
          child: Text(
            'Not logged in',
            style: TextStyle(
              color: grey600,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: grey50,
      appBar: AppBar(
        backgroundColor: white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Friends',
          style: TextStyle(
            color: grey900,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: grey900),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: grey200),
        ),
      ),
      body: Column(
        children: [
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _streamIncomingRequests(currentUid),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const SizedBox.shrink();
              }

              final requests = snapshot.data ?? [];

              if (requests.isEmpty) {
                return const SizedBox.shrink();
              }

              return Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: grey200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Incoming Requests (${requests.length})',
                      style: const TextStyle(
                        color: grey900,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: requests.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final requestUser = requests[index];
                        final requestUid = (requestUser['uid'] ?? '').toString();
                        final username =
                            (requestUser['username'] ?? 'User').toString();
                        final realName =
                            (requestUser['realName'] ?? '').toString();
                        final photoUrl =
                            (requestUser['photoUrl'] ?? '').toString();

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProfilePage(uid: requestUid),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: grey50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: grey200),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: grey200,
                                  backgroundImage: photoUrl.isNotEmpty
                                      ? NetworkImage(photoUrl)
                                      : null,
                                  child: photoUrl.isEmpty
                                      ? const Icon(Icons.person, color: grey600)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        username,
                                        style: const TextStyle(
                                          color: grey900,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      if (realName.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          realName,
                                          style: const TextStyle(
                                            color: grey600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: () async {
                                                try {
                                                  await _acceptRequest(
                                                    currentUid: currentUid,
                                                    otherUid: requestUid,
                                                  );

                                                  if (!context.mounted) return;
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Accepted $username',
                                                      ),
                                                    ),
                                                  );
                                                } catch (e) {
                                                  if (!context.mounted) return;
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content:
                                                          Text(e.toString()),
                                                    ),
                                                  );
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: blue,
                                                foregroundColor: white,
                                                elevation: 0,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 10,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                              child: const Text('Accept'),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: () async {
                                                try {
                                                  await _declineRequest(
                                                    currentUid: currentUid,
                                                    otherUid: requestUid,
                                                  );

                                                  if (!context.mounted) return;
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Declined $username',
                                                      ),
                                                    ),
                                                  );
                                                } catch (e) {
                                                  if (!context.mounted) return;
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content:
                                                          Text(e.toString()),
                                                    ),
                                                  );
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: grey200,
                                                foregroundColor: grey900,
                                                elevation: 0,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 10,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                              child: const Text('Decline'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _streamOutgoingRequests(currentUid),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const SizedBox.shrink();
              }

              final requests = snapshot.data ?? [];

              if (requests.isEmpty) {
                return const SizedBox.shrink();
              }

              return Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: grey200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Outgoing Requests (${requests.length})',
                      style: const TextStyle(
                        color: grey900,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: requests.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final requestUser = requests[index];
                        final requestUid = (requestUser['uid'] ?? '').toString();
                        final username =
                            (requestUser['username'] ?? 'User').toString();
                        final realName =
                            (requestUser['realName'] ?? '').toString();
                        final photoUrl =
                            (requestUser['photoUrl'] ?? '').toString();

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProfilePage(uid: requestUid),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: grey50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: grey200),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: grey200,
                                  backgroundImage: photoUrl.isNotEmpty
                                      ? NetworkImage(photoUrl)
                                      : null,
                                  child: photoUrl.isEmpty
                                      ? const Icon(Icons.person, color: grey600)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        username,
                                        style: const TextStyle(
                                          color: grey900,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      if (realName.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          realName,
                                          style: const TextStyle(
                                            color: grey600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 10),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            try {
                                              await _cancelRequest(
                                                currentUid: currentUid,
                                                otherUid: requestUid,
                                              );

                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Cancelled request to $username',
                                                  ),
                                                ),
                                              );
                                            } catch (e) {
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(e.toString()),
                                                ),
                                              );
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: grey200,
                                            foregroundColor: grey900,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 10,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: const Text('Cancel'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: FriendsService.instance.streamFriends(currentUid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: blue),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Something went wrong',
                      style: TextStyle(
                        color: grey600,
                        fontSize: 14,
                      ),
                    ),
                  );
                }

                final friends = snapshot.data ?? [];

                if (friends.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 48, color: grey400),
                        SizedBox(height: 10),
                        Text(
                          'No friends yet',
                          style: TextStyle(
                            color: grey600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: friends.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final friend = friends[index];
                    final friendUid = (friend['uid'] ?? '').toString();
                    final username = (friend['username'] ?? 'User').toString();
                    final realName = (friend['realName'] ?? '').toString();
                    final photoUrl = (friend['photoUrl'] ?? '').toString();

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfilePage(uid: friendUid),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: grey200),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: grey200,
                              backgroundImage: photoUrl.isNotEmpty
                                  ? NetworkImage(photoUrl)
                                  : null,
                              child: photoUrl.isEmpty
                                  ? const Icon(Icons.person, color: grey600)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    username,
                                    style: const TextStyle(
                                      color: grey900,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (realName.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      realName,
                                      style: const TextStyle(
                                        color: grey600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                try {
                                  await FriendsService.instance.removeFriend(
                                    currentUserId: currentUid,
                                    friendUserId: friendUid,
                                  );

                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Removed $username'),
                                    ),
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(e.toString()),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: grey200,
                                foregroundColor: grey900,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Remove'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}