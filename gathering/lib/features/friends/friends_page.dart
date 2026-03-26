import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../profile/profile_page.dart';

enum _FriendsFilter { all, az, za, recent, nearby }

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  static const Color blue = Color(0xFF1E88E5);
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey900 = Color(0xFF212121);

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  _FriendsFilter _selectedFilter = _FriendsFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
          .map((id) =>
              FirebaseFirestore.instance.collection('users').doc(id).get())
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
          .map((id) =>
              FirebaseFirestore.instance.collection('users').doc(id).get())
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

  Stream<List<Map<String, dynamic>>> _streamFriends(String currentUid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(currentUid)
        .snapshots()
        .asyncMap((userSnap) async {
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

      final futures = friendIds
          .map((id) =>
              FirebaseFirestore.instance.collection('users').doc(id).get())
          .toList();

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
        throw Exception('Other user profile does not exist.');
      }

      transaction.update(currentRef, {
        'outgoingFriendRequests': FieldValue.arrayRemove([otherUid]),
      });

      transaction.update(otherRef, {
        'incomingFriendRequests': FieldValue.arrayRemove([currentUid]),
      });
    });
  }

  Future<void> _removeFriend({
    required String currentUid,
    required String friendUid,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final currentRef = firestore.collection('users').doc(currentUid);
    final friendRef = firestore.collection('users').doc(friendUid);

    await firestore.runTransaction((transaction) async {
      final currentSnap = await transaction.get(currentRef);
      final friendSnap = await transaction.get(friendRef);

      if (!currentSnap.exists) {
        throw Exception('Current user profile does not exist.');
      }

      if (!friendSnap.exists) {
        throw Exception('Friend user profile does not exist.');
      }

      transaction.update(currentRef, {
        'friends': FieldValue.arrayRemove([friendUid]),
      });

      transaction.update(friendRef, {
        'friends': FieldValue.arrayRemove([currentUid]),
      });
    });
  }

  Future<List<Map<String, dynamic>>> _loadFriendsWithDistance(
    List<Map<String, dynamic>> friends,
    String currentUid,
  ) async {
    final currentDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUid)
        .get();

    final currentData = currentDoc.data() ?? {};
    final currentLat = _extractLatitude(currentData);
    final currentLng = _extractLongitude(currentData);

    return friends.map((friend) {
      final friendLat = _extractLatitude(friend);
      final friendLng = _extractLongitude(friend);

      double? distanceKm;
      if (currentLat != null &&
          currentLng != null &&
          friendLat != null &&
          friendLng != null) {
        distanceKm = _distanceKm(
          lat1: currentLat,
          lng1: currentLng,
          lat2: friendLat,
          lng2: friendLng,
        );
      }

      return {
        ...friend,
        'distanceKm': distanceKm,
        'hasDistance': distanceKm != null,
      };
    }).toList();
  }

  List<Map<String, dynamic>> _applyFriendSearchAndFilter(
    List<Map<String, dynamic>> friends,
  ) {
    var filtered = List<Map<String, dynamic>>.from(friends);

    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((friend) {
        final username = (friend['username'] ?? '').toString().toLowerCase();
        final realName = (friend['realName'] ?? '').toString().toLowerCase();
        return username.contains(query) || realName.contains(query);
      }).toList();
    }

    switch (_selectedFilter) {
      case _FriendsFilter.all:
      case _FriendsFilter.az:
        filtered.sort((a, b) {
          final aName = (a['username'] ?? '').toString().toLowerCase();
          final bName = (b['username'] ?? '').toString().toLowerCase();
          return aName.compareTo(bName);
        });
        break;
      case _FriendsFilter.za:
        filtered.sort((a, b) {
          final aName = (a['username'] ?? '').toString().toLowerCase();
          final bName = (b['username'] ?? '').toString().toLowerCase();
          return bName.compareTo(aName);
        });
        break;
      case _FriendsFilter.recent:
        filtered.sort((a, b) {
          final aRecent = _extractRecentValue(a);
          final bRecent = _extractRecentValue(b);
          return bRecent.compareTo(aRecent);
        });
        break;
      case _FriendsFilter.nearby:
        filtered =
            filtered.where((friend) => friend['distanceKm'] is num).toList();
        filtered.sort((a, b) {
          final aDistance = (a['distanceKm'] as num).toDouble();
          final bDistance = (b['distanceKm'] as num).toDouble();
          return aDistance.compareTo(bDistance);
        });
        break;
    }

    return filtered;
  }

  List<Map<String, dynamic>> _getNearbyFriends(List<Map<String, dynamic>> friends) {
    final nearby = friends.where((friend) => friend['distanceKm'] is num).toList();

    nearby.sort((a, b) {
      final aDistance = (a['distanceKm'] as num).toDouble();
      final bDistance = (b['distanceKm'] as num).toDouble();
      return aDistance.compareTo(bDistance);
    });

    return nearby;
  }

  int _extractRecentValue(Map<String, dynamic> friend) {
    final candidates = [
      friend['friendAddedAt'],
      friend['friendsSince'],
      friend['createdAt'],
      friend['updatedAt'],
      friend['timestamp'],
    ];

    for (final value in candidates) {
      if (value is Timestamp) return value.millisecondsSinceEpoch;
      if (value is DateTime) return value.millisecondsSinceEpoch;
      if (value is int) return value;
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed.millisecondsSinceEpoch;
      }
    }

    return 0;
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? blue : white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? blue : grey200),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? white : grey900,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _formatDistance(dynamic distanceKm) {
    if (distanceKm is! num) return '';
    if (distanceKm < 1) {
      final meters = (distanceKm * 1000).round();
      return '$meters m away';
    }
    return '${distanceKm.toStringAsFixed(1)} km away';
  }

  double? _extractLatitude(Map<String, dynamic> data) {
    final direct = _toDouble(data['latitude']);
    if (direct != null) return direct;

    final lat = _toDouble(data['lat']);
    if (lat != null) return lat;

    final location = data['location'];
    if (location is GeoPoint) return location.latitude;
    if (location is Map<String, dynamic>) {
      final nested = _toDouble(location['latitude']) ?? _toDouble(location['lat']);
      if (nested != null) return nested;
    }

    return null;
  }

  double? _extractLongitude(Map<String, dynamic> data) {
    final direct = _toDouble(data['longitude']);
    if (direct != null) return direct;

    final lng = _toDouble(data['lng']) ?? _toDouble(data['lon']);
    if (lng != null) return lng;

    final location = data['location'];
    if (location is GeoPoint) return location.longitude;
    if (location is Map<String, dynamic>) {
      final nested = _toDouble(location['longitude']) ??
          _toDouble(location['lng']) ??
          _toDouble(location['lon']);
      if (nested != null) return nested;
    }

    return null;
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  double _distanceKm({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    const earthRadiusKm = 6371.0;

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLng = _degreesToRadians(lng2 - lng1);

    final a = pow(sin(dLat / 2), 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            pow(sin(dLng / 2), 2);

    final c = 2 * atan2(sqrt(a.toDouble()), sqrt(1 - a.toDouble()));
    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  Widget _buildUserCard({
    required BuildContext context,
    required String currentUid,
    required Map<String, dynamic> user,
    bool showRemoveButton = true,
    bool compact = false,
  }) {
    final uid = (user['uid'] ?? '').toString();
    final username = (user['username'] ?? 'User').toString();
    final realName = (user['realName'] ?? '').toString();
    final photoUrl = (user['photoUrl'] ?? '').toString();
    final distanceText = _formatDistance(user['distanceKm']);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfilePage(uid: uid),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(compact ? 12 : 14),
        decoration: BoxDecoration(
          color: white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: grey200),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: compact ? 22 : 24,
              backgroundColor: grey200,
              backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
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
                    style: TextStyle(
                      color: grey900,
                      fontSize: compact ? 14 : 15,
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
                  if (distanceText.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      distanceText,
                      style: const TextStyle(
                        color: blue,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showRemoveButton)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Messaging $username coming soon'),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: blue,
                      foregroundColor: white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Message'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        await _removeFriend(
                          currentUid: currentUid,
                          friendUid: uid,
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
                        horizontal: 12,
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
          ],
        ),
      ),
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
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: grey200),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search friends',
                    hintStyle: const TextStyle(
                      color: grey600,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(Icons.search, color: grey600),
                    suffixIcon: _searchQuery.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                            icon: const Icon(Icons.close, color: grey600),
                          ),
                    filled: true,
                    fillColor: grey50,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: grey200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: blue),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: 'All',
                        selected: _selectedFilter == _FriendsFilter.all,
                        onTap: () {
                          setState(() {
                            _selectedFilter = _FriendsFilter.all;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'A-Z',
                        selected: _selectedFilter == _FriendsFilter.az,
                        onTap: () {
                          setState(() {
                            _selectedFilter = _FriendsFilter.az;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Z-A',
                        selected: _selectedFilter == _FriendsFilter.za,
                        onTap: () {
                          setState(() {
                            _selectedFilter = _FriendsFilter.za;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Recent',
                        selected: _selectedFilter == _FriendsFilter.recent,
                        onTap: () {
                          setState(() {
                            _selectedFilter = _FriendsFilter.recent;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Nearby',
                        selected: _selectedFilter == _FriendsFilter.nearby,
                        onTap: () {
                          setState(() {
                            _selectedFilter = _FriendsFilter.nearby;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
                                                      content: Text(e.toString()),
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
                                                      content: Text(e.toString()),
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
              stream: _streamFriends(currentUid),
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

                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: _loadFriendsWithDistance(friends, currentUid),
                  builder: (context, distanceSnapshot) {
                    if (distanceSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: blue),
                      );
                    }

                    final enrichedFriends = distanceSnapshot.data ?? friends;
                    final nearbyFriends = _getNearbyFriends(enrichedFriends);
                    final filteredFriends =
                        _applyFriendSearchAndFilter(enrichedFriends);

                    if (filteredFriends.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off, size: 48, color: grey400),
                            const SizedBox(height: 10),
                            Text(
                              _selectedFilter == _FriendsFilter.nearby
                                  ? 'No nearby friends found'
                                  : 'No matching friends found',
                              style: const TextStyle(
                                color: grey600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final showNearbySection =
                        _selectedFilter != _FriendsFilter.nearby &&
                        _searchQuery.trim().isEmpty &&
                        nearbyFriends.isNotEmpty;

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      children: [
                        if (showNearbySection) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: grey200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.near_me,
                                      color: blue,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Nearby Friends (${nearbyFriends.length})',
                                      style: const TextStyle(
                                        color: grey900,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: nearbyFriends.length > 3
                                      ? 3
                                      : nearbyFriends.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    return _buildUserCard(
                                      context: context,
                                      currentUid: currentUid,
                                      user: nearbyFriends[index],
                                      compact: true,
                                    );
                                  },
                                ),
                                if (nearbyFriends.length > 3) ...[
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          _selectedFilter = _FriendsFilter.nearby;
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: blue,
                                        foregroundColor: white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 11,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: const Text('View All Nearby'),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        ...List.generate(filteredFriends.length, (index) {
                          final friend = filteredFriends[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == filteredFriends.length - 1 ? 0 : 10,
                            ),
                            child: _buildUserCard(
                              context: context,
                              currentUid: currentUid,
                              user: friend,
                            ),
                          );
                        }),
                      ],
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