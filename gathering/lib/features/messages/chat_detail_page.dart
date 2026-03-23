import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/chat_service.dart';
import 'models/chat_models.dart';

class ChatDetailPage extends StatefulWidget {
  const ChatDetailPage({
    super.key,
    required this.otherUser,
    this.conversationId,
  });

  final ChatUser otherUser;
  final String? conversationId;

  static const Color blue = Color(0xFF1E88E5);
  static const Color yellow = Color(0xFFFFD600);
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey900 = Color(0xFF212121);

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  ChatUser? _currentUser;
  String? _conversationId;
  bool _isInitializing = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    final currentUser = await ChatService.instance.getCurrentChatUser();
    if (!mounted) {
      return;
    }

    if (currentUser == null) {
      setState(() {
        _isInitializing = false;
      });
      return;
    }

    final conversation = await ChatService.instance.createOrGetConversation(
      currentUser: currentUser,
      otherUser: widget.otherUser,
    );
    await ChatService.instance.markConversationRead(
      conversationId: conversation.id,
      currentUid: currentUser.uid,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _currentUser = currentUser;
      _conversationId = widget.conversationId ?? conversation.id;
      _isInitializing = false;
    });
  }

  Future<void> _sendMessage() async {
    final currentUser = _currentUser;
    final conversationId = _conversationId;
    final text = _messageController.text.trim();

    if (currentUser == null || conversationId == null || text.isEmpty || _isSending) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    HapticFeedback.selectionClick();
    _messageController.clear();

    try {
      await ChatService.instance.sendMessage(
        conversationId: conversationId,
        currentUser: currentUser,
        otherUser: widget.otherUser,
        text: text,
      );
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChatDetailPage.grey50,
      appBar: AppBar(
        backgroundColor: ChatDetailPage.white,
        titleSpacing: 0,
        title: Row(
          children: [
            _UserAvatar(user: widget.otherUser, radius: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser.username,
                    style: const TextStyle(
                      color: ChatDetailPage.grey900,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    widget.otherUser.realName.isNotEmpty
                        ? widget.otherUser.realName
                        : widget.otherUser.email,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ChatDetailPage.grey600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator())
          : _conversationId == null || _currentUser == null
              ? const Center(
                  child: Text(
                    'Unable to open this chat.',
                    style: TextStyle(color: ChatDetailPage.grey600),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              ChatDetailPage.grey50,
                              ChatDetailPage.grey100,
                            ],
                          ),
                        ),
                        child: StreamBuilder<List<ChatMessage>>(
                          stream: ChatService.instance.streamMessages(_conversationId!),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting &&
                                !snapshot.hasData) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            final messages = snapshot.data ?? const <ChatMessage>[];
                            if (messages.isEmpty) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 32),
                                  child: Text(
                                    'Start chatting with ${widget.otherUser.username}.',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: ChatDetailPage.grey600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              );
                            }

                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (_scrollController.hasClients) {
                                _scrollController.jumpTo(
                                  _scrollController.position.maxScrollExtent,
                                );
                              }
                            });

                            return ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final message = messages[index];
                                final isMine = message.senderId == _currentUser!.uid;
                                return Align(
                                  alignment: isMine
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                    constraints: BoxConstraints(
                                      maxWidth: MediaQuery.of(context).size.width * 0.74,
                                    ),
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                                    decoration: BoxDecoration(
                                      color: isMine
                                          ? ChatDetailPage.blue
                                          : ChatDetailPage.white,
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(18),
                                        topRight: const Radius.circular(18),
                                        bottomLeft: Radius.circular(isMine ? 18 : 6),
                                        bottomRight: Radius.circular(isMine ? 6 : 18),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.06),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          message.text,
                                          style: TextStyle(
                                            color: isMine
                                                ? ChatDetailPage.white
                                                : ChatDetailPage.grey900,
                                            fontSize: 15,
                                            height: 1.35,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatTime(message.createdAt),
                                          style: TextStyle(
                                            color: isMine
                                                ? ChatDetailPage.white.withOpacity(0.78)
                                                : ChatDetailPage.grey600,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                        decoration: const BoxDecoration(
                          color: ChatDetailPage.white,
                          border: Border(
                            top: BorderSide(color: ChatDetailPage.grey200),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                minLines: 1,
                                maxLines: 5,
                                textCapitalization: TextCapitalization.sentences,
                                decoration: InputDecoration(
                                  hintText: 'Type a message',
                                  fillColor: ChatDetailPage.grey50,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: const BorderSide(
                                      color: ChatDetailPage.grey200,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: const BorderSide(
                                      color: ChatDetailPage.grey200,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: const BorderSide(
                                      color: ChatDetailPage.blue,
                                      width: 1.4,
                                    ),
                                  ),
                                ),
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Material(
                              color: ChatDetailPage.blue,
                              borderRadius: BorderRadius.circular(999),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(999),
                                onTap: _sendMessage,
                                child: SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: _isSending
                                      ? const Padding(
                                          padding: EdgeInsets.all(12),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              ChatDetailPage.white,
                                            ),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.send_rounded,
                                          color: ChatDetailPage.white,
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.user, required this.radius});

  final ChatUser user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (user.photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(user.photoUrl),
        backgroundColor: ChatDetailPage.grey200,
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: ChatDetailPage.yellow,
      child: Text(
        user.avatarText,
        style: TextStyle(
          color: ChatDetailPage.grey900,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }
}
