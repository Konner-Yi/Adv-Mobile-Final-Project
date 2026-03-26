import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/services/auth_service.dart';
import '../friends/friends_page.dart';
import '../profile/profile_page.dart';

class HomePage extends StatefulWidget {
  final VoidCallback onOpenMap;

  const HomePage({
    super.key,
    required this.onOpenMap,
  });

  @override
  State<HomePage> createState() => _HomePageState();

  static const Color blue = Color(0xFF1E88E5);
  static const Color yellow = Color(0xFFFFD600);
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey900 = Color(0xFF212121);
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _savingLocation = false;

  final List<Map<String, dynamic>> _activityItems = const [
    {
      'title': 'New spot reported nearby',
      'subtitle': '0.3 km away · just now',
      'type': 'place',
    },
    {
      'title': 'Event happening soon',
      'subtitle': '0.3 km away · just now',
      'type': 'event',
    },
    {
      'title': 'New spot reported nearby',
      'subtitle': '0.3 km away · just now',
      'type': 'place',
    },
    {
      'title': 'Event happening soon',
      'subtitle': '0.3 km away · just now',
      'type': 'event',
    },
    {
      'title': 'Popular food spot nearby',
      'subtitle': '0.8 km away · 5 min ago',
      'type': 'food',
    },
  ];

  @override
  void initState() {
    super.initState();
    _saveCurrentUserLocation();
  }

  List<Map<String, dynamic>> get _filteredItems {
    if (_query.isEmpty) return _activityItems;

    return _activityItems.where((item) {
      final title = (item['title'] ?? '').toString().toLowerCase();
      final subtitle = (item['subtitle'] ?? '').toString().toLowerCase();
      final type = (item['type'] ?? '').toString().toLowerCase();

      return title.contains(_query) ||
          subtitle.contains(_query) ||
          type.contains(_query);
    }).toList();
  }

