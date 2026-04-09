import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/services/chat_service.dart';
import '../messages/chat_detail_page.dart';
import '../messages/models/chat_models.dart';
import '../posts/post_bottom_sheet.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key, required this.user});

  final ChatUser user;

  static const Color blue    = Color(0xFF1E88E5);
  static const Color yellow  = Color(0xFFFFD600);
  static const Color white   = Color(0xFFFFFFFF);
  static const Color grey50  = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey900 = Color(0xFF212121);

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final Stream<QuerySnapshot> _postsStream;

  bool _isOpeningChat = false;
  bool _isFollowing   = false;
  bool _followLoading = true;

  final String _myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _postsStream = FirebaseFirestore.instance
        .collection('posts')
        .where('userId', isEqualTo: widget.user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();

    _checkFollowing();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkFollowing() async {
    if (_myUid.isEmpty) {
      setState(() => _followLoading = false);
      return;
    }
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_myUid)
        .collection('following')
        .doc(widget.user.uid)
        .get();
    if (mounted) {
      setState(() {
        _isFollowing   = doc.exists;
        _followLoading = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    if (_myUid.isEmpty) return;
    HapticFeedback.selectionClick();

    final myRef    = FirebaseFirestore.instance.collection('users').doc(_myUid);
    final theirRef = FirebaseFirestore.instance.collection('users').doc(widget.user.uid);
    final followingRef = myRef.collection('following').doc(widget.user.uid);
    final followerRef  = theirRef.collection('followers').doc(_myUid);

    final batch = FirebaseFirestore.instance.batch();

    if (_isFollowing) {
      batch.delete(followingRef);
      batch.delete(followerRef);
      batch.update(myRef,    {'following': FieldValue.increment(-1)});
      batch.update(theirRef, {'followers': FieldValue.increment(-1)});
      setState(() => _isFollowing = false);
    } else {
      batch.set(followingRef, {'followedAt': FieldValue.serverTimestamp()});
      batch.set(followerRef,  {'followedAt': FieldValue.serverTimestamp()});
      batch.update(myRef,    {'following': FieldValue.increment(1)});
      batch.update(theirRef, {'followers': FieldValue.increment(1)});
      setState(() => _isFollowing = true);
    }

    await batch.commit();
  }

  Future<void> _messageUser() async {
    if (_isOpeningChat) return;
    setState(() => _isOpeningChat = true);
    HapticFeedback.selectionClick();

    try {
      final currentUser = await ChatService.instance.getCurrentChatUser();
      if (!mounted || currentUser == null) return;

      final conversation = await ChatService.instance.createOrGetConversation(
        currentUser: currentUser,
        otherUser: widget.user,
      );

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatDetailPage(
            otherUser: widget.user,
            conversationId: conversation.id,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isOpeningChat = false);
    }
  }

  String _getReputationLabel(int score) {
    if (score >= 150) return 'Community Leader';
    if (score >= 75)  return 'Local Guide';
    if (score >= 25)  return 'Explorer';
    return 'Newcomer';
  }

  Color _getReputationColor(int score) {
    if (score >= 150) return UserProfilePage.yellow;
    if (score >= 75)  return UserProfilePage.blue;
    if (score >= 25)  return const Color(0xFF43A047);
    return UserProfilePage.grey600;
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;

    return Scaffold(
      backgroundColor: UserProfilePage.grey50,
      appBar: AppBar(
        backgroundColor: UserProfilePage.white,
        surfaceTintColor: Colors.transparent,
        title: Text(
          user.username,
          style: const TextStyle(
            color: UserProfilePage.grey900,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: UserProfilePage.grey200),
        ),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Avatar + stats ──────────────────────────────────────
                Container(
                  color: UserProfilePage.white,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PublicAvatar(user: user),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    user.realName.isEmpty ? user.username : user.realName,
                                    style: const TextStyle(
                                      color: UserProfilePage.grey900,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (user.pronouns.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: UserProfilePage.grey100,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: UserProfilePage.grey200),
                                    ),
                                    child: Text(
                                      user.pronouns,
                                      style: const TextStyle(
                                        color: UserProfilePage.grey600,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // ── Live stats from Firestore ──
                            StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .snapshots(),
                              builder: (context, snap) {
                                final data = snap.data?.data()
                                as Map<String, dynamic>? ?? {};
                                final score     = (data['score']     as num?)?.toInt() ?? 0;
                                final followers = (data['followers'] as num?)?.toInt() ?? 0;
                                final following = (data['following'] as num?)?.toInt() ?? 0;
                                final repLabel  = _getReputationLabel(score);
                                final repColor  = _getReputationColor(score);

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        _StatItem(value: '$score',     label: 'Score'),
                                        const SizedBox(width: 20),
                                        _StatItem(value: '$followers', label: 'Followers'),
                                        const SizedBox(width: 20),
                                        _StatItem(value: '$following', label: 'Following'),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: repColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(
                                            color: repColor.withOpacity(0.28)),
                                      ),
                                      child: Text(
                                        repLabel,
                                        style: TextStyle(
                                          color: repColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Container(height: 1, color: UserProfilePage.grey200),

                // ── Bio + tags ───────────────────────────────────────────
                Container(
                  width: double.infinity,
                  color: UserProfilePage.white,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // meta chips
                      Wrap(
                        spacing: 14,
                        runSpacing: 6,
                        children: [
                          if (user.country.isNotEmpty)
                            _MetaChip(
                              icon: Icons.flag_outlined,
                              text: user.country,
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        user.bio.isEmpty ? 'No bio yet.' : user.bio,
                        style: TextStyle(
                          color: user.bio.isEmpty
                              ? UserProfilePage.grey400
                              : UserProfilePage.grey600,
                          fontSize: 13,
                          height: 1.55,
                          fontStyle: user.bio.isEmpty
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                      ),
                      if (user.tags.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: user.tags
                              .map((t) => _TagChip(label: t))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Follow + Message buttons ─────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Follow / Following
                      Expanded(
                        child: _followLoading
                            ? const SizedBox(
                          height: 44,
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: UserProfilePage.blue,
                              ),
                            ),
                          ),
                        )
                            : _isFollowing
                            ? OutlinedButton.icon(
                          onPressed: _toggleFollow,
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Following'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: UserProfilePage.blue,
                            side: const BorderSide(
                                color: UserProfilePage.blue,
                                width: 1.5),
                            padding: const EdgeInsets.symmetric(
                                vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        )
                            : ElevatedButton.icon(
                          onPressed: _toggleFollow,
                          icon: const Icon(
                              Icons.person_add_outlined,
                              size: 16),
                          label: const Text('Follow'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: UserProfilePage.blue,
                            foregroundColor: UserProfilePage.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Message
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _messageUser,
                          icon: _isOpeningChat
                              ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: UserProfilePage.blue,
                            ),
                          )
                              : const Icon(Icons.chat_bubble_outline,
                              size: 16),
                          label: const Text('Message'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: UserProfilePage.blue,
                            side: const BorderSide(
                                color: UserProfilePage.blue, width: 1.5),
                            padding:
                            const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),

          // ── Sticky tab bar ───────────────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyTabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: UserProfilePage.blue,
                unselectedLabelColor: UserProfilePage.grey400,
                indicatorColor: UserProfilePage.blue,
                indicatorWeight: 2,
                tabs: const [
                  Tab(text: 'Posts'),
                  Tab(text: 'About'),
                ],
              ),
            ),
          ),
        ],

        // ── Tab content ──────────────────────────────────────────────────
        body: TabBarView(
          controller: _tabController,
          children: [
            // Posts tab
            _PostsTab(stream: _postsStream),

            // About tab
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (user.country.isNotEmpty) ...[
                    _AboutRow(
                      icon: Icons.flag_outlined,
                      text: user.country,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (user.tags.isNotEmpty) ...[
                    const Text(
                      'Interests',
                      style: TextStyle(
                        color: UserProfilePage.grey900,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: user.tags
                          .map((tag) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: UserProfilePage.grey100,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color: UserProfilePage.grey200),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            color: UserProfilePage.grey900,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Posts tab widget ──────────────────────────────────────────────────────────

class _PostsTab extends StatelessWidget {
  final Stream<QuerySnapshot> stream;
  const _PostsTab({required this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: UserProfilePage.blue),
          );
        }

        final docs = (snapshot.data?.docs ?? [])
            .where((d) {
          final data = d.data() as Map<String, dynamic>;
          return data['isRemoved'] != true;
        })
            .toList();

        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.grid_off_outlined,
                    size: 48, color: UserProfilePage.grey200),
                SizedBox(height: 10),
                Text('No posts yet',
                    style: TextStyle(
                        color: UserProfilePage.grey400, fontSize: 14)),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(2),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final doc      = docs[i];
            final data     = doc.data() as Map<String, dynamic>;
            final imageUrl = data['imageUrl'] as String? ?? '';
            final likes    = (data['likes'] as num?)?.toInt() ?? 0;

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (_) => PostBottomSheet(
                    post: {...data, 'postId': doc.id},
                    postId: doc.id,
                  ),
                );
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  imageUrl.isNotEmpty
                      ? Image.network(imageUrl, fit: BoxFit.cover)
                      : Container(
                      color: const Color(0xFF1A1A1A),
                      child: const Icon(Icons.photo,
                          color: Colors.white24)),
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Row(
                      children: [
                        const Icon(Icons.favorite,
                            color: Colors.white, size: 12),
                        const SizedBox(width: 3),
                        Text(
                          '$likes',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(
                                  color: Colors.black54, blurRadius: 4)
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _StickyTabBarDelegate(this.tabBar);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: UserProfilePage.white,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;
  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  bool shouldRebuild(_StickyTabBarDelegate old) => tabBar != old.tabBar;
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
                color: UserProfilePage.grey900,
                fontSize: 16,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                color: UserProfilePage.grey600, fontSize: 11)),
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
        Icon(icon, size: 13, color: UserProfilePage.grey400),
        const SizedBox(width: 4),
        Text(text,
            style: const TextStyle(
                color: UserProfilePage.grey600, fontSize: 12)),
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
        color: UserProfilePage.blue.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border:
        Border.all(color: UserProfilePage.blue.withOpacity(0.25)),
      ),
      child: Text(label,
          style: const TextStyle(
              color: UserProfilePage.blue,
              fontSize: 12,
              fontWeight: FontWeight.w500)),
    );
  }
}

class _AboutRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _AboutRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: UserProfilePage.grey400),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(
                color: UserProfilePage.grey600, fontSize: 14)),
      ],
    );
  }
}

class _PublicAvatar extends StatelessWidget {
  const _PublicAvatar({required this.user});
  final ChatUser user;

  @override
  Widget build(BuildContext context) {
    if (user.photoUrl.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: user.photoUrl,
          width: 76,
          height: 76,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
              width: 76,
              height: 76,
              color: UserProfilePage.grey100),
          errorWidget: (_, __, ___) => _FallbackAvatar(user: user),
        ),
      );
    }
    return _FallbackAvatar(user: user);
  }
}

class _FallbackAvatar extends StatelessWidget {
  const _FallbackAvatar({required this.user});
  final ChatUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      decoration: const BoxDecoration(
        color: UserProfilePage.yellow,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        user.avatarText,
        style: const TextStyle(
          color: UserProfilePage.grey900,
          fontSize: 28,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}