import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'edit_profile_page.dart';
import '../../core/services/auth_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // ── Palette ───────────────────────────────────────────────────────────────
  static const Color blue    = Color(0xFF1E88E5);
  static const Color yellow  = Color(0xFFFFD600);
  static const Color white   = Color(0xFFFFFFFF);
  static const Color grey50  = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey900 = Color(0xFF212121);

  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  Future<void> _handleSettingTap(String title) async {
    HapticFeedback.selectionClick();

    switch (title) {
      case 'Edit Profile':
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );

        final data = await AuthService.instance.getUserProfile();

        Navigator.pop(context);

        if (data == null) return;

        final updated = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EditProfilePage(initialData: data),
          ),
        );

        if (updated == true) {
          setState(() {});
        }
        break;

      case 'Change Password':
        final email = AuthService.instance.currentUser?.email;
        if (email == null) {
          _showWIP('Error: no email found for this account');
          return;
        }

        final error = await AuthService.instance.sendPasswordReset(email);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Password reset email sent!'),
            backgroundColor: error != null ? Colors.red : Colors.green,
          ),
        );
        break;

      default:
        _showWIP(title);
    }
  }

  // Show a WIP
  void _showWIP(String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: const Text('This feature is still in development.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ── Placeholder settings data ─────────────────────────────────────────────
  static const List<Map<String, dynamic>> _allSettings = [
    // Account
    {
      'section': 'Account',
      'title': 'Edit Profile',
      'subtitle': 'Change your name, bio, and photo',
      'icon': Icons.person_outline,
    },
    {
      'section': 'Account',
      'title': 'Change Password',
      'subtitle': 'Update your login credentials',
      'icon': Icons.lock_outline,
    },
    {
      'section': 'Account',
      'title': 'Linked Accounts',
      'subtitle': 'Manage connected social accounts',
      'icon': Icons.link,
    },
    // Privacy
    {
      'section': 'Privacy',
      'title': 'Profile Visibility',
      'subtitle': 'Control who can see your profile',
      'icon': Icons.visibility_outlined,
    },
    {
      'section': 'Privacy',
      'title': 'Location Sharing',
      'subtitle': 'Manage how your location is shared',
      'icon': Icons.location_on_outlined,
    },
    {
      'section': 'Privacy',
      'title': 'Blocked Users',
      'subtitle': 'View and manage blocked accounts',
      'icon': Icons.block,
    },
    // Notifications
    {
      'section': 'Notifications',
      'title': 'Push Notifications',
      'subtitle': 'Alerts, mentions and activity',
      'icon': Icons.notifications_outlined,
    },
    {
      'section': 'Notifications',
      'title': 'Email Notifications',
      'subtitle': 'Weekly digest and important updates',
      'icon': Icons.email_outlined,
    },
    // Map
    {
      'section': 'Map',
      'title': 'Default Map Style',
      'subtitle': 'Streets, satellite or terrain',
      'icon': Icons.map_outlined,
    },
    {
      'section': 'Map',
      'title': 'Marker Preferences',
      'subtitle': 'Customize pin colours and icons',
      'icon': Icons.place_outlined,
    },
    // App
    {
      'section': 'App',
      'title': 'Language',
      'subtitle': 'English (Canada)',
      'icon': Icons.language,
    },
    {
      'section': 'App',
      'title': 'Theme',
      'subtitle': 'Light, dark or system default',
      'icon': Icons.palette_outlined,
    },
    {
      'section': 'App',
      'title': 'Data & Storage',
      'subtitle': 'Cache, offline maps and usage',
      'icon': Icons.storage_outlined,
    },
    // Support
    {
      'section': 'Support',
      'title': 'Help Centre',
      'subtitle': 'FAQs, guides and contact',
      'icon': Icons.help_outline,
    },
    {
      'section': 'Support',
      'title': 'Report a Problem',
      'subtitle': 'Let us know what went wrong',
      'icon': Icons.bug_report_outlined,
    },
    {
      'section': 'Support',
      'title': 'About Local Link',
      'subtitle': 'Version, licences and legal',
      'icon': Icons.info_outline,
    },
  ];

  List<Map<String, dynamic>> get _filtered {
    if (_query.isEmpty) return _allSettings;
    final q = _query.toLowerCase();
    return _allSettings.where((s) {
      return (s['title'] as String).toLowerCase().contains(q) ||
          (s['subtitle'] as String).toLowerCase().contains(q) ||
          (s['section'] as String).toLowerCase().contains(q);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    // Group into sections (preserves order, respects search filter)
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final item in filtered) {
      final section = item['section'] as String;
      grouped.putIfAbsent(section, () => []).add(item);
    }

    return Scaffold(
      backgroundColor: grey50,

      // ── App bar ─────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: _SearchBar(
          controller: _searchController,
          onChanged: (v) => setState(() => _query = v),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: grey100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: grey200),
                ),
                child: const Icon(Icons.close, color: grey900, size: 22),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: grey200),
        ),
      ),

      // ── Scrollable settings list ─────────────────────────────────────────
      body: filtered.isEmpty
          ? _emptyState()
          : ListView(
        padding: const EdgeInsets.only(top: 12, bottom: 40),
        children: [
          for (final section in grouped.keys) ...[
            _SectionHeader(title: section),
            for (final item in grouped[section]!)
              _SettingsTile(
                icon: item['icon'] as IconData,
                title: item['title'] as String,
                subtitle: item['subtitle'] as String,
                onTap: () => _handleSettingTap(item['title']),
              ),
            const SizedBox(height: 8),
          ],
          // ── LOGOUT TILE ───────────────────────────────────────────────
          const SizedBox(height: 12), // space above logout
          _SettingsTile(
            icon: Icons.logout,
            title: 'Log Out',
            subtitle: 'Sign out of your account',
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm Logout'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Log Out', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await AuthService.instance.logout();
                if (!mounted) return;
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, size: 52, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 14),
          Text(
            'No settings match "$_query"',
            style: const TextStyle(color: Color(0xFF757575), fontSize: 15),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search bar widget
// ─────────────────────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14, color: Color(0xFF212121)),
        decoration: InputDecoration(
          hintText: 'Search settings…',
          hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF1E88E5), size: 20),
          suffixIcon: controller.text.isNotEmpty
              ? GestureDetector(
            onTap: () {
              controller.clear();
              onChanged('');
            },
            child: const Icon(Icons.clear, color: Color(0xFF9E9E9E), size: 18),
          )
              : null,
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 1.5),
          ),
        ),
      ),
    );

  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF1E88E5),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual settings tile
// ─────────────────────────────────────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap; // add this

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap, // add this
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap, // use it here
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E88E5).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: const Color(0xFF1E88E5), size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                            color: Color(0xFF212121),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          )),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: const TextStyle(
                            color: Color(0xFF757575),
                            fontSize: 12,
                          )),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: Color(0xFFBDBDBD), size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}