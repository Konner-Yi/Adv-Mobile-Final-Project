import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/chat_service.dart';
import '../messages/chat_detail_page.dart';
import '../messages/models/chat_models.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key, required this.user});

  final ChatUser user;

  static const Color blue = Color(0xFF1E88E5);
  static const Color yellow = Color(0xFFFFD600);
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey900 = Color(0xFF212121);

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool _isOpeningChat = false;

  Future<void> _messageUser() async {
    if (_isOpeningChat) {
      return;
    }

    setState(() {
      _isOpeningChat = true;
    });

    HapticFeedback.selectionClick();

    try {
      final currentUser = await ChatService.instance.getCurrentChatUser();
      if (!mounted || currentUser == null) {
        return;
      }

      final conversation = await ChatService.instance.createOrGetConversation(
        currentUser: currentUser,
        otherUser: widget.user,
      );

      if (!mounted) {
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatDetailPage(
            otherUser: widget.user,
            conversationId: conversation.id,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isOpeningChat = false;
        });
      }
    }
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (user.pronouns.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                        const SizedBox(height: 6),
                        Text(
                          '@${user.username}',
                          style: const TextStyle(
                            color: UserProfilePage.grey600,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (user.country.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.flag_outlined, size: 16, color: UserProfilePage.grey600),
                              const SizedBox(width: 6),
                              Text(
                                user.country,
                                style: const TextStyle(
                                  color: UserProfilePage.grey600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: UserProfilePage.grey200),
            Container(
              width: double.infinity,
              color: UserProfilePage.white,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About',
                    style: TextStyle(
                      color: UserProfilePage.grey900,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user.bio.isEmpty ? 'No bio added yet.' : user.bio,
                    style: TextStyle(
                      color: user.bio.isEmpty
                          ? UserProfilePage.grey400
                          : UserProfilePage.grey600,
                      fontSize: 14,
                      height: 1.5,
                      fontStyle: user.bio.isEmpty ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                  if (user.tags.isNotEmpty) ...[
                    const SizedBox(height: 16),
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
                          .map(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: UserProfilePage.grey100,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: UserProfilePage.grey200),
                              ),
                              child: Text(
                                tag,
                                style: const TextStyle(
                                  color: UserProfilePage.grey900,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _messageUser,
                  icon: _isOpeningChat
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(UserProfilePage.white),
                          ),
                        )
                      : const Icon(Icons.chat_bubble_outline),
                  label: const Text('Message'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: UserProfilePage.blue,
                    foregroundColor: UserProfilePage.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PublicAvatar extends StatelessWidget {
  const _PublicAvatar({required this.user});

  final ChatUser user;

  @override
  Widget build(BuildContext context) {
    if (user.photoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: CachedNetworkImage(
          imageUrl: user.photoUrl,
          width: 92,
          height: 92,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            width: 92,
            height: 92,
            color: UserProfilePage.grey100,
          ),
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
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        color: UserProfilePage.yellow,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: Text(
        user.avatarText,
        style: const TextStyle(
          color: UserProfilePage.grey900,
          fontSize: 32,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}