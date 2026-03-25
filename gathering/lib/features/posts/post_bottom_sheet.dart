import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostBottomSheet extends StatefulWidget {
  final Map<String, dynamic> post;
  final String postId;

  const PostBottomSheet({
    super.key,
    required this.post,
    required this.postId,
  });

  @override
  State<PostBottomSheet> createState() => _PostBottomSheetState();
}

class _PostBottomSheetState extends State<PostBottomSheet> {
  static const Color _bg      = Color(0xFF0D0D0D);
  static const Color _surface = Color(0xFF1A1A1A);
  static const Color _accent  = Color(0xFF1E88E5);
  static const Color _yellow  = Color(0xFFFFD600);

  bool _liked    = false;
  bool _reposted = false;

  final String _uid      = FirebaseAuth.instance.currentUser?.uid ?? '';
  final bool   _isGuest  = FirebaseAuth.instance.currentUser == null;

  @override
  void initState() {
    super.initState();
    if (!_isGuest) {
      _checkIfLiked();
      _checkIfReposted();
    }
  }

  Future<void> _checkIfLiked() async {
    final doc = await FirebaseFirestore.instance
        .collection('posts').doc(widget.postId)
        .collection('likedBy').doc(_uid)
        .get();
    if (mounted) setState(() => _liked = doc.exists);
  }

  Future<void> _checkIfReposted() async {
    final doc = await FirebaseFirestore.instance
        .collection('posts').doc(widget.postId)
        .collection('repostedBy').doc(_uid)
        .get();
    if (mounted) setState(() => _reposted = doc.exists);
  }

  // ── Like toggle ────────────────────────────────────────
  Future<void> _toggleLike() async {
    if (_isGuest) { _snackLoginRequired(); return; }
    HapticFeedback.lightImpact();

    final ref = FirebaseFirestore.instance
        .collection('posts').doc(widget.postId);

    if (_liked) {
      await ref.update({'likes': FieldValue.increment(-1)});
      await ref.collection('likedBy').doc(_uid).delete();
      setState(() => _liked = false);
    } else {
      await ref.update({'likes': FieldValue.increment(1)});
      await ref.collection('likedBy').doc(_uid)
          .set({'likedAt': FieldValue.serverTimestamp()});
      setState(() => _liked = true);
    }
  }

  // ── Repost toggle (per-user tracked) ──────────────────
  Future<void> _toggleRepost() async {
    if (_isGuest) { _snackLoginRequired(); return; }
    HapticFeedback.lightImpact();

    final ref = FirebaseFirestore.instance
        .collection('posts').doc(widget.postId);

    if (_reposted) {
      await ref.update({'reposts': FieldValue.increment(-1)});
      await ref.collection('repostedBy').doc(_uid).delete();
      setState(() => _reposted = false);
    } else {
      await ref.update({'reposts': FieldValue.increment(1)});
      await ref.collection('repostedBy').doc(_uid)
          .set({'repostedAt': FieldValue.serverTimestamp()});
      setState(() => _reposted = true);
    }
  }