  Future<void> _saveCurrentUserLocation() async {
    if (_savingLocation) return;

    final user = AuthService.instance.currentUser;
    if (user == null) return;

    _savingLocation = true;

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await AuthService.instance.updateUserProfile({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'locationUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
    } finally {
      _savingLocation = false;
    }
  }

  Stream<List<Map<String, dynamic>>> _searchUsers(String query) {
    if (query.isEmpty) {
      return Stream.value([]);
    }

    return FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .map((snapshot) {
      final lowerQuery = query.toLowerCase();

      final users = snapshot.docs
          .map((doc) => {
                'uid': doc.id,
                ...doc.data(),
              })
          .where((user) {
            final username = (user['username'] ?? '').toString().toLowerCase();
            final realName = (user['realName'] ?? '').toString().toLowerCase();
            return username.contains(lowerQuery) || realName.contains(lowerQuery);
          })
          .toList();

      users.sort((a, b) {
        final aUsername = (a['username'] ?? '').toString().toLowerCase();
        final bUsername = (b['username'] ?? '').toString().toLowerCase();
        return aUsername.compareTo(bUsername);
      });

      return users;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openFriendsPage() {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const FriendsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _filteredItems;

    return Scaffold(
      backgroundColor: HomePage.grey50,
      appBar: AppBar(
        backgroundColor: HomePage.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: HomePage.blue,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.location_on,
                  color: HomePage.yellow,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Local Link',
              style: TextStyle(
                color: HomePage.grey900,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: HomePage.grey600,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(
              Icons.account_circle_outlined,
              color: HomePage.grey600,
            ),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: HomePage.grey200),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: HomePage.white,
                border: Border.all(color: HomePage.grey200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() => _query = value.trim().toLowerCase());
                },
                decoration: InputDecoration(
                  hintText: 'Search places, events, people…',
                  hintStyle: const TextStyle(
                    color: HomePage.grey600,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(Icons.search, color: HomePage.blue),
                  suffixIcon: _query.isEmpty
                      ? Container(
                          margin: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: HomePage.yellow,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.tune,
                            color: HomePage.grey900,
                            size: 18,
                          ),
                        )
                      : IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: HomePage.grey600,
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
          if (_query.isNotEmpty)
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _searchUsers(_query),
              builder: (context, snapshot) {
                final users = snapshot.data ?? [];

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: SizedBox(
                      height: 80,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: HomePage.blue,
                        ),
                      ),
                    ),
                  );
                }

                if (users.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: HomePage.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: HomePage.grey200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: users.length > 5 ? 5 : users.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: HomePage.grey200,
                    ),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final uid = (user['uid'] ?? '').toString();
                      final username = (user['username'] ?? 'User').toString();
                      final realName = (user['realName'] ?? '').toString();

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: HomePage.grey200,
                          backgroundImage: (user['photoUrl'] ?? '')
                                  .toString()
                                  .isNotEmpty
                              ? NetworkImage((user['photoUrl'] ?? '').toString())
                              : null,
                          child: (user['photoUrl'] ?? '').toString().isEmpty
                              ? const Icon(
                                  Icons.person,
                                  color: HomePage.grey600,
                                )
                              : null,
                        ),
                        title: Text(
                          username,
                          style: const TextStyle(
                            color: HomePage.grey900,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: realName.isNotEmpty
                            ? Text(
                                realName,
                                style: const TextStyle(
                                  color: HomePage.grey600,
                                  fontSize: 12,
                                ),
                              )
                            : null,
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: HomePage.grey600,
                          size: 18,
                        ),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProfilePage(uid: uid),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const _Chip(label: 'Near Me', icon: Icons.near_me, active: true),
                const _Chip(label: 'Events', icon: Icons.event, active: false),
                GestureDetector(
                  onTap: _openFriendsPage,
                  child: const _Chip(
                    label: 'Friends',
                    icon: Icons.people_outline,
                    active: false,
                  ),
                ),
                const _Chip(label: 'Food', icon: Icons.restaurant, active: false),
                const _Chip(label: 'Traffic', icon: Icons.traffic, active: false),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onOpenMap();
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: HomePage.blue,
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 6,
                        decoration: const BoxDecoration(
                          color: HomePage.yellow,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.map,
                            color: HomePage.white,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Open Live Map',
                            style: TextStyle(
                              color: HomePage.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'See what\'s happening around you',
                            style: TextStyle(
                              color: HomePage.white.withOpacity(0.85),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: HomePage.yellow,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Explore →',
                          style: TextStyle(
                            color: HomePage.grey900,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _query.isEmpty ? 'Nearby Activity' : 'Search Results',
                  style: const TextStyle(
                    color: HomePage.grey900,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    _query.isEmpty ? 'See all' : '${filteredItems.length} found',
                    style: const TextStyle(
                      color: HomePage.blue,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredItems.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: HomePage.grey600,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'No results found',
                          style: TextStyle(
                            color: HomePage.grey600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: filteredItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _FeedCard(
                      title: filteredItems[i]['title'] as String,
                      subtitle: filteredItems[i]['subtitle'] as String,
                      type: filteredItems[i]['type'] as String,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;

  const _Chip({
    required this.label,
    required this.icon,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? HomePage.blue : HomePage.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? HomePage.blue : HomePage.grey200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: active ? HomePage.white : HomePage.grey600,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: active ? HomePage.white : HomePage.grey600,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String type;

  const _FeedCard({
    required this.title,
    required this.subtitle,
    required this.type,
  });

  static const Color blue = Color(0xFF1E88E5);
  static const Color yellow = Color(0xFFFFD600);
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey900 = Color(0xFF212121);

  @override
  Widget build(BuildContext context) {
    final isPlace = type == 'place';
    final isFood = type == 'food';

    IconData icon;
    Color iconBg;
    Color iconColor;

    if (isFood) {
      icon = Icons.restaurant;
      iconBg = yellow.withOpacity(0.25);
      iconColor = grey900;
    } else if (isPlace) {
      icon = Icons.place;
      iconBg = blue.withOpacity(0.15);
      iconColor = blue;
    } else {
      icon = Icons.event;
      iconBg = yellow.withOpacity(0.25);
      iconColor = grey900;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: grey200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: iconBg,
            child: Icon(
              icon,
              color: iconColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: grey900,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: grey600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: grey600, size: 18),
        ],
      ),
    );
  }
}