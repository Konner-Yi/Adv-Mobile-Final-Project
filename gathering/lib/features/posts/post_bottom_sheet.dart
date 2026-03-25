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

  late int _likes;
  late int _comments;
  late int _reposts;
  bool _liked    = false;
  bool _reposted = false;

  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _likes    = widget.post['likes']   ?? 0;
    _comments = widget.post['comments'] ?? 0;
    _reposts  = widget.post['reposts'] ?? 0;
    _checkIfLiked();
  }

  // ── Check if current user already liked this post ──────
  Future<void> _checkIfLiked() async {
    final doc = await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('likedBy')
        .doc(_uid)
        .get();
    if (mounted) setState(() => _liked = doc.exists);
  }

  // ── Like toggle ────────────────────────────────────────
  Future<void> _toggleLike() async {
    HapticFeedback.lightImpact();
    final ref = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId);

    if (_liked) {
      await ref.update({'likes': FieldValue.increment(-1)});
      await ref.collection('likedBy').doc(_uid).delete();
      setState(() { _liked = false; _likes--; });
    } else {
      await ref.update({'likes': FieldValue.increment(1)});
      await ref.collection('likedBy').doc(_uid).set({'likedAt': FieldValue.serverTimestamp()});
      setState(() { _liked = true; _likes++; });
    }
  }

  // ── Repost toggle ──────────────────────────────────────
  Future<void> _toggleRepost() async {
    HapticFeedback.lightImpact();
    final ref = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId);

    if (_reposted) {
      await ref.update({'reposts': FieldValue.increment(-1)});
      setState(() { _reposted = false; _reposts--; });
    } else {
      await ref.update({'reposts': FieldValue.increment(1)});
      setState(() { _reposted = true; _reposts++; });
    }
  }

  // ── Comments sheet ─────────────────────────────────────
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

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final avatarUrl  = post['avatarUrl']  as String? ?? '';
    final username   = post['username']   as String? ?? 'Anonymous';
    final imageUrl   = post['imageUrl']   as String? ?? '';
    final caption    = post['caption']    as String? ?? '';

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
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── Header: avatar + username ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _surface,
                  backgroundImage:
                  avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
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

          // ── Post image ──
          if (imageUrl.isNotEmpty)
            Image.network(
              imageUrl,
              width: double.infinity,
              height: 320,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : Container(
                height: 320,
                color: _surface,
                child: const Center(
                  child: CircularProgressIndicator(color: _accent),
                ),
              ),
            ),

          // ── Action bar ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Like
                _ActionButton(
                  icon: _liked ? Icons.favorite : Icons.favorite_border,
                  color: _liked ? Colors.redAccent : Colors.white70,
                  count: _likes,
                  onTap: _toggleLike,
                ),
                const SizedBox(width: 4),
                // Comment
                _ActionButton(
                  icon: Icons.chat_bubble_outline,
                  color: Colors.white70,
                  count: _comments,
                  onTap: _openComments,
                ),
                const SizedBox(width: 4),
                // Repost
                _ActionButton(
                  icon: Icons.repeat,
                  color: _reposted ? _yellow : Colors.white70,
                  count: _reposts,
                  onTap: _toggleRepost,
                ),
              ],
            ),
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

// ── Small action button widget ─────────────────────────────────────────────
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

// ── Comments bottom sheet ──────────────────────────────────────────────────
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
  bool _sending = false;

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    final user = FirebaseAuth.instance.currentUser;

    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .add({
      'userId':    user?.uid ?? '',
      'username':  user?.displayName ?? 'Anonymous',
      'avatarUrl': user?.photoURL ?? '',
      'text':      text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Increment comment count on the post
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .update({'comments': FieldValue.increment(1)});

    _commentController.clear();
    setState(() => _sending = false);
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
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            width: 40,
            height: 4,
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

          // Comments list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (_, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: _accent),
                  );
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No comments yet. Be first!',
                      style: TextStyle(color: Colors.white38),
                    ),
                  );
                }
                return ListView.builder(
                  controller: scrollController,
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final c = docs[i].data() as Map<String, dynamic>;
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: _surface,
                        backgroundImage: (c['avatarUrl'] as String?)
                            ?.isNotEmpty ==
                            true
                            ? NetworkImage(c['avatarUrl'])
                            : null,
                        child: (c['avatarUrl'] as String?)?.isEmpty != false
                            ? const Icon(Icons.person,
                            color: Colors.white54, size: 16)
                            : null,
                      ),
                      title: Text(
                        c['username'] ?? 'Anonymous',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(
                        c['text'] ?? '',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Comment input
          Container(
            color: _bg,
            padding: EdgeInsets.fromLTRB(
                12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: const TextStyle(color: Colors.white30),
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
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _accent),
                )
                    : IconButton(
                  icon: const Icon(Icons.send, color: _accent),
                  onPressed: _sendComment,
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