import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'moderation_service.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  static const Color _bg = Color(0xFF0D0D0D);
  static const Color _surface = Color(0xFF1A1A1A);
  static const Color _accent = Color(0xFF1E88E5);

  final ModerationService _moderationService = ModerationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Blocked Users'),
      ),
      body: FutureBuilder<List<String>>(
        future: _moderationService.getBlockedUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _accent),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.done_all,
                    size: 64,
                    color: Colors.white30,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No blocked users',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          final blockedUserIds = snapshot.data!;

          return ListView.builder(
            itemCount: blockedUserIds.length,
            itemBuilder: (context, index) {
              final userId = blockedUserIds[index];
              return _BlockedUserTile(
                userId: userId,
                onUnblock: () {
                  _moderationService.unblockUser(userId);
                  setState(() {});
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _BlockedUserTile extends StatelessWidget {
  final String userId;
  final VoidCallback onUnblock;

  static const Color _surface = Color(0xFF1A1A1A);
  static const Color _accent = Color(0xFF1E88E5);

  const _BlockedUserTile({
    required this.userId,
    required this.onUnblock,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        String username = 'Unknown User';
        String avatarUrl = '';

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          username = data['displayName'] ?? 'Unknown User';
          avatarUrl = data['avatarUrl'] ?? '';
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: _accent.withOpacity(0.2),
                backgroundImage:
                    avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                child: avatarUrl.isEmpty
                    ? const Icon(Icons.person, color: Colors.white54)
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
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Blocked',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: onUnblock,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent.withOpacity(0.1),
                  foregroundColor: _accent,
                ),
                child: const Text('Unblock'),
              ),
            ],
          ),
        );
      },
    );
  }
}
