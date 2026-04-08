import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/auth_service.dart';
import 'settings_page.dart';
import 'edit_profile_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../posts/post_bottom_sheet.dart';
import '../posts/create_post_screen.dart'; // for kStockOptions / StockOption

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

  Future<void> _logout() async {
    HapticFeedback.selectionClick();
    await AuthService.instance.logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/welcome');
    }
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

  String _getReputationLabel(int score) {
    if (score >= 150) return 'Community Leader';
    if (score >= 75) return 'Local Guide';
    if (score >= 25) return 'Explorer';
    return 'Newcomer';
  }

  Color _getReputationColor(int score) {
    if (score >= 150) return yellow;
    if (score >= 75) return blue;
    if (score >= 25) return const Color(0xFF43A047);
    return grey600;
  }

  @override
  Widget build(BuildContext context) {
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
        final scoreValue = profile['score'];
        final score = scoreValue is num
            ? scoreValue.toInt()
            : int.tryParse(scoreValue?.toString() ?? '') ?? 0;
        final followers = profile['followers'] ?? 0;
        final following = profile['following'] ?? 0;
        final rawTags = profile['tags'];
        final tags = rawTags is List ? List<String>.from(rawTags) : <String>[];
        final reputationLabel = _getReputationLabel(score);
        final reputationColor = _getReputationColor(score);

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
                              ],
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: reputationColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: reputationColor.withOpacity(0.28),
                                ),
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
                  const SizedBox(height: 24),
                ] else ...[
                  const SizedBox(height: 24),
                ],
                // ── Tab row ────────────────────────────────────────────────────
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

// ── Posts grid ─────────────────────────────────────────────────
                _ProfilePostsGrid(
                  uid: widget.uid ?? AuthService.instance.currentUser?.uid ?? '',
                ),

                const SizedBox(height: 40),
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

// ── Profile posts grid ────────────────────────────────────────────────────────
class _ProfilePostsGrid extends StatelessWidget {
  final String uid;
  const _ProfilePostsGrid({required this.uid});

  static const Color _bg      = Color(0xFF0D0D0D);
  static const Color _surface = Color(0xFF1A1A1A);
  static const Color _grey200 = Color(0xFFEEEEEE);
  static const Color _grey400 = Color(0xFFBDBDBD);

  @override
  Widget build(BuildContext context) {
    if (uid.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Text('No posts yet',
              style: TextStyle(color: _grey400, fontSize: 14)),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.grid_off_outlined, size: 48, color: _grey200),
                  SizedBox(height: 10),
                  Text('No posts yet',
                      style: TextStyle(color: _grey400, fontSize: 14)),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: docs.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 3,
              crossAxisSpacing: 3,
            ),
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final imageUrl = data['imageUrl'] as String? ?? '';
              final postIcon = data['postIcon'] as String?;
              final isRemoved = data['isRemoved'] as bool? ?? false;

              if (isRemoved) {
                return Container(
                  color: _surface,
                  child: const Center(
                    child: Icon(Icons.block,
                        color: Colors.white24, size: 24),
                  ),
                );
              }

              return GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (_) => PostBottomSheet(
                      post: {
                        ...data,
                        'postId': docs[i].id,
                      },
                      postId: docs[i].id,
                    ),
                  );
                },
                child: imageUrl.isNotEmpty
                    ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: _surface,
                    child: const Icon(Icons.broken_image,
                        color: Colors.white24),
                  ),
                )
                    : _StockIconTile(iconLabel: postIcon ?? ''),
              );
            },
          ),
        );
      },
    );
  }
}

class _StockIconTile extends StatelessWidget {
  final String iconLabel;
  const _StockIconTile({required this.iconLabel});

  @override
  Widget build(BuildContext context) {
    final opt = kStockOptions.firstWhere(
          (o) => o.label == iconLabel,
      orElse: () =>
      const StockOption(Icons.photo_camera, Color(0xFF546E7A), 'photo'),
    );
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            opt.color.withOpacity(0.35),
            opt.color.withOpacity(0.10),
          ],
        ),
      ),
      child: Center(
        child: Icon(opt.icon, color: opt.color, size: 32),
      ),
    );
  }
}
