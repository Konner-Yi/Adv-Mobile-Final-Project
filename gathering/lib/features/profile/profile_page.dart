import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/friends_service.dart';
import 'settings_page.dart';
import 'edit_profile_page.dart';
import '../friends/friends_page.dart';

class ProfilePage extends StatefulWidget {
  final String? uid;

  const ProfilePage({super.key, this.uid});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Color blue = Color(0xFF1E88E5);
  static const Color yellow = Color(0xFFFFD600);
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey900 = Color(0xFF212121);

  bool get _isOwnProfile {
    final currentUid = AuthService.instance.currentUser?.uid;
    return widget.uid == null || widget.uid == currentUid;
  }

  void _openSettings() {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsPage()),
    );
  }

  void _openEdit(Map<String, dynamic> profileData) {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfilePage(initialData: profileData),
      ),
    );
  }

  void _openFriends() {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FriendsPage()),
    );
  }

  Future<void> _logout() async {
    HapticFeedback.selectionClick();
    await AuthService.instance.logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/welcome');
    }
  }

  Future<void> _showMutualFriends({
    required String currentUid,
    required String otherUid,
  }) async {
    final mutuals = await FriendsService.instance.getMutualFriends(
      currentUserId: currentUid,
      otherUserId: otherUid,
    );

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 340,
              maxHeight: 420,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Mutual Friends',
                    style: TextStyle(
                      color: grey900,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (mutuals.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'No mutual friends',
                        style: TextStyle(
                          color: grey600,
                          fontSize: 14,
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: mutuals.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final user = mutuals[index];
                          final username = (user['username'] ?? 'User').toString();
                          final realName = (user['realName'] ?? '').toString();
                          final photoUrl = (user['photoUrl'] ?? '').toString();
                          final userUid = (user['uid'] ?? '').toString();

                          return GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                this.context,
                                MaterialPageRoute(
                                  builder: (_) => ProfilePage(uid: userUid),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: grey200,
                                  backgroundImage: photoUrl.isNotEmpty
                                      ? NetworkImage(photoUrl)
                                      : null,
                                  child: photoUrl.isEmpty
                                      ? const Icon(
                                          Icons.person,
                                          size: 18,
                                          color: grey600,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        username,
                                        style: const TextStyle(
                                          color: grey900,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (realName.isNotEmpty)
                                        Text(
                                          realName,
                                          style: const TextStyle(
                                            color: grey600,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: blue,
                        foregroundColor: white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showFriends(String currentUid) async {
    final friends = await FriendsService.instance.streamFriends(currentUid).first;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 340,
              maxHeight: 420,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Friends',
                    style: TextStyle(
                      color: grey900,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (friends.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'No friends yet',
                        style: TextStyle(
                          color: grey600,
                          fontSize: 14,
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: friends.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final user = friends[index];
                          final username = (user['username'] ?? 'User').toString();
                          final realName = (user['realName'] ?? '').toString();
                          final photoUrl = (user['photoUrl'] ?? '').toString();
                          final userUid = (user['uid'] ?? '').toString();

                          return GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                this.context,
                                MaterialPageRoute(
                                  builder: (_) => ProfilePage(uid: userUid),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: grey200,
                                  backgroundImage: photoUrl.isNotEmpty
                                      ? NetworkImage(photoUrl)
                                      : null,
                                  child: photoUrl.isEmpty
                                      ? const Icon(
                                          Icons.person,
                                          size: 18,
                                          color: grey600,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        username,
                                        style: const TextStyle(
                                          color: grey900,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (realName.isNotEmpty)
                                        Text(
                                          realName,
                                          style: const TextStyle(
                                            color: grey600,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: blue,
                        foregroundColor: white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Stream<Map<String, dynamic>?> _profileStream() {
    if (_isOwnProfile) {
      return AuthService.instance.getUserProfileStream();
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .snapshots()
        .map((doc) => doc.data());
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = AuthService.instance.currentUser?.uid;

    return StreamBuilder<Map<String, dynamic>?>(
      stream: _profileStream(),
      builder: (context, snapshot) {
        final profile = snapshot.data ?? {};
        final username = profile['username'] as String? ?? 'username';
        final realName = profile['realName'] as String? ?? '';
        final pronouns = profile['pronouns'] as String? ?? '';
        final bio = profile['bio'] as String? ?? '';
        final country = profile['country'] as String? ?? '';
        final photoUrl = profile['photoUrl'] as String? ?? '';
        final score = profile['score'] ?? 0;
        final followers = profile['followers'] ?? 0;
        final following = profile['following'] ?? 0;
        final friends =
            profile['friends'] is List ? (profile['friends'] as List).length : 0;
        final incomingRequests = profile['incomingFriendRequests'] is List
            ? (profile['incomingFriendRequests'] as List).length
            : 0;
        final rawTags = profile['tags'];
        final tags = rawTags is List ? List<String>.from(rawTags) : <String>[];

        return Scaffold(
          backgroundColor: grey50,
          appBar: AppBar(
            backgroundColor: white,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            titleSpacing: 20,
            title: Text(
              username,
              style: const TextStyle(
                color: grey900,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 0.2,
              ),
            ),
            actions: [
              if (_isOwnProfile)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _SettingsButton(onTap: _openSettings),
                ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: grey200),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  color: white,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Avatar(photoUrl: photoUrl),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Expanded(
                                  child: Text(
                                    realName.isEmpty ? 'Add your name' : realName,
                                    style: TextStyle(
                                      color:
                                          realName.isEmpty ? grey400 : grey900,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      fontStyle: realName.isEmpty
                                          ? FontStyle.italic
                                          : FontStyle.normal,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (pronouns.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: grey100,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: grey200),
                                    ),
                                    child: Text(
                                      pronouns,
                                      style: const TextStyle(
                                        color: grey600,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                _StatItem(
                                  value: score.toString(),
                                  label: 'Score',
                                ),
                                const SizedBox(width: 20),
                                _StatItem(
                                  value: followers.toString(),
                                  label: 'Followers',
                                ),
                                const SizedBox(width: 20),
                                _StatItem(
                                  value: following.toString(),
                                  label: 'Following',
                                ),
                                const SizedBox(width: 20),
                                GestureDetector(
                                  onTap: () {
                                    if (currentUid != null) {
                                      _showFriends(currentUid);
                                    }
                                  },
                                  child: _StatItem(
                                    value: friends.toString(),
                                    label: 'Friends',
                                  ),
                                ),
                              ],
                            ),
                            if (!_isOwnProfile &&
                                currentUid != null &&
                                widget.uid != null)
                              FutureBuilder<int>(
                                future: FriendsService.instance
                                    .getMutualFriendsCount(
                                  currentUserId: currentUid,
                                  otherUserId: widget.uid!,
                                ),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData || snapshot.data == 0) {
                                    return const SizedBox.shrink();
                                  }

                                  final count = snapshot.data!;

                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: GestureDetector(
                                      onTap: () => _showMutualFriends(
                                        currentUid: currentUid,
                                        otherUid: widget.uid!,
                                      ),
                                      child: Text(
                                        '$count mutual friend${count == 1 ? '' : 's'}',
                                        style: const TextStyle(
                                          color: grey600,
                                          fontSize: 12,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_isOwnProfile && currentUid != null && widget.uid != null)
                  StreamBuilder<String>(
                    stream: FriendsService.instance.streamRelationshipStatus(
                      currentUserId: currentUid,
                      otherUserId: widget.uid!,
                    ),
                    builder: (context, snapshot) {
                      final status = snapshot.data ?? 'none';

                      return Container(
                        color: white,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          children: [
                            if (status == 'incoming')
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        try {
                                          await FriendsService.instance
                                              .acceptFriendRequest(
                                            currentUserId: currentUid,
                                            otherUserId: widget.uid!,
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
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: const Text('Accept Request'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        try {
                                          await FriendsService.instance
                                              .declineFriendRequest(
                                            currentUserId: currentUid,
                                            otherUserId: widget.uid!,
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
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: const Text('Decline'),
                                    ),
                                  ),
                                ],
                              )
                            else
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    try {
                                      if (status == 'friends') {
                                        await FriendsService.instance.removeFriend(
                                          currentUserId: currentUid,
                                          friendUserId: widget.uid!,
                                        );
                                      } else if (status == 'outgoing') {
                                        await FriendsService.instance
                                            .cancelFriendRequest(
                                          currentUserId: currentUid,
                                          otherUserId: widget.uid!,
                                        );
                                      } else {
                                        await FriendsService.instance
                                            .sendFriendRequest(
                                          currentUserId: currentUid,
                                          otherUserId: widget.uid!,
                                        );
                                      }

                                      if (!context.mounted) return;

                                      String message;
                                      if (status == 'friends') {
                                        message = 'Removed $username';
                                      } else if (status == 'outgoing') {
                                        message = 'Cancelled request to $username';
                                      } else {
                                        message = 'Sent request to $username';
                                      }

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(message),
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
                                    backgroundColor: status == 'friends'
                                        ? grey200
                                        : status == 'outgoing'
                                            ? grey200
                                            : blue,
                                    foregroundColor: status == 'friends'
                                        ? grey900
                                        : status == 'outgoing'
                                            ? grey900
                                            : white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    status == 'friends'
                                        ? 'Remove Friend'
                                        : status == 'outgoing'
                                            ? 'Cancel Request'
                                            : 'Send Request',
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                Container(height: 1, color: grey200),
                Container(
                  color: white,
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 14,
                        runSpacing: 6,
                        children: [
                          if (country.isNotEmpty)
                            _MetaChip(
                              icon: Icons.flag_outlined,
                              text: country,
                            ),
                          _MetaChip(
                            icon: Icons.calendar_today_outlined,
                            text: 'Joined ${_formatDate(profile['createdAt'])}',
                          ),
                        ],
                      ),
                      if (bio.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          bio,
                          style: const TextStyle(
                            color: grey600,
                            fontSize: 13,
                            height: 1.55,
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 10),
                        Text(
                          _isOwnProfile
                              ? 'No bio yet — tap Edit Profile to add one.'
                              : 'No bio yet.',
                          style: TextStyle(
                            color: grey400,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      if (tags.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: tags.map((t) => _TagChip(label: t)).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (_isOwnProfile) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _openEdit(profile),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit Profile'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: blue,
                          side: const BorderSide(color: blue, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openFriends,
                        icon: const Icon(Icons.people),
                        label: Text(
                          incomingRequests > 0
                              ? 'Friends ($incomingRequests)'
                              : 'Friends',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: blue,
                          foregroundColor: white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ] else ...[
                  const SizedBox(height: 24),
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: const [
                      _TabLabel(label: 'Posts', active: true),
                      SizedBox(width: 24),
                      _TabLabel(label: 'Pins', active: false),
                      SizedBox(width: 24),
                      _TabLabel(label: 'Saved', active: false),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 2,
                  color: blue,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.grid_off_outlined,
                        size: 48,
                        color: grey200,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'No posts yet',
                        style: TextStyle(
                          color: grey400,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                if (_isOwnProfile)
                  Center(
                    child: TextButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, size: 16),
                      label: const Text('Log out'),
                      style: TextButton.styleFrom(foregroundColor: grey600),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(dynamic ts) {
    if (ts == null) return '';
    try {
      final dt = (ts as dynamic).toDate() as DateTime;
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return '';
    }
  }
}

class _SettingsButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SettingsButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.settings_outlined,
              color: Color(0xFF212121),
              size: 16,
            ),
            SizedBox(width: 5),
            Text(
              'Settings',
              style: TextStyle(
                color: Color(0xFF212121),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String photoUrl;
  const _Avatar({required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    const double size = 76;
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFEEEEEE),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: photoUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: photoUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const Icon(
                      Icons.person,
                      size: 40,
                      color: Color(0xFF9E9E9E),
                    ),
                    errorWidget: (_, __, ___) => const Icon(
                      Icons.person,
                      size: 40,
                      color: Color(0xFF9E9E9E),
                    ),
                  )
                : const Icon(
                    Icons.person,
                    size: 40,
                    color: Color(0xFF9E9E9E),
                  ),
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF212121),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF757575),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF9E9E9E)),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF757575),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E88E5).withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF1E88E5).withOpacity(0.25),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF1E88E5),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  final String label;
  final bool active;
  const _TabLabel({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: active ? const Color(0xFF1E88E5) : const Color(0xFF9E9E9E),
        fontSize: 14,
        fontWeight: active ? FontWeight.w700 : FontWeight.w400,
      ),
    );
  }
}
//
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import '../../core/services/auth_service.dart';
// import 'settings_page.dart';
//
// class ProfilePage extends StatefulWidget {
//   const ProfilePage({super.key});
//
//   @override
//   State<ProfilePage> createState() => _ProfilePageState();
// }
//
// class _ProfilePageState extends State<ProfilePage> {
//   static const Color blue    = Color(0xFF1E88E5);
//   static const Color yellow  = Color(0xFFFFD600);
//   static const Color white   = Color(0xFFFFFFFF);
//   static const Color grey50  = Color(0xFFFAFAFA);
//   static const Color grey100 = Color(0xFFF5F5F5);
//   static const Color grey200 = Color(0xFFEEEEEE);
//   static const Color grey400 = Color(0xFFBDBDBD);
//   static const Color grey600 = Color(0xFF757575);
//   static const Color grey900 = Color(0xFF212121);
//
//   void _openSettings() {
//     HapticFeedback.selectionClick();
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => const SettingsPage()),
//     );
//   }
//
//   Future<void> _logout() async {
//     HapticFeedback.selectionClick();
//     await AuthService.instance.logout();
//     if (mounted) Navigator.pushReplacementNamed(context, '/welcome');
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // Pull display name from Firebase if available
//     final firebaseUser = AuthService.instance.currentUser;
//     final displayName = firebaseUser?.displayName ?? 'username';
//
//     return Scaffold(
//       backgroundColor: grey50,
//
//       appBar: AppBar(
//         backgroundColor: white,
//         elevation: 0,
//         surfaceTintColor: Colors.transparent,
//         titleSpacing: 20,
//         title: Text(
//           displayName,
//           style: const TextStyle(
//             color: grey900,
//             fontWeight: FontWeight.bold,
//             fontSize: 20,
//             letterSpacing: 0.2,
//           ),
//         ),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 12),
//             child: _SettingsButton(onTap: _openSettings),
//           ),
//         ],
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(1),
//           child: Container(height: 1, color: grey200),
//         ),
//       ),
//
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.only(bottom: 100),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//
//             // Header card: avatar + name + stats
//             Container(
//               color: white,
//               padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
//               child: Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   _Avatar(),
//                   const SizedBox(width: 20),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Row(
//                           crossAxisAlignment: CrossAxisAlignment.baseline,
//                           textBaseline: TextBaseline.alphabetic,
//                           children: [
//                             const Expanded(
//                               child: Text(
//                                 'Real Name',
//                                 style: TextStyle(
//                                   color: grey900,
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w700,
//                                 ),
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                             ),
//                             const SizedBox(width: 6),
//                             Container(
//                               padding: const EdgeInsets.symmetric(
//                                   horizontal: 8, vertical: 3),
//                               decoration: BoxDecoration(
//                                 color: grey100,
//                                 borderRadius: BorderRadius.circular(10),
//                                 border: Border.all(color: grey200),
//                               ),
//                               child: const Text(
//                                 'they/them',
//                                 style: TextStyle(
//                                   color: grey600,
//                                   fontSize: 11,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 14),
//                         const Row(
//                           children: [
//                             _StatItem(value: '0', label: 'Score'),
//                             SizedBox(width: 20),
//                             _StatItem(value: '0', label: 'Followers'),
//                             SizedBox(width: 20),
//                             _StatItem(value: '0', label: 'Following'),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//
//             Container(height: 1, color: grey200),
//
//             // Bio / info card
//             Container(
//               color: white,
//               width: double.infinity,
//               padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Wrap(
//                     spacing: 14,
//                     runSpacing: 6,
//                     children: [
//                       _MetaChip(
//                         icon: Icons.calendar_today_outlined,
//                         text: 'Joined January 2025',
//                       ),
//                       _MetaChip(
//                         icon: Icons.flag_outlined,
//                         text: 'Canada',
//                       ),
//                       _MetaChip(
//                         icon: Icons.tag,
//                         text: 'adventure · maps · local',
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 14),
//                   const Text(
//                     'This is a placeholder bio. The user can write a short description about themselves here.',
//                     style: TextStyle(
//                       color: grey600,
//                       fontSize: 13,
//                       height: 1.55,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//
//             const SizedBox(height: 8),
//
//             // Edit profile button
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: SizedBox(
//                 width: double.infinity,
//                 child: OutlinedButton.icon(
//                   onPressed: () => HapticFeedback.selectionClick(),
//                   icon: const Icon(Icons.edit_outlined, size: 16),
//                   label: const Text('Edit Profile'),
//                   style: OutlinedButton.styleFrom(
//                     foregroundColor: blue,
//                     side: const BorderSide(color: blue, width: 1.5),
//                     padding: const EdgeInsets.symmetric(vertical: 12),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//
//             const SizedBox(height: 24),
//
//             // Tab row
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20),
//               child: Row(
//                 children: const [
//                   _TabLabel(label: 'Posts', active: true),
//                   SizedBox(width: 24),
//                   _TabLabel(label: 'Pins', active: false),
//                   SizedBox(width: 24),
//                   _TabLabel(label: 'Saved', active: false),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 4),
//             Container(
//                 height: 2,
//                 color: blue,
//                 margin: const EdgeInsets.only(left: 20, right: 20)),
//             const SizedBox(height: 16),
//
//             // Empty state
//             const Center(
//               child: Column(
//                 children: [
//                   Icon(Icons.grid_off_outlined, size: 48, color: grey200),
//                   SizedBox(height: 10),
//                   Text(
//                     'No posts yet',
//                     style: TextStyle(color: grey400, fontSize: 14),
//                   ),
//                 ],
//               ),
//             ),
//
//             const SizedBox(height: 40),
//
//             // Log out
//             Center(
//               child: TextButton.icon(
//                 onPressed: _logout,
//                 icon: const Icon(Icons.logout, size: 16),
//                 label: const Text('Log out'),
//                 style: TextButton.styleFrom(foregroundColor: grey600),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // ─── Helper widgets ───────────────────────────────────────────────────────────
//
// class _SettingsButton extends StatelessWidget {
//   final VoidCallback onTap;
//   const _SettingsButton({required this.onTap});
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//         decoration: BoxDecoration(
//           color: const Color(0xFFF5F5F5),
//           borderRadius: BorderRadius.circular(10),
//           border: Border.all(color: const Color(0xFFEEEEEE)),
//         ),
//         child: const Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(Icons.settings_outlined, color: Color(0xFF212121), size: 16),
//             SizedBox(width: 5),
//             Text(
//               'Settings',
//               style: TextStyle(
//                 color: Color(0xFF212121),
//                 fontSize: 13,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class _Avatar extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       children: [
//         Container(
//           width: 76,
//           height: 76,
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             color: const Color(0xFFEEEEEE),
//             border: Border.all(color: Colors.white, width: 3),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.08),
//                 blurRadius: 8,
//                 offset: const Offset(0, 2),
//               ),
//             ],
//           ),
//           child: const Icon(Icons.person, size: 40, color: Color(0xFF9E9E9E)),
//         ),
//         Positioned(
//           right: 0,
//           bottom: 0,
//           child: Container(
//             width: 24,
//             height: 24,
//             decoration: const BoxDecoration(
//               color: Color(0xFF1E88E5),
//               shape: BoxShape.circle,
//             ),
//             child: const Icon(
//                 Icons.camera_alt_outlined, color: Colors.white, size: 13),
//           ),
//         ),
//       ],
//     );
//   }
// }
//
// class _StatItem extends StatelessWidget {
//   final String value;
//   final String label;
//   const _StatItem({required this.value, required this.label});
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Text(value,
//             style: const TextStyle(
//                 color: Color(0xFF212121),
//                 fontSize: 16,
//                 fontWeight: FontWeight.w800)),
//         const SizedBox(height: 2),
//         Text(label,
//             style: const TextStyle(
//                 color: Color(0xFF757575), fontSize: 11)),
//       ],
//     );
//   }
// }
//
// class _MetaChip extends StatelessWidget {
//   final IconData icon;
//   final String text;
//   const _MetaChip({required this.icon, required this.text});
//
//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Icon(icon, size: 13, color: const Color(0xFF9E9E9E)),
//         const SizedBox(width: 4),
//         Text(text,
//             style: const TextStyle(color: Color(0xFF757575), fontSize: 12)),
//       ],
//     );
//   }
// }
//
// class _TabLabel extends StatelessWidget {
//   final String label;
//   final bool active;
//   const _TabLabel({required this.label, required this.active});
//
//   @override
//   Widget build(BuildContext context) {
//     return Text(
//       label,
//       style: TextStyle(
//         color: active ? const Color(0xFF1E88E5) : const Color(0xFF9E9E9E),
//         fontSize: 14,
//         fontWeight: active ? FontWeight.w700 : FontWeight.w400,
//       ),
//     );
//   }
// }