import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/friends_service.dart';
import '../../core/services/chat_service.dart';
import '../messages/chat_detail_page.dart';
import '../messages/models/chat_models.dart';
import 'settings_page.dart';
import 'edit_profile_page.dart';
import '../friends/friends_page.dart';
import 'profile_pins_grid.dart';
import 'profile_saved_grid.dart';
import 'profile_posts_grid.dart';

class ProfilePage extends StatefulWidget {
  final String? uid;
  const ProfilePage({super.key, this.uid});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Palette
  static const Color blue    = Color(0xFF1E88E5);
  static const Color yellow  = Color(0xFFFFD600);
  static const Color white   = Color(0xFFFFFFFF);
  static const Color grey50  = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey900 = Color(0xFF212121);

  bool _isOpeningChat = false;

  bool get _isOwnProfile {
    final currentUid = AuthService.instance.currentUser?.uid;
    return widget.uid == null || widget.uid == currentUid;
  }

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
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const FriendsPage()));
  }

  Future<void> _messageUser({
    required String otherUid,
    required String email,
    required String username,
    required String realName,
    required String photoUrl,
    required String pronouns,
    required String bio,
    required String country,
    required List<String> tags,
  }) async {
    if (_isOpeningChat) return;

    setState(() => _isOpeningChat = true);
    HapticFeedback.selectionClick();

    try {
      final currentUser = await ChatService.instance.getCurrentChatUser();
      if (!mounted || currentUser == null) return;

      final otherUser = ChatUser(
        uid: otherUid,
        email: email,
        username: username,
        realName: realName,
        photoUrl: photoUrl,
        pronouns: pronouns,
        bio: bio,
        country: country,
        tags: tags,
      );

      final conversation = await ChatService.instance.createOrGetConversation(
        currentUser: currentUser,
        otherUser: otherUser,
      );

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatDetailPage(
            otherUser: otherUser,
            conversationId: conversation.id,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isOpeningChat = false);
      }
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final currentUid = AuthService.instance.currentUser?.uid;

    return StreamBuilder<Map<String, dynamic>?>(
      stream: _profileStream(),
      builder: (context, snapshot) {
        final profile  = snapshot.data ?? {};
        final username = profile['username'] ?? 'username';
        final realName = profile['realName'] ?? '';
        final pronouns = profile['pronouns'] ?? '';
        final bio      = profile['bio'] ?? '';
        final country  = profile['country'] ?? '';
        final photoUrl = profile['photoUrl'] ?? '';
        final email = profile['email'] ?? '';
        final scoreValue = profile['score'];
        final score = scoreValue is num
            ? scoreValue.toInt()
            : int.tryParse(scoreValue?.toString() ?? '') ?? 0;
        final friends = profile['friends'] is List
            ? (profile['friends'] as List).length
            : 0;
        final incomingRequests = profile['incomingFriendRequests'] is List
            ? (profile['incomingFriendRequests'] as List).length
            : 0;
        final rawTags = profile['tags'];
        final tags    = rawTags is List ? List<String>.from(rawTags) : <String>[];
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
                    fontSize: 20),
              ),
              actions: [
                if (_isOwnProfile)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _SettingsButton(onTap: _openSettings),
                  ),
              ],
              bottom: const TabBar(
                labelColor: blue,
                unselectedLabelColor: grey400,
                indicatorColor: blue,
                indicatorWeight: 2,
                tabs: [
                  Tab(text: 'Posts'),
                  Tab(text: 'Pins'),
                  Tab(text: 'Saved'),
                ],
              ),
            ),
            body: Column(
              children: [
                // Avatar + Stats
                Container(
                  color: white,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Avatar(photoUrl: photoUrl),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Name + pronouns inline
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  children: [
                                    Text(
                                      realName.isEmpty ? 'Add your name' : realName,
                                      style: TextStyle(
                                        color: realName.isEmpty ? grey400 : grey900,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        fontStyle: realName.isEmpty
                                            ? FontStyle.italic
                                            : FontStyle.normal,
                                      ),
                                    ),
                                    if (pronouns.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: grey100,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: grey200),
                                        ),
                                        child: Text(
                                          pronouns,
                                          style: const TextStyle(
                                              color: grey600, fontSize: 11),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Stats + badge inline
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 16,
                                  runSpacing: 6,
                                  children: [
                                    _StatItem(value: score.toString(), label: 'Score'),
                                    GestureDetector(
                                      onTap: _isOwnProfile ? _openFriends : null,
                                      child: _StatItem(
                                          value: friends.toString(), label: 'Friends'),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: reputationColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(
                                            color: reputationColor.withOpacity(0.28)),
                                      ),
                                      child: Text(
                                        reputationLabel,
                                        style: TextStyle(
                                          color: reputationColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                // Bio
                                Text(
                                  bio.isNotEmpty
                                      ? bio
                                      : _isOwnProfile
                                          ? 'No bio yet — tap Edit Profile to add one.'
                                          : 'No bio yet.',
                                  style: TextStyle(
                                      color: bio.isNotEmpty ? grey900 : grey400,
                                    fontStyle: bio.isNotEmpty
                                        ? FontStyle.normal
                                        : FontStyle.italic,
                                    fontSize: 13,
                                      height: 1.45),
                                ),
                                if (tags.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children:
                                      tags.map((t) => _TagChip(label: t)).toList(),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Own profile buttons
                if (_isOwnProfile)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _openEdit(profile),
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text('Edit Profile'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: blue,
                              side: const BorderSide(color: blue, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
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
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (currentUid != null && widget.uid != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: StreamBuilder<String>(
                      stream: FriendsService.instance.streamRelationshipStatus(
                        currentUserId: currentUid,
                        otherUserId: widget.uid!,
                      ),
                      builder: (context, snapshot) {
                        final status = snapshot.data ?? 'none';

                        String friendLabel;
                        IconData friendIcon;

                        if (status == 'friends') {
                          friendLabel = 'Friends';
                          friendIcon = Icons.check;
                        } else if (status == 'outgoing') {
                          friendLabel = 'Requested';
                          friendIcon = Icons.schedule;
                        } else if (status == 'incoming') {
                          friendLabel = 'Accept';
                          friendIcon = Icons.person_add_alt_1;
                        } else {
                          friendLabel = 'Add Friend';
                          friendIcon = Icons.person_add_alt_1;
                        }

                        return Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
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
                                    } else if (status == 'incoming') {
                                      await FriendsService.instance
                                          .acceptFriendRequest(
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

                                    if (!mounted) return;

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          status == 'friends'
                                              ? 'Removed friend'
                                              : status == 'outgoing'
                                                  ? 'Friend request cancelled'
                                                  : status == 'incoming'
                                                      ? 'Friend request accepted'
                                                      : 'Friend request sent',
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString())),
                                    );
                                  }
                                },
                                icon: Icon(friendIcon, size: 16),
                                label: Text(friendLabel),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: blue,
                                  side: const BorderSide(
                                    color: blue,
                                    width: 1.5,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isOpeningChat
                                    ? null
                                    : () {
                                        _messageUser(
                                          otherUid: widget.uid!,
                                          email: email,
                                          username: username,
                                          realName: realName,
                                          photoUrl: photoUrl,
                                          pronouns: pronouns,
                                          bio: bio,
                                          country: country,
                                          tags: tags,
                                        );
                                      },
                                icon: _isOpeningChat
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.chat_bubble_outline,
                                        size: 16,
                                      ),
                                label: const Text('Message'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: blue,
                                  foregroundColor: white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 8),

                // Tabs content fills remaining space
                Expanded(
                  child: TabBarView(
                    children: [
                      ProfilePostsGrid(uid: widget.uid ?? currentUid!),
                      ProfilePinsGrid(uid: widget.uid ?? currentUid!),
                      _isOwnProfile
                          ? ProfileSavedGrid(uid: currentUid!)
                          : const Center(child: Text('Saved posts are private')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Helper widgets

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
            Icon(Icons.settings_outlined, color: Color(0xFF212121), size: 16),
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
          placeholder: (_, __) =>
          const Icon(Icons.person, size: 40, color: Color(0xFF9E9E9E)),
          errorWidget: (_, __, ___) =>
          const Icon(Icons.person, size: 40, color: Color(0xFF9E9E9E)),
              )
            : const Icon(Icons.person, size: 40, color: Color(0xFF9E9E9E)),
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
            style: const TextStyle(color: Color(0xFF757575), fontSize: 11)),
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
        border: Border.all(color: const Color(0xFF1E88E5).withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF1E88E5),
          fontSize: 12,
            fontWeight: FontWeight.w500),
      ),
    );
  }
}