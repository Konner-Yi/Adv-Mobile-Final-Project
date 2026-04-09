import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'moderation_service.dart';
import 'report_service.dart';
import 'report_models.dart';

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
  static const Color _bg = Color(0xFF0D0D0D);
  static const Color _surface = Color(0xFF1A1A1A);
  static const Color _accent = Color(0xFF1E88E5);
  static const Color _yellow = Color(0xFFFFD600);
  static const Color _red = Color(0xFFD32F2F);

  bool _liked = false;
  bool _disliked = false;
  bool _reposted = false;
  int _myRating = 0;
  bool _isPostOwnerBlocked = false;
  bool _isPostRemoved = false;

  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final bool _isGuest = FirebaseAuth.instance.currentUser == null;
  final ModerationService _moderationService = ModerationService();
  final ReportAndReputationService _reportService = ReportAndReputationService();
  bool _hasReportedThisPost = false;
  String _userBadges = '';

  String get _postOwnerId => (widget.post['userId'] ?? '').toString();

  @override
  void initState() {
    super.initState();
    if (!_isGuest) {
      _checkIfLiked();
      _checkIfReposted();
      _loadMyRating();
      _checkIfDisliked();
      _checkIfOwnerBlocked();
      _loadUserReputation();
    }
  }

  Future<void> _checkIfLiked() async {
    final doc = await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('likedBy')
        .doc(_uid)
        .get();
    if (mounted) setState(() => _liked = doc.exists);
  }

  Future<void> _checkIfReposted() async {
    final doc = await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('repostedBy')
        .doc(_uid)
        .get();
    if (mounted) setState(() => _reposted = doc.exists);
  }

  Future<void> _checkIfDisliked() async {
    try {
      final disliked = await _moderationService.hasUserDisliked(widget.postId);
      if (mounted) setState(() => _disliked = disliked);
    } catch (e) {
      print('Error checking dislike: $e');
    }
  }

  Future<void> _checkIfOwnerBlocked() async {
    try {
      final isBlocked = await _moderationService.isUserBlocked(_postOwnerId);
      if (mounted) setState(() => _isPostOwnerBlocked = isBlocked);
    } catch (e) {
      print('Error checking block status: $e');
    }
  }

  Future<void> _loadMyRating() async {
    final doc = await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('ratings')
        .doc(_uid)
        .get();

    if (!mounted) return;

    final data = doc.data();
    setState(() {
      _myRating = data?['rating'] is num ? (data!['rating'] as num).toInt() : 0;
    });
  }

  Future<void> _toggleLike() async {
    if (_isGuest) {
      _snackLoginRequired();
      return;
    }

    HapticFeedback.lightImpact();

    final ref = FirebaseFirestore.instance.collection('posts').doc(widget.postId);
    final batch = FirebaseFirestore.instance.batch();

    if (_liked) {
      batch.update(ref, {'likes': FieldValue.increment(-1)});
      batch.delete(ref.collection('likedBy').doc(_uid));

      if (_postOwnerId.isNotEmpty && _postOwnerId != _uid) {
        batch.set(
          FirebaseFirestore.instance.collection('users').doc(_postOwnerId),
          {'score': FieldValue.increment(-2)},
          SetOptions(merge: true),
        );
      }

      await batch.commit();
      if (mounted) setState(() => _liked = false);
    } else {
      batch.update(ref, {'likes': FieldValue.increment(1)});
      batch.set(
        ref.collection('likedBy').doc(_uid),
        {'likedAt': FieldValue.serverTimestamp()},
      );

      if (_postOwnerId.isNotEmpty && _postOwnerId != _uid) {
        batch.set(
          FirebaseFirestore.instance.collection('users').doc(_postOwnerId),
          {'score': FieldValue.increment(2)},
          SetOptions(merge: true),
        );
      }

      await batch.commit();
      if (mounted) setState(() => _liked = true);
    }
  }

  Future<void> _toggleDislike() async {
  if (_isGuest) {
    _snackLoginRequired();
    return;
  }

  if (_disliked) {
    
    try {
      await _moderationService.toggleDislike(widget.postId, null);
      if (mounted) setState(() => _disliked = false);
      _snack('Dislike removed');
    } catch (e) {
      _snack('Error: $e');
    }
  } else {
    
    _showDislikeReasonDialog();
  }
}

  void _showDislikeReasonDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _surface,
        title: const Text(
          'Why are you disliking this?',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DislikeReasonButton(
              label: 'Inappropriate Content',
              onTap: () {
                Navigator.pop(context);
                _addDislike('Inappropriate Content');
              },
            ),
            _DislikeReasonButton(
              label: 'Spam or Misleading',
              onTap: () {
                Navigator.pop(context);
                _addDislike('Spam or Misleading');
              },
            ),
            _DislikeReasonButton(
              label: 'Low Quality',
              onTap: () {
                Navigator.pop(context);
                _addDislike('Low Quality');
              },
            ),
            _DislikeReasonButton(
              label: 'Other',
              onTap: () {
                Navigator.pop(context);
                _addDislike('Other');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addDislike(String reason) async {
    try {
      HapticFeedback.lightImpact();
      await _moderationService.toggleDislike(widget.postId, reason);
      if (mounted) {
        setState(() => _disliked = true);
        _snack('Dislike recorded. Thank you for helping improve the community!');
      }
    } catch (e) {
      _snack('Error: $e');
    }
  }

  Future<void> _showBlockUserOptions() async {
    if (_isGuest) {
      _snackLoginRequired();
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: _bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isPostOwnerBlocked ? 'User Blocked' : 'Block User?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_isPostOwnerBlocked)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'You have blocked this user. You won\'t see their posts anymore.',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _unblockUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                    ),
                    child: const Text('Unblock User'),
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Blocking this user will hide their posts from your feed.',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _blockUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _red,
                    ),
                    child: const Text('Block User'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _blockUser() async {
    try {
      await _moderationService.blockUser(_postOwnerId);
      if (mounted) {
        setState(() => _isPostOwnerBlocked = true);
        Navigator.pop(context);
        _snack('User blocked successfully');
      }
    } catch (e) {
      _snack('Error blocking user: $e');
    }
  }

  Future<void> _unblockUser() async {
    try {
      await _moderationService.unblockUser(_postOwnerId);
      if (mounted) {
        setState(() => _isPostOwnerBlocked = false);
        Navigator.pop(context);
        _snack('User unblocked');
      }
    } catch (e) {
      _snack('Error unblocking user: $e');
    }
  }

  Future<void> _toggleRepost() async {
    if (_isGuest) {
      _snackLoginRequired();
      return;
    }

    HapticFeedback.lightImpact();

    final ref = FirebaseFirestore.instance.collection('posts').doc(widget.postId);
    final batch = FirebaseFirestore.instance.batch();

    if (_reposted) {
      batch.update(ref, {'reposts': FieldValue.increment(-1)});
      batch.delete(ref.collection('repostedBy').doc(_uid));

      if (_postOwnerId.isNotEmpty && _postOwnerId != _uid) {
        batch.set(
          FirebaseFirestore.instance.collection('users').doc(_postOwnerId),
          {'score': FieldValue.increment(-4)},
          SetOptions(merge: true),
        );
      }

      await batch.commit();
      if (mounted) setState(() => _reposted = false);
    } else {
      batch.update(ref, {'reposts': FieldValue.increment(1)});
      batch.set(
        ref.collection('repostedBy').doc(_uid),
        {'repostedAt': FieldValue.serverTimestamp()},
      );

      if (_postOwnerId.isNotEmpty && _postOwnerId != _uid) {
        batch.set(
          FirebaseFirestore.instance.collection('users').doc(_postOwnerId),
          {'score': FieldValue.increment(4)},
          SetOptions(merge: true),
        );
      }

      await batch.commit();
      if (mounted) setState(() => _reposted = true);
    }
  }

  Future<void> _submitRating(int rating) async {
    if (_isGuest) {
      _snackLoginRequired();
      return;
    }

    HapticFeedback.selectionClick();

    final postRef =
        FirebaseFirestore.instance.collection('posts').doc(widget.postId);
    final ratingRef = postRef.collection('ratings').doc(_uid);
    final ownerRef = FirebaseFirestore.instance.collection('users').doc(_postOwnerId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final postSnap = await transaction.get(postRef);
      final ratingSnap = await transaction.get(ratingRef);

      final postData = postSnap.data() ?? <String, dynamic>{};
      final oldRating = ratingSnap.exists
          ? ((ratingSnap.data()?['rating'] as num?)?.toInt() ?? 0)
          : 0;

      if (oldRating == rating) return;

      final oldRatingTotal =
          (postData['ratingTotal'] is num) ? (postData['ratingTotal'] as num).toInt() : 0;
      final oldRatingCount =
          (postData['ratingCount'] is num) ? (postData['ratingCount'] as num).toInt() : 0;
      final qualityBonusAwarded = postData['qualityBonusAwarded'] == true;

      int newRatingTotal = oldRatingTotal;
      int newRatingCount = oldRatingCount;

      transaction.set(ratingRef, {
        'rating': rating,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (oldRating == 0) {
        newRatingTotal += rating;
        newRatingCount += 1;

        transaction.update(postRef, {
          'ratingTotal': FieldValue.increment(rating),
          'ratingCount': FieldValue.increment(1),
        });

        if (_postOwnerId.isNotEmpty && _postOwnerId != _uid) {
          transaction.set(
            ownerRef,
            {'score': FieldValue.increment(1)},
            SetOptions(merge: true),
          );
        }
      } else {
        newRatingTotal += rating - oldRating;

        transaction.update(postRef, {
          'ratingTotal': FieldValue.increment(rating - oldRating),
        });
      }

      final newAverage =
          newRatingCount > 0 ? newRatingTotal / newRatingCount : 0.0;
      final qualifiesForBonus = newRatingCount >= 3 && newAverage >= 4.0;

      if (!qualityBonusAwarded &&
          qualifiesForBonus &&
          _postOwnerId.isNotEmpty &&
          _postOwnerId != _uid) {
        transaction.set(
          ownerRef,
          {'score': FieldValue.increment(2)},
          SetOptions(merge: true),
        );

        transaction.set(
          postRef,
          {'qualityBonusAwarded': true},
          SetOptions(merge: true),
        );
      }
    });

    if (mounted) {
      setState(() => _myRating = rating);
    }
  }

  Future<void> _loadUserReputation() async {
    try {
      final reputation = await _reportService.getUserReputation(_postOwnerId);
      if (mounted) {
        setState(() {
          _userBadges = reputation.badgeDisplay;
        });
      }
    } catch (e) {
      print('Error loading reputation: $e');
    }
  }

  void _showReportDialog() {
    if (_isGuest) {
      _snackLoginRequired();
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _surface,
        title: const Text(
          'Report Post',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Why are you reporting this post?',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ...ReportReason.values.map((reason) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showReportDetailsDialog(reason);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF262626),
                        foregroundColor: Colors.white,
                      ),
                      child: Column(
                        children: [
                          Text(reason.displayName,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(reason.description,
                              style: const TextStyle(fontSize: 11, color: Colors.white60)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportDetailsDialog(ReportReason reason) {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _surface,
        title: const Text(
          'Additional Details',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please provide any additional information:',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Details (optional)',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: _bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitReport(reason, messageController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: _red),
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReport(ReportReason reason, String message) async {
    try {
      await _reportService.reportPost(
        postId: widget.postId,
        postOwnerId: _postOwnerId,
        reason: reason,
        message: message.isNotEmpty ? message : reason.displayName,
      );
      if (mounted) {
        setState(() => _hasReportedThisPost = true);
        _snack('Report submitted. Thank you for helping keep our community safe.');
      }
    } catch (e) {
      _snack('Error submitting report: $e');
    }
  }

  void _showAppealDialog() {
    final appealController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _surface,
        title: const Text(
          'Appeal Post Removal',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tell us why you think this post should be restored:',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: appealController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Your appeal reason...',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: _bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitAppeal(appealController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: _accent),
            child: const Text('Submit Appeal'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitAppeal(String reason) async {
    if (reason.trim().isEmpty) {
      _snack('Please provide a reason for your appeal');
      return;
    }

    try {
      await _reportService.submitAppeal(
        postId: widget.postId,
        appealReason: reason,
      );
      if (mounted) {
        _snack('Appeal submitted. We will review it shortly.');
      }
    } catch (e) {
      _snack('Error submitting appeal: $e');
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
      builder: (_) => _CommentsSheet(
        postId: widget.postId,
        postOwnerId: _postOwnerId,
      ),
    );
  }

  void _snackLoginRequired() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sign in to interact with posts.')),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  String _getReputationLabel(int score) {
    if (score >= 150) return 'Community Leader';
    if (score >= 75) return 'Local Guide';
    if (score >= 25) return 'Explorer';
    return 'Newcomer';
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final avatarUrl = post['avatarUrl'] as String? ?? '';
    final username = post['username'] as String? ?? 'Anonymous';
    final imageUrl = post['imageUrl'] as String? ?? '';
    final caption = post['caption'] as String? ?? '';
    final isRemoved = post['isRemoved'] as bool? ?? false;

    // Don't show removed posts
    if (isRemoved) {
      return Container(
        decoration: const BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Icon(
              Icons.block,
              color: _red,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'This post has been removed',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              post['removalReason'] ?? 'Post removed by moderation',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_uid == (post['userId'] ?? ''))
              ElevatedButton(
                onPressed: _showAppealDialog,
                style: ElevatedButton.styleFrom(backgroundColor: _accent),
                child: const Text('Appeal Removal'),
              ),
            const SizedBox(height: 40),
          ],
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
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
                Expanded(
                  child: FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(_postOwnerId)
                        .get(),
                    builder: (context, snapshot) {
                      int score = 0;
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data =
                            snapshot.data!.data() as Map<String, dynamic>?;
                        final rawScore = data?['score'];
                        score = rawScore is num
                            ? rawScore.toInt()
                            : int.tryParse(rawScore?.toString() ?? '') ?? 0;
                      }

                      final label = _getReputationLabel(score);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                username,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              if (_userBadges.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Text(
                                    _userBadges,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$label • Score $score',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                if (_uid != _postOwnerId)
                  IconButton(
                    icon: Icon(
                      Icons.more_vert,
                      color: _isPostOwnerBlocked ? _red : Colors.white54,
                    ),
                    onPressed: _showBlockUserOptions,
                  ),
              ],
            ),
          ),
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
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('posts')
                .doc(widget.postId)
                .snapshots(),
            builder: (context, snapshot) {
              final data = snapshot.data?.data() as Map<String, dynamic>?;
              final likes = data?['likes'] ?? 0;
              final comments = data?['comments'] ?? 0;
              final reposts = data?['reposts'] ?? 0;
              final dislikes = data?['dislikes'] ?? 0;
              final ratingTotal = (data?['ratingTotal'] ?? 0) as num;
              final ratingCount = (data?['ratingCount'] ?? 0) as num;
              final averageRating = ratingCount > 0
                  ? ratingTotal.toDouble() / ratingCount.toDouble()
                  : 0.0;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
                    child: Row(
                      children: [
                        const Text(
                          'Area Rating',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (ratingCount > 0)
                          Text(
                            '${averageRating.toStringAsFixed(1)} ★',
                            style: const TextStyle(
                              color: _yellow,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        if (ratingCount > 0) const SizedBox(width: 8),
                        Text(
                          ratingCount > 0
                              ? '(${ratingCount.toInt()} ratings)'
                              : 'No ratings yet',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
                    child: Row(
                      children: List.generate(5, (index) {
                        final starValue = index + 1;
                        final filled = starValue <= _myRating;
                        return IconButton(
                          onPressed: _isGuest
                              ? _snackLoginRequired
                              : () => _submitRating(starValue),
                          icon: Icon(
                            filled ? Icons.star : Icons.star_border,
                            color: _yellow,
                            size: 28,
                          ),
                          splashRadius: 20,
                        );
                      }),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        _ActionButton(
                          icon: _liked ? Icons.favorite : Icons.favorite_border,
                          color: _liked ? Colors.redAccent : Colors.white70,
                          count: likes,
                          onTap: _toggleLike,
                        ),
                        const SizedBox(width: 4),
                        _ActionButton(
                          icon: Icons.chat_bubble_outline,
                          color: Colors.white70,
                          count: comments,
                          onTap: _openComments,
                        ),
                        const SizedBox(width: 4),
                        _ActionButton(
                          icon: Icons.repeat,
                          color: _reposted ? _yellow : Colors.white70,
                          count: reposts,
                          onTap: _toggleRepost,
                        ),
                        const SizedBox(width: 4),
                        _ActionButton(
                          icon: _disliked ? Icons.thumb_down : Icons.thumb_down_outlined,
                          color: _disliked ? _red : Colors.white70,
                          count: dislikes,
                          onTap: _toggleDislike,
                        ),
                        const SizedBox(width: 4),
                        _ActionButton(
                          icon: _hasReportedThisPost ? Icons.flag : Icons.flag_outlined,
                          color: _hasReportedThisPost ? Colors.orange : Colors.white70,
                          count: 0,
                          onTap: _showReportDialog,
                        ),
                      ],
                    ),
                  ),
                  if (dislikes >= 3)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _red.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_outlined,
                              color: _red,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'This post has received many dislikes ($dislikes)',
                                style: TextStyle(
                                  color: _red.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
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

class _DislikeReasonButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DislikeReasonButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF262626),
            foregroundColor: Colors.white,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

// Keep the existing _CommentsSheet and _CommentTile from your original code...
class _CommentsSheet extends StatefulWidget {
  final String postId;
  final String postOwnerId;

  const _CommentsSheet({
    required this.postId,
    required this.postOwnerId,
  });

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  static const Color _bg = Color(0xFF0D0D0D);
  static const Color _surface = Color(0xFF1A1A1A);
  static const Color _accent = Color(0xFF1E88E5);

  final _commentController = TextEditingController();
  bool _sending = false;
  String? _replyToId;
  String? _replyToUsername;

  final String? _uid = FirebaseAuth.instance.currentUser?.uid;
  final bool _isGuest = FirebaseAuth.instance.currentUser == null;

  void _setReply(String commentId, String username) {
    setState(() {
      _replyToId = commentId;
      _replyToUsername = username;
    });
    FocusScope.of(context).unfocus();
  }

  void _clearReply() {
    setState(() {
      _replyToId = null;
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
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .doc();

    batch.set(commentRef, {
      'userId': user.uid,
      'username': user.displayName ?? 'Anonymous',
      'avatarUrl': user.photoURL ?? '',
      'text': text,
      'replyToId': _replyToId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.update(
      FirebaseFirestore.instance.collection('posts').doc(widget.postId),
      {'comments': FieldValue.increment(1)},
    );

    await batch.commit();

    _commentController.clear();
    _clearReply();
    if (mounted) setState(() => _sending = false);
  }

  Future<void> _deleteComment(String commentId, String commentUserId) async {
    final batch = FirebaseFirestore.instance.batch();

    batch.delete(
      FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .doc(commentId),
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

                final allDocs = snapshot.data!.docs;
                final topLevel = allDocs
                    .where((d) => (d.data() as Map)['replyToId'] == null)
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
                    final doc = topLevel[i];
                    final c = doc.data() as Map<String, dynamic>;
                    final isMe = c['userId'] == _uid;

                    final replies = allDocs
                        .where((d) => (d.data() as Map)['replyToId'] == doc.id)
                        .toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CommentTile(
                          commentId: doc.id,
                          data: c,
                          isMe: isMe,
                          isGuest: _isGuest,
                          onReply: () => _setReply(doc.id, c['username'] ?? ''),
                          onDelete: isMe
                              ? () => _deleteComment(
                                  doc.id,
                                  (c['userId'] ?? '').toString(),
                                )
                              : null,
                        ),
                        if (replies.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 48),
                            child: Column(
                              children: replies.map((r) {
                                final rd = r.data() as Map<String, dynamic>;
                                final rIsMe = rd['userId'] == _uid;
                                return _CommentTile(
                                  commentId: r.id,
                                  data: rd,
                                  isMe: rIsMe,
                                  isGuest: _isGuest,
                                  isReply: true,
                                  onReply: () =>
                                      _setReply(doc.id, rd['username'] ?? ''),
                                  onDelete: rIsMe
                                      ? () => _deleteComment(
                                            r.id,
                                            (rd['userId'] ?? '').toString(),
                                          )
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
          if (_replyToUsername != null)
            Container(
              color: _surface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.reply, color: _accent, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Replying to @$_replyToUsername',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _clearReply,
                    child:
                        const Icon(Icons.close, color: Colors.white38, size: 16),
                  ),
                ],
              ),
            ),
          Container(
            color: _bg,
            padding: EdgeInsets.fromLTRB(
              12,
              8,
              12,
              MediaQuery.of(context).padding.bottom + 8,
            ),
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
                      hintStyle: const TextStyle(color: Colors.white30),
                      filled: true,
                      fillColor: _surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
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
                          strokeWidth: 2,
                          color: _accent,
                        ),
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

class _CommentTile extends StatelessWidget {
  final String commentId;
  final Map<String, dynamic> data;
  final bool isMe;
  final bool isGuest;
  final bool isReply;
  final VoidCallback onReply;
  final VoidCallback? onDelete;

  static const Color _surface = Color(0xFF1A1A1A);
  static const Color _accent = Color(0xFF1E88E5);

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
    final username = data['username'] as String? ?? 'Anonymous';
    final text = data['text'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: isReply ? 14 : 18,
            backgroundColor: _surface,
            backgroundImage:
                avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
            child: avatarUrl.isEmpty
                ? Icon(
                    Icons.person,
                    color: Colors.white54,
                    size: isReply ? 14 : 18,
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white30,
                          size: 16,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
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