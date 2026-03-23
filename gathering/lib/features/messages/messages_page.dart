import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/chat_service.dart';
import 'chat_detail_page.dart';
import 'models/chat_models.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  static const Color blue = Color(0xFF1E88E5);
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey900 = Color(0xFF212121);

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  ChatUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = await ChatService.instance.getCurrentChatUser();
    if (!mounted) {
      return;
    }
    setState(() {
      _currentUser = user;
    });
  }

  Future<void> _openChat(ChatUser user, {String? conversationId}) async {
    HapticFeedback.selectionClick();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatDetailPage(
          otherUser: user,
          conversationId: conversationId,
        ),
      ),
    );
  }

  String _formatConversationTime(DateTime? dateTime) {
    if (dateTime == null) {
      return '';
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final valueDay = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (valueDay == today) {
      final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = dateTime.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    }

    if (valueDay == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }

    return '${dateTime.month}/${dateTime.day}';
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _currentUser;

    return Scaffold(
      backgroundColor: MessagesPage.grey50,
      appBar: AppBar(
        backgroundColor: MessagesPage.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Messages',
          style: TextStyle(
            color: MessagesPage.grey900,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: MessagesPage.grey600),
            onPressed: () async {
              HapticFeedback.selectionClick();
              await AuthService.instance.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/welcome');
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: MessagesPage.grey200),
        ),
      ),
      body: currentUser == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Row(
                    children: [
                      Text(
                        'Recent chats',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: MessagesPage.grey900,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.forum_outlined,
                        color: MessagesPage.blue,
                        size: 20,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<ChatConversation>>(
                    stream: ChatService.instance.streamRecentConversations(currentUser.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final conversations = snapshot.data ?? const <ChatConversation>[];
                      if (conversations.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 56,
                                  color: MessagesPage.grey200,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Use Search to find someone and start your first chat.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: MessagesPage.grey600,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                        itemCount: conversations.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final conversation = conversations[index];
                          final otherUser = conversation.otherParticipant(currentUser.uid);
                          if (otherUser == null) {
                            return const SizedBox.shrink();
                          }

                          final unreadCount = conversation.unreadFor(currentUser.uid);
                          final sentByCurrentUser =
                              conversation.lastMessageSenderId == currentUser.uid;

                          return Material(
                            color: MessagesPage.white,
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => _openChat(
                                otherUser,
                                conversationId: conversation.id,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    _ChatAvatar(user: otherUser, radius: 28),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  otherUser.username,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: MessagesPage.grey900,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                _formatConversationTime(
                                                  conversation.lastMessageAt,
                                                ),
                                                style: TextStyle(
                                                  color: unreadCount > 0
                                                      ? MessagesPage.blue
                                                      : MessagesPage.grey600,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  conversation.lastMessage.isEmpty
                                                      ? 'Tap to start chatting'
                                                      : sentByCurrentUser
                                                          ? 'You: ${conversation.lastMessage}'
                                                          : conversation.lastMessage,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: MessagesPage.grey600,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                              if (unreadCount > 0) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: const BoxDecoration(
                                                    color: MessagesPage.blue,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Text(
                                                    unreadCount.toString(),
                                                    style: const TextStyle(
                                                      color: MessagesPage.white,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar({required this.user, this.radius = 24});

  final ChatUser user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (user.photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(user.photoUrl),
        backgroundColor: MessagesPage.grey200,
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color.fromARGB(255, 220, 248, 94),
      child: Text(
        user.avatarText,
        style: TextStyle(
          color: MessagesPage.grey900,
          fontSize: radius * 0.72,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}