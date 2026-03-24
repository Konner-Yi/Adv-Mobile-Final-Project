// import 'package:flutter/material.dart';
//
// class SearchPage extends StatelessWidget {
//   const SearchPage({super.key});
//
//   static const Color cyan = Color(0xFF00E5FF);
//   static const Color indigo = Color(0xFF3949AB);
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.transparent,
//
//       appBar: AppBar(
//         backgroundColor: indigo,
//         elevation: 0,
//         title: const Text(
//           'Search',
//           style: TextStyle(
//             color: cyan,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.logout, color: cyan),
//             onPressed: () {
//               Navigator.pushReplacementNamed(context, '/login');
//             },
//           ),
//         ],
//       ),
//
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Color(0xFF5C6BC0),
//               Color(0xFF5C6BC0),
//             ],
//           ),
//         ),
//         child: const Center(
//           child: Text(
//             'Search functionality will go here',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 18,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/friends_service.dart';
import '../profile/profile_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  static const Color blue = Color(0xFF1E88E5);
  static const Color yellow = Color(0xFFFFD600);
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey900 = Color(0xFF212121);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = AuthService.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: SearchPage.grey50,
      appBar: AppBar(
        backgroundColor: SearchPage.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Search',
          style: TextStyle(
            color: SearchPage.grey900,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: SearchPage.grey200),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: SearchPage.white,
                border: Border.all(color: SearchPage.grey200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() => _query = value.trim().toLowerCase());
                },
                decoration: InputDecoration(
                  hintText: 'Search people, posts, places, events...',
                  hintStyle: const TextStyle(
                    color: SearchPage.grey600,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(Icons.search, color: SearchPage.blue),
                  suffixIcon: _query.isEmpty
                      ? Container(
                          margin: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: SearchPage.yellow,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.travel_explore,
                            color: SearchPage.grey900,
                            size: 18,
                          ),
                        )
                      : IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: SearchPage.grey600,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 20),
              children: [
                _UsersSearchSection(
                  currentUid: currentUid,
                  query: _query,
                ),
                const SizedBox(height: 18),
                const _PlaceholderSection(
                  title: 'Posts',
                  icon: Icons.article_outlined,
                  text: 'Post search can be added here later.',
                ),
                const SizedBox(height: 18),
                const _PlaceholderSection(
                  title: 'Places',
                  icon: Icons.place_outlined,
                  text: 'Place search can be added here later.',
                ),
                const SizedBox(height: 18),
                const _PlaceholderSection(
                  title: 'Events',
                  icon: Icons.event_outlined,
                  text: 'Event search can be added here later.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UsersSearchSection extends StatelessWidget {
  final String? currentUid;
  final String query;

  const _UsersSearchSection({
    required this.currentUid,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    if (currentUid == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: _SectionCard(
          child: Center(
            child: Text(
              'Not logged in',
              style: TextStyle(
                color: SearchPage.grey600,
                fontSize: 16,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(
              title: 'Users',
              icon: Icons.people_outline,
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: CircularProgressIndicator(color: SearchPage.blue),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Something went wrong',
                      style: TextStyle(
                        color: SearchPage.grey600,
                        fontSize: 14,
                      ),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                final filteredUsers = docs.where((doc) {
                  if (doc.id == currentUid) return false;

                  final data = doc.data();
                  final username =
                      (data['username'] ?? '').toString().toLowerCase();
                  final realName =
                      (data['realName'] ?? '').toString().toLowerCase();

                  if (query.isEmpty) return true;

                  return username.contains(query) || realName.contains(query);
                }).toList();

                if (filteredUsers.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text(
                        'No users found',
                        style: TextStyle(
                          color: SearchPage.grey600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: filteredUsers.map((doc) {
                    final data = doc.data();
                    final otherUid = doc.id;
                    final username = data['username']?.toString() ?? 'User';
                    final realName = data['realName']?.toString() ?? '';
                    final photoUrl = data['photoUrl']?.toString() ?? '';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _UserResultTile(
                        currentUid: currentUid!,
                        otherUid: otherUid,
                        username: username,
                        realName: realName,
                        photoUrl: photoUrl,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _UserResultTile extends StatelessWidget {
  final String currentUid;
  final String otherUid;
  final String username;
  final String realName;
  final String photoUrl;

  const _UserResultTile({
    required this.currentUid,
    required this.otherUid,
    required this.username,
    required this.realName,
    required this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfilePage(uid: otherUid),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: SearchPage.grey50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: SearchPage.grey200),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: SearchPage.grey200,
              backgroundImage:
                  photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
              child: photoUrl.isEmpty
                  ? const Icon(Icons.person, color: SearchPage.grey600)
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
                      color: SearchPage.grey900,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (realName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      realName,
                      style: const TextStyle(
                        color: SearchPage.grey600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            StreamBuilder<String>(
              stream: FriendsService.instance.streamRelationshipStatus(
                currentUserId: currentUid,
                otherUserId: otherUid,
              ),
              builder: (context, snapshot) {
                final status = snapshot.data ?? 'none';

                return ElevatedButton(
                  onPressed: () async {
                    try {
                      if (status == 'friends') {
                        await FriendsService.instance.removeFriend(
                          currentUserId: currentUid,
                          friendUserId: otherUid,
                        );
                      } else if (status == 'outgoing') {
                        await FriendsService.instance.cancelFriendRequest(
                          currentUserId: currentUid,
                          otherUserId: otherUid,
                        );
                      } else if (status == 'incoming') {
                        await FriendsService.instance.acceptFriendRequest(
                          currentUserId: currentUid,
                          otherUserId: otherUid,
                        );
                      } else {
                        await FriendsService.instance.sendFriendRequest(
                          currentUserId: currentUid,
                          otherUserId: otherUid,
                        );
                      }
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        status == 'none' ? SearchPage.blue : SearchPage.grey200,
                    foregroundColor:
                        status == 'none' ? SearchPage.white : SearchPage.grey900,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    status == 'friends'
                        ? 'Remove'
                        : status == 'outgoing'
                            ? 'Cancel'
                            : status == 'incoming'
                                ? 'Accept'
                                : 'Send Request',
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final String text;

  const _PlaceholderSection({
    required this.title,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(title: title, icon: icon),
            const SizedBox(height: 14),
            Center(
              child: Column(
                children: [
                  Icon(icon, size: 40, color: SearchPage.grey400),
                  const SizedBox(height: 10),
                  Text(
                    text,
                    style: const TextStyle(
                      color: SearchPage.grey600,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SearchPage.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SearchPage.grey200),
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: SearchPage.blue, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: SearchPage.grey900,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}