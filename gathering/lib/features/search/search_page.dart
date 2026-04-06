import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/chat_service.dart';
import '../messages/models/chat_models.dart';
import '../profile/user_profile_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  static const Color blue = Color(0xFF1E88E5);
  static const Color yellow = Color(0xFFFFD600);
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey900 = Color(0xFF212121);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  ChatUser? _currentUser;
  List<ChatUser> _results = const <ChatUser>[];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
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

  void _handleSearchChanged(String value) {
    _searchDebounce?.cancel();
    final query = value.trim();

    if (query.isEmpty) {
      setState(() {
        _results = const <ChatUser>[];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    _searchDebounce = Timer(const Duration(milliseconds: 250), () async {
      final currentUser = _currentUser;
      if (currentUser == null) {
        if (mounted) {
          setState(() {
            _isSearching = false;
          });
        }
        return;
      }

      final results = await ChatService.instance.searchUsersByUsername(
        query: query,
        currentUid: currentUser.uid,
      );

      if (!mounted || _searchController.text.trim() != query) {
        return;
      }

      setState(() {
        _results = results;
        _isSearching = false;
      });
    });
  }

  Future<void> _openUserProfile(ChatUser user) async {
    HapticFeedback.selectionClick();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserProfilePage(user: user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _searchController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: SearchPage.grey50,
      appBar: AppBar(
        backgroundColor: SearchPage.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Search',
          style: TextStyle(
            color: SearchPage.grey900,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: SearchPage.grey200),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: SearchPage.white,
                border: Border.all(color: SearchPage.grey200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                autofocus: false,
                onChanged: _handleSearchChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search people by username',
                  hintStyle: const TextStyle(color: SearchPage.grey600, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: SearchPage.blue),
                  suffixIcon: Container(
                    margin: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: SearchPage.yellow,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_search, color: SearchPage.grey900, size: 18),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Text(
              hasQuery ? 'Top 5 closest matches' : 'Find people',
              style: const TextStyle(
                color: SearchPage.grey600,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: _currentUser == null
                ? const Center(child: CircularProgressIndicator())
                : _isSearching
                    ? const Center(child: CircularProgressIndicator())
                    : !hasQuery
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person_search, size: 56, color: SearchPage.grey200),
                                SizedBox(height: 16),
                                Text(
                                  'Search usernames to view profiles and message people.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: SearchPage.grey600,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _results.isEmpty
                            ? const Center(
                                child: Text(
                                  'No users matched that username.',
                                  style: TextStyle(
                                    color: SearchPage.grey600,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                                itemCount: _results.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final user = _results[index];
                                  return Material(
                                    color: SearchPage.white,
                                    borderRadius: BorderRadius.circular(18),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(18),
                                      onTap: () => _openUserProfile(user),
                                      child: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Row(
                                          children: [
                                            _SearchAvatar(user: user),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    user.username,
                                                    style: const TextStyle(
                                                      color: SearchPage.grey900,
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    user.realName.isNotEmpty
                                                        ? user.realName
                                                        : user.email,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      color: SearchPage.grey600,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Icon(
                                              Icons.chevron_right_rounded,
                                              color: SearchPage.grey600,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
          ),
        ],
      ),
    );
  }
}

class _SearchAvatar extends StatelessWidget {
  const _SearchAvatar({required this.user});

  final ChatUser user;

  @override
  Widget build(BuildContext context) {
    if (user.photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 26,
        backgroundImage: NetworkImage(user.photoUrl),
        backgroundColor: SearchPage.grey200,
      );
    }

    return CircleAvatar(
      radius: 26,
      backgroundColor: SearchPage.yellow,
      child: Text(
        user.avatarText,
        style: const TextStyle(
          color: SearchPage.grey900,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
    );
  }
}