  void _openComments() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CommentsSheet(postId: widget.postId),
    );
  }

  void _snackLoginRequired() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sign in to interact with posts.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post       = widget.post;
    final avatarUrl  = post['avatarUrl'] as String? ?? '';
    final username   = post['username']  as String? ?? 'Anonymous';
    final imageUrl   = post['imageUrl']  as String? ?? '';
    final caption    = post['caption']   as String? ?? '';

    return Container(
      decoration: const BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ──
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── Header ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _surface,
                  backgroundImage: avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl.isEmpty
                      ? const Icon(Icons.person, color: Colors.white54)
                      : null,
                ),
                const SizedBox(width: 10),
                Text(
                  username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),

          // ── Image ──
          if (imageUrl.isNotEmpty)
            Image.network(
              imageUrl,
              width: double.infinity,
              height: 320,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : Container(
                height: 320, color: _surface,
                child: const Center(
                  child: CircularProgressIndicator(color: _accent),
                ),
              ),
            ),

          // ── Live action bar (StreamBuilder for real-time counts) ──
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('posts')
                .doc(widget.postId)
                .snapshots(),
            builder: (context, snapshot) {
              final data = snapshot.data?.data() as Map<String, dynamic>?;
              final likes    = data?['likes']    ?? 0;
              final comments = data?['comments'] ?? 0;
              final reposts  = data?['reposts']  ?? 0;

              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    // Like
                    _ActionButton(
                      icon: _liked
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: _liked ? Colors.redAccent : Colors.white70,
                      count: likes,
                      onTap: _toggleLike,
                    ),
                    const SizedBox(width: 4),
                    // Comment
                    _ActionButton(
                      icon: Icons.chat_bubble_outline,
                      color: Colors.white70,
                      count: comments,
                      onTap: _openComments,
                    ),
                    const SizedBox(width: 4),
                    // Repost
                    _ActionButton(
                      icon: Icons.repeat,
                      color: _reposted ? _yellow : Colors.white70,
                      count: reposts,
                      onTap: _toggleRepost,
                    ),
                  ],
                ),
              );
            },
          ),

          // ── Caption ──
          if (caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$username ',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      TextSpan(
                        text: caption,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

// ── Action button ──────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int count;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(width: 5),
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Comments sheet ─────────────────────────────────────────────────────────
class _CommentsSheet extends StatefulWidget {
  final String postId;
  const _CommentsSheet({required this.postId});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  static const Color _bg      = Color(0xFF0D0D0D);
  static const Color _surface = Color(0xFF1A1A1A);
  static const Color _accent  = Color(0xFF1E88E5);

  final _commentController = TextEditingController();
  bool   _sending          = false;
  String? _replyToId;
  String? _replyToUsername;

  final String? _uid      = FirebaseAuth.instance.currentUser?.uid;
  final String? _username = FirebaseAuth.instance.currentUser?.displayName;
  final bool    _isGuest  = FirebaseAuth.instance.currentUser == null;

  void _setReply(String commentId, String username) {
    setState(() {
      _replyToId       = commentId;
      _replyToUsername = username;
    });
    // Focus the text field
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _clearReply() {
    setState(() {
      _replyToId       = null;
      _replyToUsername = null;
    });
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isGuest) return;

    setState(() => _sending = true);

    final user = FirebaseAuth.instance.currentUser!;
    final batch = FirebaseFirestore.instance.batch();

    final commentRef = FirebaseFirestore.instance
        .collection('posts').doc(widget.postId)
        .collection('comments').doc();

    batch.set(commentRef, {
      'userId':      user.uid,
      'username':    user.displayName ?? 'Anonymous',
      'avatarUrl':   user.photoURL ?? '',
      'text':        text,
      'replyToId':   _replyToId,   // null if top-level comment
      'createdAt':   FieldValue.serverTimestamp(),
    });

    // Increment comment count
    batch.update(
      FirebaseFirestore.instance.collection('posts').doc(widget.postId),
      {'comments': FieldValue.increment(1)},
    );

    await batch.commit();

    _commentController.clear();
    _clearReply();
    setState(() => _sending = false);
  }

  Future<void> _deleteComment(String commentId) async {
    final batch = FirebaseFirestore.instance.batch();

    batch.delete(
      FirebaseFirestore.instance
          .collection('posts').doc(widget.postId)
          .collection('comments').doc(commentId),
    );
    batch.update(
      FirebaseFirestore.instance.collection('posts').doc(widget.postId),
      {'comments': FieldValue.increment(-1)},
    );

    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          // ── Handle ──
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const Text(
            'Comments',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          const Divider(color: Colors.white12, height: 20),

          // ── Live comments list ──
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts').doc(widget.postId)
                  .collection('comments')
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (_, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: _accent),
                  );
                }

                // Separate top-level comments from replies
                final allDocs = snapshot.data!.docs;
                final topLevel = allDocs
                    .where((d) =>
                (d.data() as Map)['replyToId'] == null)
                    .toList();

                if (topLevel.isEmpty) {
                  return const Center(
                    child: Text(
                      'No comments yet. Be first!',
                      style: TextStyle(color: Colors.white38),
                    ),
                  );
                }

                return ListView.builder(
                  controller: scrollController,
                  itemCount: topLevel.length,
                  itemBuilder: (_, i) {
                    final doc  = topLevel[i];
                    final c    = doc.data() as Map<String, dynamic>;
                    final isMe = c['userId'] == _uid;

                    // Replies to this comment
                    final replies = allDocs
                        .where((d) =>
                    (d.data() as Map)['replyToId'] == doc.id)
                        .toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Top-level comment ──
                        _CommentTile(
                          commentId:  doc.id,
                          data:       c,
                          isMe:       isMe,
                          isGuest:    _isGuest,
                          onReply:    () => _setReply(doc.id, c['username'] ?? ''),
                          onDelete:   isMe
                              ? () => _deleteComment(doc.id)
                              : null,
                        ),

                        // ── Replies ──
                        if (replies.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 48),
                            child: Column(
                              children: replies.map((r) {
                                final rd    = r.data() as Map<String, dynamic>;
                                final rIsMe = rd['userId'] == _uid;
                                return _CommentTile(
                                  commentId: r.id,
                                  data:      rd,
                                  isMe:      rIsMe,
                                  isGuest:   _isGuest,
                                  isReply:   true,
                                  onReply:   () => _setReply(
                                      doc.id, rd['username'] ?? ''),
                                  onDelete: rIsMe
                                      ? () => _deleteComment(r.id)
                                      : null,
                                );
                              }).toList(),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // ── Reply indicator ──
          if (_replyToUsername != null)
            Container(
              color: _surface,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.reply, color: _accent, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Replying to @$_replyToUsername',
                    style: const TextStyle(
                        color: Colors.white60, fontSize: 12),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _clearReply,
                    child: const Icon(Icons.close,
                        color: Colors.white38, size: 16),
                  ),
                ],
              ),
            ),

          // ── Input ──
          Container(
            color: _bg,
            padding: EdgeInsets.fromLTRB(
                12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    enabled: !_isGuest,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: _isGuest
                          ? 'Sign in to comment...'
                          : _replyToUsername != null
                          ? 'Reply to @$_replyToUsername...'
                          : 'Add a comment...',
                      hintStyle:
                      const TextStyle(color: Colors.white30),
                      filled: true,
                      fillColor: _surface,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _sending
                    ? const SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _accent),
                )
                    : IconButton(
                  icon: const Icon(Icons.send, color: _accent),
                  onPressed: _isGuest ? null : _sendComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}

// ── Single comment tile ────────────────────────────────────────────────────
class _CommentTile extends StatelessWidget {
  final String              commentId;
  final Map<String, dynamic> data;
  final bool                isMe;
  final bool                isGuest;
  final bool                isReply;
  final VoidCallback        onReply;
  final VoidCallback?       onDelete;

  static const Color _surface = Color(0xFF1A1A1A);
  static const Color _accent  = Color(0xFF1E88E5);

  const _CommentTile({
    required this.commentId,
    required this.data,
    required this.isMe,
    required this.isGuest,
    required this.onReply,
    this.onDelete,
    this.isReply = false,
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl = data['avatarUrl'] as String? ?? '';
    final username  = data['username']  as String? ?? 'Anonymous';
    final text      = data['text']      as String? ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: isReply ? 14 : 18,
            backgroundColor: _surface,
            backgroundImage: avatarUrl.isNotEmpty
                ? NetworkImage(avatarUrl) : null,
            child: avatarUrl.isEmpty
                ? Icon(Icons.person,
                color: Colors.white54,
                size: isReply ? 14 : 18)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username + delete button
                Row(
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    if (onDelete != null)
                      GestureDetector(
                        onTap: onDelete,
                        child: const Icon(Icons.delete_outline,
                            color: Colors.white30, size: 16),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                // Comment text
                Text(
                  text,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                // Reply button
                if (!isGuest)
                  GestureDetector(
                    onTap: onReply,
                    child: const Text(
                      'Reply',
                      style: TextStyle(
                        color: _accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
