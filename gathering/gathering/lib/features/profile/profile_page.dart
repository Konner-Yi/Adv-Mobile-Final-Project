import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/friends_service.dart';
import 'settings_page.dart';
import 'edit_profile_page.dart';
// import 'profile_pins_grid.dart';
// import 'profile_posts_grid.dart';
// import 'profile_saved_grid.dart';
import '../friends/friends_page.dart';

class ProfilePage extends StatefulWidget {
  final String? uid;

  const ProfilePage({super.key, this.uid});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // ── Palette ───────────────────────────────────────────────────────────────
  static const Color blue    = Color(0xFF1E88E5);
  static const Color yellow  = Color(0xFFFFD600);
  static const Color white   = Color(0xFFFFFFFF);
  static const Color grey50  = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey900 = Color(0xFF212121);

  // ── Helpers ───────────────────────────────────────────────────────────────
  bool get _isOwnProfile {
    final currentUid = AuthService.instance.currentUser?.uid;
    return widget.uid == null || widget.uid == currentUid;
  }

  // ── Navigation ────────────────────────────────────────────────────────────
  void _openSettings() {
    HapticFeedback.selectionClick();
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const SettingsPage()));
  }

  void _openEdit(Map<String, dynamic> profileData) {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => EditProfilePage(initialData: profileData)),
    );
  }

  void _openFriends() {
    HapticFeedback.selectionClick();
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const FriendsPage()));
  }

  Future<void> _logout() async {
    HapticFeedback.selectionClick();
    await AuthService.instance.logout();
    if (mounted) Navigator.pushReplacementNamed(context, '/welcome');
  }

  // ── Mutual friends dialog ─────────────────────────────────────────────────
  Future<void> _showMutualFriends({
    required String currentUid,
    required String otherUid,
  }) async {
    final mutuals = await FriendsService.instance.getMutualFriends(
      currentUserId: currentUid,
      otherUserId:   otherUid,
    );
    if (!mounted) return;
    _showFriendListDialog('Mutual Friends', mutuals);
  }

  // ── Friends list dialog ───────────────────────────────────────────────────
  Future<void> _showFriends(String uid) async {
    final friends =
    await FriendsService.instance.streamFriends(uid).first;
    if (!mounted) return;
    _showFriendListDialog('Friends', friends);
  }

  void _showFriendListDialog(
      String title, List<Map<String, dynamic>> users) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340, maxHeight: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: grey900,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                if (users.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No $title yet',
                      style: const TextStyle(color: grey600, fontSize: 14),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: users.length,
                      separatorBuilder: (_, __) =>
                      const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final user     = users[index];
                        final username = (user['username'] ?? 'User').toString();
                        final realName = (user['realName'] ?? '').toString();
                        final photoUrl = (user['photoUrl'] ?? '').toString();
                        final userUid  = (user['uid']      ?? '').toString();

                        return GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              this.context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      ProfilePage(uid: userUid)),
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
                                    ? const Icon(Icons.person,
                                    size: 18, color: grey600)
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(username,
                                        style: const TextStyle(
                                          color: grey900,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        )),
                                    if (realName.isNotEmpty)
                                      Text(realName,
                                          style: const TextStyle(
                                              color: grey600, fontSize: 12)),
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
                      padding:
                      const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Streams ───────────────────────────────────────────────────────────────
  Stream<Map<String, dynamic>?> _profileStream() {
    if (_isOwnProfile) return AuthService.instance.getUserProfileStream();
    return FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .snapshots()
        .map((doc) => doc.data());
  }

  String _getReputationLabel(int score) {
    if (score >= 150) return 'Community Leader';
    if (score >= 75)  return 'Local Guide';
    if (score >= 25)  return 'Explorer';
    return 'Newcomer';
  }

  Color _getReputationColor(int score) {
    if (score >= 150) return yellow;
    if (score >= 75)  return blue;
    if (score >= 25)  return const Color(0xFF43A047);
    return grey600;
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final currentUid = AuthService.instance.currentUser?.uid;

    return StreamBuilder<Map<String, dynamic>?>(
      stream: _profileStream(),
      builder: (context, snapshot) {
        final profile  = snapshot.data ?? {};
        final username = profile['username']  as String? ?? 'username';
        final realName = profile['realName']  as String? ?? '';
        final pronouns = profile['pronouns']  as String? ?? '';
        final bio      = profile['bio']       as String? ?? '';
        final country  = profile['country']   as String? ?? '';
        final photoUrl = profile['photoUrl']  as String? ?? '';

        final scoreValue = profile['score'];
        final score      = scoreValue is num
            ? scoreValue.toInt()
            : int.tryParse(scoreValue?.toString() ?? '') ?? 0;

        final followers = profile['followers'] ?? 0;
        final following = profile['following'] ?? 0;
        final friends   = profile['friends'] is List
            ? (profile['friends'] as List).length
            : 0;
        final incomingRequests = profile['incomingFriendRequests'] is List
            ? (profile['incomingFriendRequests'] as List).length
            : 0;

        final rawTags = profile['tags'];
        final tags    = rawTags is List
            ? List<String>.from(rawTags)
            : <String>[];

        final reputationLabel = _getReputationLabel(score);
        final reputationColor = _getReputationColor(score);

        return DefaultTabController(
          length: 3,
          child: Scaffold(
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
              bottom: const TabBar(
                labelColor:          blue,
                unselectedLabelColor: grey400,
                indicatorColor:      blue,
                indicatorWeight:     2,
                tabs: [
                  Tab(text: 'Posts'),
                  Tab(text: 'Pins'),
                  Tab(text: 'Saved'),
                ],
              ),
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Avatar + stats ──────────────────────────────────────
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
                            // Name + pronouns row
                            Row(
                              crossAxisAlignment:
                              CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Expanded(
                                  child: Text(
                                    realName.isEmpty
                                        ? 'Add your name'
                                        : realName,
                                    style: TextStyle(
                                      color: realName.isEmpty
                                          ? grey400
                                          : grey900,
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
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: grey100,
                                      borderRadius:
                                      BorderRadius.circular(10),
                                      border:
                                      Border.all(color: grey200),
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
                            // Stats row
                            Row(
                              children: [
                                _StatItem(
                                    value: score.toString(),
                                    label: 'Score'),
                                const SizedBox(width: 16),
                                _StatItem(
                                    value: followers.toString(),
                                    label: 'Followers'),
                                const SizedBox(width: 16),
                                _StatItem(
                                    value: following.toString(),
                                    label: 'Following'),
                                const SizedBox(width: 16),
                                GestureDetector(
                                  onTap: () {
                                    if (currentUid != null) {
                                      _showFriends(
                                          widget.uid ?? currentUid);
                                    }
                                  },
                                  child: _StatItem(
                                      value: friends.toString(),
                                      label: 'Friends'),
                                ),
                              ],
                            ),
                            // Mutual friends (other profiles only)
                            if (!_isOwnProfile &&
                                currentUid != null &&
                                widget.uid != null)
                              FutureBuilder<int>(
                                future: FriendsService.instance
                                    .getMutualFriendsCount(
                                  currentUserId: currentUid,
                                  otherUserId:   widget.uid!,
                                ),
                                builder: (context, snap) {
                                  if (!snap.hasData || snap.data == 0) {
                                    return const SizedBox.shrink();
                                  }
                                  final count = snap.data!;
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: GestureDetector(
                                      onTap: () => _showMutualFriends(
                                        currentUid: currentUid,
                                        otherUid:   widget.uid!,
                                      ),
                                      child: Text(
                                        '$count mutual friend${count == 1 ? '' : 's'}',
                                        style: const TextStyle(
                                          color: grey600,
                                          fontSize: 12,
                                          decoration:
                                          TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            const SizedBox(height: 10),
                            // Reputation badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color:
                                reputationColor.withOpacity(0.12),
                                borderRadius:
                                BorderRadius.circular(999),
                                border: Border.all(
                                    color: reputationColor
                                        .withOpacity(0.28)),
                              ),
                              child: Text(
                                reputationLabel,
                                style: TextStyle(
                                  color: reputationColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Friend request section (other profiles only) ──────────
                if (!_isOwnProfile &&
                    currentUid != null &&
                    widget.uid != null)
                  StreamBuilder<String>(
                    stream: FriendsService.instance.streamRelationshipStatus(
                      currentUserId: currentUid,
                      otherUserId:   widget.uid!,
                    ),
                    builder: (context, snap) {
                      final status = snap.data ?? 'none';
                      return Container(
                        color: white,
                        padding:
                        const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: status == 'incoming'
                            ? Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  try {
                                    await FriendsService.instance
                                        .acceptFriendRequest(
                                      currentUserId: currentUid,
                                      otherUserId:   widget.uid!,
                                    );
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                        content: Text(
                                            'Accepted $username')));
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                        content:
                                        Text(e.toString())));
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: blue,
                                  foregroundColor: white,
                                  padding: const EdgeInsets
                                      .symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(12)),
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
                                      otherUserId:   widget.uid!,
                                    );
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                        content: Text(
                                            'Declined $username')));
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                        content:
                                        Text(e.toString())));
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: grey200,
                                  foregroundColor: grey900,
                                  padding: const EdgeInsets
                                      .symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                child: const Text('Decline'),
                              ),
                            ),
                          ],
                        )
                            : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              try {
                                if (status == 'friends') {
                                  await FriendsService.instance
                                      .removeFriend(
                                    currentUserId: currentUid,
                                    friendUserId:  widget.uid!,
                                  );
                                } else if (status == 'outgoing') {
                                  await FriendsService.instance
                                      .cancelFriendRequest(
                                    currentUserId: currentUid,
                                    otherUserId:   widget.uid!,
                                  );
                                } else {
                                  await FriendsService.instance
                                      .sendFriendRequest(
                                    currentUserId: currentUid,
                                    otherUserId:   widget.uid!,
                                  );
                                }
                                if (!context.mounted) return;
                                final msg = status == 'friends'
                                    ? 'Removed $username'
                                    : status == 'outgoing'
                                    ? 'Cancelled request to $username'
                                    : 'Sent request to $username';
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                    content: Text(msg)));
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                    content:
                                    Text(e.toString())));
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: (status == 'friends' ||
                                  status == 'outgoing')
                                  ? grey200
                                  : blue,
                              foregroundColor: (status == 'friends' ||
                                  status == 'outgoing')
                                  ? grey900
                                  : white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(12)),
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
                      );
                    },
                  ),

                Container(height: 1, color: grey200),

                // ── Bio / tags ────────────────────────────────────────────
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
                                text: country),
                          _MetaChip(
                            icon: Icons.calendar_today_outlined,
                            text:
                            'Joined ${_formatDate(profile['createdAt'])}',
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
                          children: tags
                              .map((t) => _TagChip(label: t))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Own-profile action buttons ────────────────────────────
                if (_isOwnProfile) ...[
                  Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _openEdit(profile),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit Profile'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: blue,
                          side: const BorderSide(color: blue, width: 1.5),
                          padding:
                          const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16),
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
                          padding:
                          const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ] else ...[
                  const SizedBox(height: 24),
                ],

                // ── Tab content ───────────────────────────────────────────
                // Expanded(
                //   child: TabBarView(
                //     physics: const NeverScrollableScrollPhysics(),
                //     children: [
                //       ProfilePostsGrid(
                //         uid: widget.uid ??
                //             AuthService.instance.currentUser!.uid,
                //       ),
                //       ProfilePinsGrid(
                //         uid: widget.uid ??
                //             AuthService.instance.currentUser!.uid,
                //       ),
                //       _isOwnProfile
                //           ? ProfileSavedGrid(
                //         uid: AuthService
                //             .instance.currentUser!.uid,
                //       )
                //           : const Padding(
                //         padding:
                //         EdgeInsets.symmetric(vertical: 48),
                //         child: Center(
                //           child: Text(
                //             'Saved posts are private',
                //             style: TextStyle(
                //                 color: grey400, fontSize: 14),
                //           ),
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
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
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return '';
    }
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

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
            Icon(Icons.settings_outlined,
                color: Color(0xFF212121), size: 16),
            SizedBox(width: 5),
            Text(
              'Settings',
              style: TextStyle(
                  color: Color(0xFF212121),
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
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
    return Container(
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
          placeholder: (_, __) => const Icon(Icons.person,
              size: 40, color: Color(0xFF9E9E9E)),
          errorWidget: (_, __, ___) => const Icon(Icons.person,
              size: 40, color: Color(0xFF9E9E9E)),
        )
            : const Icon(Icons.person,
            size: 40, color: Color(0xFF9E9E9E)),
      ),
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
        Text(value,
            style: const TextStyle(
                color: Color(0xFF212121),
                fontSize: 16,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                color: Color(0xFF757575), fontSize: 11)),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String   text;
  const _MetaChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF9E9E9E)),
        const SizedBox(width: 4),
        Text(text,
            style: const TextStyle(
                color: Color(0xFF757575), fontSize: 12)),
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
            color: const Color(0xFF1E88E5).withOpacity(0.25)),
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