// // import 'package:flutter/material.dart';
// // import 'package:flutter/services.dart';
// // import '../../core/services/auth_database.dart';
// //
// // class ProfilePage extends StatelessWidget {
// //   const ProfilePage({super.key});
// //
// //   static const Color cyan = Color(0xFF00E5FF);
// //   static const Color indigo = Color(0xFF3949AB);
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: Colors.transparent,
// //
// //       appBar: AppBar(
// //         backgroundColor: indigo,
// //         elevation: 0,
// //         title: const Text(
// //           'Profile',
// //           style: TextStyle(
// //             color: cyan,
// //             fontWeight: FontWeight.bold,
// //           ),
// //         ),
// //         actions: [
// //           IconButton(
// //             icon: const Icon(Icons.logout, color: cyan),
// //             onPressed: () async {
// //               HapticFeedback.selectionClick();
// //               await AuthDatabase().logout();
// //               if (context.mounted) {
// //                 Navigator.pushReplacementNamed(context, '/login');
// //               }
// //             },
// //           ),
// //         ],
// //       ),
// //
// //       body: Container(
// //         decoration: const BoxDecoration(
// //           gradient: LinearGradient(
// //             begin: Alignment.topCenter,
// //             end: Alignment.bottomCenter,
// //             colors: [
// //               Color(0xFF5C6BC0),
// //               Color(0xFF5C6BC0),
// //             ],
// //           ),
// //         ),
// //         child: const Center(
// //           child: Text(
// //             'User profile will go here',
// //             style: TextStyle(
// //               color: Colors.white,
// //               fontSize: 18,
// //               fontWeight: FontWeight.w600,
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
//
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import '../../core/services/auth_database.dart';
//
// class ProfilePage extends StatelessWidget {
//   const ProfilePage({super.key});
//
//   static const Color blue    = Color(0xFF1E88E5);
//   static const Color yellow  = Color(0xFFFFD600);
//   static const Color white   = Color(0xFFFFFFFF);
//   static const Color grey50  = Color(0xFFFAFAFA);
//   static const Color grey200 = Color(0xFFEEEEEE);
//   static const Color grey600 = Color(0xFF757575);
//   static const Color grey900 = Color(0xFF212121);
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: grey50,
//
//       appBar: AppBar(
//         backgroundColor: white,
//         elevation: 0,
//         surfaceTintColor: Colors.transparent,
//         title: const Text(
//           'Profile',
//           style: TextStyle(
//             color: grey900,
//             fontWeight: FontWeight.bold,
//             fontSize: 20,
//           ),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.settings_outlined, color: grey600),
//             onPressed: () {},
//           ),
//           IconButton(
//             icon: const Icon(Icons.logout_outlined, color: grey600),
//             onPressed: () async {
//               HapticFeedback.selectionClick();
//               await AuthDatabase().logout();
//               if (context.mounted) {
//                 Navigator.pushReplacementNamed(context, '/login');
//               }
//             },
//           ),
//         ],
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(1),
//           child: Container(height: 1, color: grey200),
//         ),
//       ),
//
//       body: const Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             CircleAvatar(
//               radius: 40,
//               backgroundColor: grey200,
//               child: Icon(Icons.person, size: 44, color: grey600),
//             ),
//             SizedBox(height: 16),
//             Text(
//               'User profile will go here',
//               style: TextStyle(
//                 color: grey600,
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/auth_database.dart';
import 'settings_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

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

  void _openSettings() {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsPage()),
    );
  }

  Future<void> _logout() async {
    HapticFeedback.selectionClick();
    await AuthDatabase().logout();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: grey50,

      // ── App bar: username left, Settings button right ──────────────────
      appBar: AppBar(
        backgroundColor: white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 20,
        title: const Text(
          'username',
          style: TextStyle(
            color: grey900,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 0.2,
          ),
        ),
        actions: [
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

            // ── Header card: avatar + name + stats ────────────────────────
            Container(
              color: white,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  _Avatar(),
                  const SizedBox(width: 20),

                  // Name, pronouns & stat row
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Real name + pronouns
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            const Expanded(
                              child: Text(
                                'Real Name',
                                style: TextStyle(
                                  color: grey900,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: grey100,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: grey200),
                              ),
                              child: const Text(
                                'they/them',
                                style: TextStyle(
                                  color: grey600,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Stats row
                        Row(
                          children: const [
                            _StatItem(value: '0', label: 'Score'),
                            SizedBox(width: 20),
                            _StatItem(value: '0', label: 'Followers'),
                            SizedBox(width: 20),
                            _StatItem(value: '0', label: 'Following'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Thin divider
            Container(height: 1, color: grey200),

            // ── Bio / info card ───────────────────────────────────────────
            Container(
              color: white,
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meta row: joined · country · tags
                  Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    children: const [
                      _MetaChip(
                        icon: Icons.calendar_today_outlined,
                        text: 'Joined January 2025',
                      ),
                      _MetaChip(
                        icon: Icons.flag_outlined,
                        text: 'Canada',
                      ),
                      _MetaChip(
                        icon: Icons.tag,
                        text: 'adventure · maps · local',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Description
                  const Text(
                    'This is a placeholder bio. The user can write a short description about themselves here — where they\'re from, what they like to explore, or anything else they want to share with the community.',
                    style: TextStyle(
                      color: grey600,
                      fontSize: 13,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Edit profile button ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => HapticFeedback.selectionClick(),
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

            // ── Posts / activity placeholder ──────────────────────────────
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
            Container(height: 2, color: blue, margin: const EdgeInsets.only(left: 20, right: 20)),
            const SizedBox(height: 16),

            // Empty state
            Center(
              child: Column(
                children: [
                  const Icon(Icons.grid_off_outlined, size: 48, color: grey200),
                  const SizedBox(height: 10),
                  const Text(
                    'No posts yet',
                    style: TextStyle(color: grey400, fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // ── Log out ───────────────────────────────────────────────────
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
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Settings button (top-right of app bar)
// ─────────────────────────────────────────────────────────────────────────────
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.settings_outlined,
                color: Color(0xFF212121), size: 16),
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

// ─────────────────────────────────────────────────────────────────────────────
// Avatar circle
// ─────────────────────────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 76,
          height: 76,
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
          child: const Icon(
            Icons.person,
            size: 40,
            color: Color(0xFF9E9E9E),
          ),
        ),
        // Camera badge
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFF1E88E5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.camera_alt_outlined,
              color: Colors.white,
              size: 13,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat item (Score / Followers / Following)
// ─────────────────────────────────────────────────────────────────────────────
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
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Meta chip (joined / country / tags row)
// ─────────────────────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────────────
// Tab label (Posts / Pins / Saved)
// ─────────────────────────────────────────────────────────────────────────────
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