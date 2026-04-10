// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'moderation_service.dart';
// import '../posts/create_post_screen.dart';
//
// class PostBottomSheet extends StatefulWidget {
//   final Map<String, dynamic> post;
//   final String postId;
//   final String collection;
//
//   const PostBottomSheet({
//     super.key,
//     required this.post,
//     required this.postId,
//     this.collection = 'posts',
//   });
//
//   @override
//   State<PostBottomSheet> createState() => _PostBottomSheetState();
// }
//
// class _PostBottomSheetState extends State<PostBottomSheet> {
//   static const Color _bg      = Color(0xFFFAFAFA);
//   static const Color _surface = Color(0xFFFFFFFF);
//   static const Color _accent  = Color(0xFF1E88E5);
//   static const Color _yellow  = Color(0xFFFFD600);
//   static const Color _red     = Color(0xFFD32F2F);
//   static const Color _grey200 = Color(0xFFEEEEEE);
//   static const Color _grey600 = Color(0xFF757575);
//   static const Color _grey900 = Color(0xFF212121);
//
//   bool _liked   = false;
//   bool _disliked  = false;
//   bool _reposted  = false;
//   bool _saved     = false;
//   int  _myRating  = 0;
//   bool _isPostOwnerBlocked = false;
//
//   final String _uid     = FirebaseAuth.instance.currentUser?.uid ?? '';
//   final bool   _isGuest = FirebaseAuth.instance.currentUser == null;
//   final ModerationService _moderationService = ModerationService();
//
//   DocumentReference get _postRef =>
//       FirebaseFirestore.instance.collection(widget.collection).doc(widget.postId);
//
//   String get _postOwnerId => (widget.post['userId'] ?? '').toString();
//
//   @override
//   void initState() {
//     super.initState();
//     if (!_isGuest) {
//       _checkIfLiked();
//       _checkIfReposted();
//       _checkIfSaved();
//       _loadMyRating();
//       _checkIfDisliked();
//       _checkIfOwnerBlocked();
//     }
//   }
//
//   Future<void> _checkIfLiked() async {
//     final doc = await _postRef.collection('likedBy').doc(_uid).get();
//     if (mounted) setState(() => _liked = doc.exists);
//   }
//
//   Future<void> _checkIfReposted() async {
//     final doc = await _postRef.collection('repostedBy').doc(_uid).get();
//     if (mounted) setState(() => _reposted = doc.exists);
//   }
//
//   Future<void> _checkIfSaved() async {
//     final doc = await FirebaseFirestore.instance
//         .collection('users').doc(_uid)
//         .collection('saved').doc(widget.postId)
//         .get();
//     if (mounted) setState(() => _saved = doc.exists);
//   }
//
//   Future<void> _checkIfDisliked() async {
//     try {
//       final disliked = await _moderationService.hasUserDisliked(widget.postId);
//       if (mounted) setState(() => _disliked = disliked);
//     } catch (e) {
//       debugPrint('Error checking dislike: $e');
//     }
//   }
//
//   Future<void> _checkIfOwnerBlocked() async {
//     try {
//       final isBlocked = await _moderationService.isUserBlocked(_postOwnerId);
//       if (mounted) setState(() => _isPostOwnerBlocked = isBlocked);
//     } catch (e) {
//       debugPrint('Error checking block status: $e');
//     }
//   }
//
//   Future<void> _loadMyRating() async {
//     final doc = await _postRef.collection('ratings').doc(_uid).get();
//     if (!mounted) return;
//     final data = doc.data() as Map<String, dynamic>?;
//     setState(() {
//       _myRating = data?['rating'] is num ? (data!['rating'] as num).toInt() : 0;
//     });
//   }
//
//   Future<void> _toggleLike() async {
//     if (_isGuest) { _snackLoginRequired(); return; }
//     HapticFeedback.lightImpact();
//
//     final batch = FirebaseFirestore.instance.batch();
//
//     if (_liked) {
//       batch.update(_postRef, {'likes': FieldValue.increment(-1)});
//       batch.delete(_postRef.collection('likedBy').doc(_uid));
//       if (_postOwnerId.isNotEmpty && _postOwnerId != _uid) {
//         batch.set(
//           FirebaseFirestore.instance.collection('users').doc(_postOwnerId),
//           {'score': FieldValue.increment(-2)},
//           SetOptions(merge: true),
//         );
//       }
//       await batch.commit();
//       if (mounted) setState(() => _liked = false);
//     } else {
//       batch.update(_postRef, {'likes': FieldValue.increment(1)});
//       batch.set(
//         _postRef.collection('likedBy').doc(_uid),
//         {'likedAt': FieldValue.serverTimestamp()},
//       );
//       if (_postOwnerId.isNotEmpty && _postOwnerId != _uid) {
//         batch.set(
//           FirebaseFirestore.instance.collection('users').doc(_postOwnerId),
//           {'score': FieldValue.increment(2)},
//           SetOptions(merge: true),
//         );
//       }
//       await batch.commit();
//       if (mounted) setState(() => _liked = true);
//     }
//   }
//
//   Future<void> _toggleSave() async {
//     if (_isGuest) { _snackLoginRequired(); return; }
//     HapticFeedback.lightImpact();
//
//     final savedRef = FirebaseFirestore.instance
//         .collection('users').doc(_uid)
//         .collection('saved').doc(widget.postId);
//
//     if (_saved) {
//       await savedRef.delete();
//       if (mounted) setState(() => _saved = false);
//     } else {
//       await savedRef.set({
//         'savedAt': FieldValue.serverTimestamp(),
//         'collection': widget.collection,
//       });
//       if (mounted) setState(() => _saved = true);
//     }
//   }
//
//   Future<void> _toggleDislike() async {
//     if (_isGuest) { _snackLoginRequired(); return; }
//     if (!_disliked) {
//       _showDislikeReasonDialog();
//     } else {
//       try {
//         await _moderationService.toggleDislike(widget.postId, null);
//         if (mounted) setState(() => _disliked = false);
//         _snack('Dislike removed');
//       } catch (e) {
//         _snack('Error: $e');
//       }
//     }
//   }
//
//   void _showDislikeReasonDialog() {
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         backgroundColor: _surface,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: const Text('Why are you disliking this?',
//             style: TextStyle(color: _grey900, fontWeight: FontWeight.bold)),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             _DislikeReasonButton(label: 'Inappropriate Content',
//                 onTap: () { Navigator.pop(context); _addDislike('Inappropriate Content'); }),
//             _DislikeReasonButton(label: 'Spam or Misleading',
//                 onTap: () { Navigator.pop(context); _addDislike('Spam or Misleading'); }),
//             _DislikeReasonButton(label: 'Low Quality',
//                 onTap: () { Navigator.pop(context); _addDislike('Low Quality'); }),
//             _DislikeReasonButton(label: 'Other',
//                 onTap: () { Navigator.pop(context); _addDislike('Other'); }),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Future<void> _addDislike(String reason) async {
//     try {
//       HapticFeedback.lightImpact();
//       await _moderationService.toggleDislike(widget.postId, reason);
//       if (mounted) {
//         setState(() => _disliked = true);
//         _snack('Dislike recorded. Thank you for helping improve the community!');
//       }
//     } catch (e) {
//       _snack('Error: $e');
//     }
//   }
//
//   Future<void> _toggleRepost() async {
//     if (_isGuest) { _snackLoginRequired(); return; }
//     HapticFeedback.lightImpact();
//
//     final batch = FirebaseFirestore.instance.batch();
//
//     if (_reposted) {
//       batch.update(_postRef, {'reposts': FieldValue.increment(-1)});
//       batch.delete(_postRef.collection('repostedBy').doc(_uid));
//       if (_postOwnerId.isNotEmpty && _postOwnerId != _uid) {
//         batch.set(
//           FirebaseFirestore.instance.collection('users').doc(_postOwnerId),
//           {'score': FieldValue.increment(-4)},
//           SetOptions(merge: true),
//         );
//       }
//       await batch.commit();
//       if (mounted) setState(() => _reposted = false);
//     } else {
//       batch.update(_postRef, {'reposts': FieldValue.increment(1)});
//       batch.set(
//         _postRef.collection('repostedBy').doc(_uid),
//         {'repostedAt': FieldValue.serverTimestamp()},
//       );
//       if (_postOwnerId.isNotEmpty && _postOwnerId != _uid) {
//         batch.set(
//           FirebaseFirestore.instance.collection('users').doc(_postOwnerId),
//           {'score': FieldValue.increment(4)},
//           SetOptions(merge: true),
//         );
//       }
//       await batch.commit();
//       if (mounted) setState(() => _reposted = true);
//     }
//   }
//
//   Future<void> _submitRating(int rating) async {
//     if (_isGuest) { _snackLoginRequired(); return; }
//     HapticFeedback.selectionClick();
//
//     final ratingRef = _postRef.collection('ratings').doc(_uid);
//     final ownerRef  = FirebaseFirestore.instance.collection('users').doc(_postOwnerId);
//
//     await FirebaseFirestore.instance.runTransaction((transaction) async {
//       final postSnap   = await transaction.get(_postRef);
//       final ratingSnap = await transaction.get(ratingRef);
//
//       final postData  = postSnap.data() as Map<String, dynamic>? ?? {};
//       final oldRating = ratingSnap.exists
//           ? ((ratingSnap.data() as Map<String, dynamic>?)?['rating'] as num?)?.toInt() ?? 0
//           : 0;
//
//       if (oldRating == rating) return;
//
//       final oldTotal  = (postData['ratingTotal'] as num?)?.toInt() ?? 0;
//       final oldCount  = (postData['ratingCount'] as num?)?.toInt() ?? 0;
//       final bonusGiven = postData['qualityBonusAwarded'] == true;
//
//       transaction.set(ratingRef,
//           {'rating': rating, 'updatedAt': FieldValue.serverTimestamp()},
//           SetOptions(merge: true));
//
//       int newTotal = oldTotal;
//       int newCount = oldCount;
//
//       if (oldRating == 0) {
//         newTotal += rating;
//         newCount += 1;
//         transaction.update(_postRef, {
//           'ratingTotal': FieldValue.increment(rating),
//           'ratingCount': FieldValue.increment(1),
//         });
//         if (_postOwnerId.isNotEmpty && _postOwnerId != _uid) {
//           transaction.set(ownerRef, {'score': FieldValue.increment(1)},
//               SetOptions(merge: true));
//         }
//       } else {
//         newTotal += rating - oldRating;
//         transaction.update(_postRef,
//             {'ratingTotal': FieldValue.increment(rating - oldRating)});
//       }
//
//       final avg = newCount > 0 ? newTotal / newCount : 0.0;
//       if (!bonusGiven && newCount >= 3 && avg >= 4.0 &&
//           _postOwnerId.isNotEmpty && _postOwnerId != _uid) {
//         transaction.set(ownerRef, {'score': FieldValue.increment(2)},
//             SetOptions(merge: true));
//         transaction.set(_postRef, {'qualityBonusAwarded': true},
//             SetOptions(merge: true));
//       }
//     });
//
//     if (mounted) setState(() => _myRating = rating);
//   }
//
//   Future<void> _showBlockUserOptions() async {
//     if (_isGuest) { _snackLoginRequired(); return; }
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: _surface,
//       shape: const RoundedRectangleBorder(
//           borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
//       builder: (_) => Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Text(_isPostOwnerBlocked ? 'User Blocked' : 'Block User?',
//                 style: const TextStyle(color: _grey900, fontSize: 16,
//                     fontWeight: FontWeight.bold)),
//             const SizedBox(height: 12),
//             if (_isPostOwnerBlocked) ...[
//               Text('You have blocked this user.',
//                   style: TextStyle(color: _grey600, fontSize: 14)),
//               const SizedBox(height: 16),
//               ElevatedButton(onPressed: _unblockUser,
//                   style: ElevatedButton.styleFrom(backgroundColor: _accent),
//                   child: const Text('Unblock User',
//                       style: TextStyle(color: Colors.white))),
//             ] else ...[
//               Text('Blocking this user will hide their posts from your feed.',
//                   style: TextStyle(color: _grey600, fontSize: 14)),
//               const SizedBox(height: 16),
//               ElevatedButton(onPressed: _blockUser,
//                   style: ElevatedButton.styleFrom(backgroundColor: _red),
//                   child: const Text('Block User',
//                       style: TextStyle(color: Colors.white))),
//               const SizedBox(height: 8),
//               OutlinedButton(
//                   onPressed: () => Navigator.pop(context),
//                   style: OutlinedButton.styleFrom(
//                       side: BorderSide(color: _grey200)),
//                   child: Text('Cancel',
//                       style: TextStyle(color: _grey900))),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
//
//   Future<void> _blockUser() async {
//     try {
//       await _moderationService.blockUser(_postOwnerId);
//       if (mounted) {
//         setState(() => _isPostOwnerBlocked = true);
//         Navigator.pop(context);
//         _snack('User blocked successfully');
//       }
//     } catch (e) { _snack('Error blocking user: $e'); }
//   }
//
//   Future<void> _unblockUser() async {
//     try {
//       await _moderationService.unblockUser(_postOwnerId);
//       if (mounted) {
//         setState(() => _isPostOwnerBlocked = false);
//         Navigator.pop(context);
//         _snack('User unblocked');
//       }
//     } catch (e) { _snack('Error unblocking user: $e'); }
//   }
//
//   void _openComments() {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: _bg,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//           borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
//       builder: (_) => _CommentsSheet(
//         postId: widget.postId,
//         postOwnerId: _postOwnerId,
//         collection: widget.collection,
//       ),
//     );
//   }
//
//   void _snackLoginRequired() => ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Sign in to interact with posts.')));
//
//   void _snack(String msg) => ScaffoldMessenger.of(context)
//       .showSnackBar(SnackBar(content: Text(msg)));
//
//   String _getReputationLabel(int score) {
//     if (score >= 150) return 'Community Leader';
//     if (score >= 75)  return 'Local Guide';
//     if (score >= 25)  return 'Explorer';
//     return 'Newcomer';
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final post      = widget.post;
//     final avatarUrl = post['avatarUrl'] as String? ?? '';
//     final username  = post['username']  as String? ?? 'Anonymous';
//     final imageUrl  = post['imageUrl']  as String? ?? '';
//     final caption   = post['caption']   as String? ?? '';
//     final isRemoved = post['isRemoved'] as bool?   ?? false;
//
//     if (isRemoved) {
//       return Container(
//         decoration: const BoxDecoration(
//             color: _bg,
//             borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const SizedBox(height: 40),
//             Icon(Icons.block, color: _red, size: 48),
//             const SizedBox(height: 16),
//             const Text('This post has been removed',
//                 style: TextStyle(color: _grey900, fontSize: 16,
//                     fontWeight: FontWeight.bold)),
//             const SizedBox(height: 8),
//             Text(post['removalReason'] ?? 'Post removed by moderation',
//                 style: TextStyle(color: _grey600, fontSize: 14),
//                 textAlign: TextAlign.center),
//             const SizedBox(height: 40),
//           ],
//         ),
//       );
//     }
//
//     return Container(
//       decoration: const BoxDecoration(
//           color: _bg,
//           borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // Drag handle
//           Container(
//             margin: const EdgeInsets.only(top: 10, bottom: 6),
//             width: 40, height: 4,
//             decoration: BoxDecoration(
//                 color: _grey200, borderRadius: BorderRadius.circular(2)),
//           ),
//
//           // Header: avatar + username + reputation
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//             child: Row(
//               children: [
//                 CircleAvatar(
//                   radius: 20,
//                   backgroundColor: _grey200,
//                   backgroundImage: avatarUrl.isNotEmpty
//                       ? NetworkImage(avatarUrl) : null,
//                   child: avatarUrl.isEmpty
//                       ? Icon(Icons.person, color: _grey600) : null,
//                 ),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: FutureBuilder<DocumentSnapshot>(
//                     future: FirebaseFirestore.instance
//                         .collection('users').doc(_postOwnerId).get(),
//                     builder: (context, snapshot) {
//                       int score = 0;
//                       if (snapshot.hasData && snapshot.data!.exists) {
//                         final d = snapshot.data!.data() as Map<String, dynamic>?;
//                         final raw = d?['score'];
//                         score = raw is num ? raw.toInt()
//                             : int.tryParse(raw?.toString() ?? '') ?? 0;
//                       }
//                       return Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(username,
//                               style: const TextStyle(color: _grey900,
//                                   fontWeight: FontWeight.bold, fontSize: 15)),
//                           const SizedBox(height: 2),
//                           Text('${_getReputationLabel(score)} • Score $score',
//                               style: TextStyle(color: _grey600, fontSize: 12)),
//                         ],
//                       );
//                     },
//                   ),
//                 ),
//                 if (_uid != _postOwnerId)
//                   IconButton(
//                     icon: Icon(Icons.more_vert,
//                         color: _isPostOwnerBlocked ? _red : _grey600),
//                     onPressed: _showBlockUserOptions,
//                   ),
//               ],
//             ),
//           ),
//
//           // Image or icon
//           if (imageUrl.isNotEmpty)
//             ClipRRect(
//               borderRadius: BorderRadius.circular(12),
//               child: Image.network(
//                 imageUrl,
//                 width: double.infinity,
//                 height: 320,
//                 fit: BoxFit.cover,
//                 loadingBuilder: (_, child, progress) => progress == null
//                     ? child
//                     : Container(
//                   height: 320,
//                   color: _grey200,
//                   child: const Center(
//                     child: CircularProgressIndicator(color: _accent),
//                   ),
//                 ),
//               ),
//             )
//           else if ((post['postIcon'] as String?) != null)
//             _PostIconDisplay(iconLabel: post['postIcon'] as String),
//
//           StreamBuilder<DocumentSnapshot>(
//             stream: _postRef.snapshots(),
//             builder: (context, snapshot) {
//               final data        = snapshot.data?.data() as Map<String, dynamic>?;
//               final likes       = (data?['likes']       as num?)?.toInt() ?? 0;
//               final comments    = (data?['comments']    as num?)?.toInt() ?? 0;
//               final reposts     = (data?['reposts']     as num?)?.toInt() ?? 0;
//               final dislikes    = (data?['dislikes']    as num?)?.toInt() ?? 0;
//               final ratingTotal = (data?['ratingTotal'] as num?) ?? 0;
//               final ratingCount = (data?['ratingCount'] as num?) ?? 0;
//               final avg = ratingCount > 0
//                   ? ratingTotal.toDouble() / ratingCount.toDouble() : 0.0;
//
//               return Column(
//                 children: [
//                   // Divider
//                   Container(
//                     margin: const EdgeInsets.only(top: 12),
//                     height: 1,
//                     color: _grey200,
//                   ),
//
//                   // Rating row
//                   Padding(
//                     padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
//                     child: Row(children: [
//                       const Text('Area Rating',
//                           style: TextStyle(color: _grey900,
//                               fontWeight: FontWeight.w700, fontSize: 14)),
//                       const SizedBox(width: 10),
//                       if (ratingCount > 0) ...[
//                         Text('${avg.toStringAsFixed(1)} ★',
//                             style: const TextStyle(color: Color(0xFFF9A825),
//                                 fontWeight: FontWeight.w700, fontSize: 14)),
//                         const SizedBox(width: 8),
//                       ],
//                       Text(
//                           ratingCount > 0
//                               ? '(${ratingCount.toInt()} ratings)'
//                               : 'No ratings yet',
//                           style: TextStyle(color: _grey600, fontSize: 12)),
//                     ]),
//                   ),
//
//                   // Stars
//                   Padding(
//                     padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
//                     child: Row(
//                       children: List.generate(5, (i) {
//                         final val    = i + 1;
//                         final filled = val <= _myRating;
//                         return IconButton(
//                           onPressed: _isGuest ? _snackLoginRequired
//                               : () => _submitRating(val),
//                           icon: Icon(
//                               filled ? Icons.star : Icons.star_border,
//                               color: const Color(0xFFF9A825), size: 28),
//                           splashRadius: 20,
//                         );
//                       }),
//                     ),
//                   ),
//
//                   Container(height: 1, color: _grey200),
//
//                   // Action buttons
//                   Padding(
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 12, vertical: 8),
//                     child: Row(children: [
//                       _ActionButton(
//                           icon: _liked ? Icons.favorite : Icons.favorite_border,
//                           color: _liked ? Colors.redAccent : _grey600,
//                           count: likes, onTap: _toggleLike),
//                       const SizedBox(width: 4),
//                       _ActionButton(
//                           icon: Icons.chat_bubble_outline,
//                           color: _grey600,
//                           count: comments, onTap: _openComments),
//                       const SizedBox(width: 4),
//                       _ActionButton(
//                           icon: Icons.repeat,
//                           color: _reposted ? const Color(0xFFF9A825) : _grey600,
//                           count: reposts, onTap: _toggleRepost),
//                       const SizedBox(width: 4),
//                       _ActionButton(
//                           icon: _disliked
//                               ? Icons.thumb_down : Icons.thumb_down_outlined,
//                           color: _disliked ? _red : _grey600,
//                           count: dislikes, onTap: _toggleDislike),
//                       const Spacer(),
//                       GestureDetector(
//                         onTap: _toggleSave,
//                         child: Padding(
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 10, vertical: 6),
//                           child: Icon(
//                             _saved ? Icons.bookmark : Icons.bookmark_border,
//                             color: _saved ? _accent : _grey600,
//                             size: 26,
//                           ),
//                         ),
//                       ),
//                     ]),
//                   ),
//
//                   if (dislikes >= 3)
//                     Padding(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 16, vertical: 8),
//                       child: Container(
//                         padding: const EdgeInsets.all(8),
//                         decoration: BoxDecoration(
//                           color: _red.withOpacity(0.07),
//                           borderRadius: BorderRadius.circular(8),
//                           border: Border.all(color: _red.withOpacity(0.25)),
//                         ),
//                         child: Row(children: [
//                           Icon(Icons.warning_outlined, color: _red, size: 16),
//                           const SizedBox(width: 8),
//                           Expanded(
//                             child: Text(
//                                 'This post has received many dislikes ($dislikes)',
//                                 style: TextStyle(
//                                     color: _red, fontSize: 12)),
//                           ),
//                         ]),
//                       ),
//                     ),
//                 ],
//               );
//             },
//           ),
//
//           // Caption
//           if (caption.isNotEmpty)
//             Padding(
//               padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: RichText(
//                   text: TextSpan(children: [
//                     TextSpan(text: '$username ',
//                         style: const TextStyle(color: _grey900,
//                             fontWeight: FontWeight.bold, fontSize: 14)),
//                     TextSpan(text: caption,
//                         style: TextStyle(color: _grey600, fontSize: 14)),
//                   ]),
//                 ),
//               ),
//             ),
//
//           SizedBox(height: MediaQuery.of(context).padding.bottom),
//         ],
//       ),
//     );
//   }
// }
//
// // ── Action button ─────────────────────────────────────────────────────────────
//
// class _ActionButton extends StatelessWidget {
//   final IconData icon;
//   final Color color;
//   final int count;
//   final VoidCallback onTap;
//
//   const _ActionButton({
//     required this.icon,
//     required this.color,
//     required this.count,
//     required this.onTap,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(20),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//         child: Row(children: [
//           Icon(icon, color: color, size: 26),
//           const SizedBox(width: 5),
//           Text('$count',
//               style: TextStyle(color: color, fontSize: 14,
//                   fontWeight: FontWeight.w600)),
//         ]),
//       ),
//     );
//   }
// }
//
// // ── Dislike reason button ─────────────────────────────────────────────────────
//
// class _DislikeReasonButton extends StatelessWidget {
//   final String label;
//   final VoidCallback onTap;
//   const _DislikeReasonButton({required this.label, required this.onTap});
//
//   static const Color _grey200 = Color(0xFFEEEEEE);
//   static const Color _grey900 = Color(0xFF212121);
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: SizedBox(
//         width: double.infinity,
//         child: ElevatedButton(
//           onPressed: onTap,
//           style: ElevatedButton.styleFrom(
//               backgroundColor: _grey200,
//               foregroundColor: _grey900,
//               elevation: 0,
//               shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10))),
//           child: Text(label),
//         ),
//       ),
//     );
//   }
// }
//
// // ── Comments sheet ────────────────────────────────────────────────────────────
//
// class _CommentsSheet extends StatefulWidget {
//   final String postId;
//   final String postOwnerId;
//   final String collection;
//
//   const _CommentsSheet({
//     required this.postId,
//     required this.postOwnerId,
//     this.collection = 'posts',
//   });
//
//   @override
//   State<_CommentsSheet> createState() => _CommentsSheetState();
// }
//
// class _CommentsSheetState extends State<_CommentsSheet> {
//   static const Color _bg      = Color(0xFFFAFAFA);
//   static const Color _surface = Color(0xFFFFFFFF);
//   static const Color _accent  = Color(0xFF1E88E5);
//   static const Color _grey200 = Color(0xFFEEEEEE);
//   static const Color _grey600 = Color(0xFF757575);
//   static const Color _grey900 = Color(0xFF212121);
//
//   final _commentController = TextEditingController();
//   bool    _sending = false;
//   String? _replyToId;
//   String? _replyToUsername;
//
//   final String? _uid     = FirebaseAuth.instance.currentUser?.uid;
//   final bool    _isGuest = FirebaseAuth.instance.currentUser == null;
//
//   DocumentReference get _postRef => FirebaseFirestore.instance
//       .collection(widget.collection).doc(widget.postId);
//
//   void _setReply(String commentId, String username) {
//     setState(() { _replyToId = commentId; _replyToUsername = username; });
//     FocusScope.of(context).unfocus();
//   }
//
//   void _clearReply() =>
//       setState(() { _replyToId = null; _replyToUsername = null; });
//
//   Future<void> _sendComment() async {
//     final text = _commentController.text.trim();
//     if (text.isEmpty || _isGuest) return;
//     setState(() => _sending = true);
//
//     final user  = FirebaseAuth.instance.currentUser!;
//     final batch = FirebaseFirestore.instance.batch();
//
//     batch.set(_postRef.collection('comments').doc(), {
//       'userId':    user.uid,
//       'username':  user.displayName ?? 'Anonymous',
//       'avatarUrl': user.photoURL ?? '',
//       'text':      text,
//       'replyToId': _replyToId,
//       'createdAt': FieldValue.serverTimestamp(),
//     });
//     batch.update(_postRef, {'comments': FieldValue.increment(1)});
//
//     await batch.commit();
//     _commentController.clear();
//     _clearReply();
//     if (mounted) setState(() => _sending = false);
//   }
//
//   Future<void> _deleteComment(String commentId) async {
//     final batch = FirebaseFirestore.instance.batch();
//     batch.delete(_postRef.collection('comments').doc(commentId));
//     batch.update(_postRef, {'comments': FieldValue.increment(-1)});
//     await batch.commit();
//   }
//
//   @override
//   void dispose() { _commentController.dispose(); super.dispose(); }
//
//   @override
//   Widget build(BuildContext context) {
//     return DraggableScrollableSheet(
//       initialChildSize: 0.6,
//       minChildSize: 0.4,
//       maxChildSize: 0.92,
//       expand: false,
//       builder: (_, scrollController) => Container(
//         color: _bg,
//         child: Column(
//           children: [
//             // Drag handle
//             Container(
//               margin: const EdgeInsets.only(top: 10, bottom: 8),
//               width: 40, height: 4,
//               decoration: BoxDecoration(color: _grey200,
//                   borderRadius: BorderRadius.circular(2)),
//             ),
//             const Text('Comments', style: TextStyle(color: _grey900,
//                 fontWeight: FontWeight.bold, fontSize: 16)),
//             Divider(color: _grey200, height: 20),
//             Expanded(
//               child: StreamBuilder<QuerySnapshot>(
//                 stream: _postRef.collection('comments')
//                     .orderBy('createdAt', descending: false).snapshots(),
//                 builder: (_, snapshot) {
//                   if (!snapshot.hasData) {
//                     return const Center(
//                         child: CircularProgressIndicator(color: _accent));
//                   }
//                   final allDocs  = snapshot.data!.docs;
//                   final topLevel = allDocs
//                       .where((d) => (d.data() as Map)['replyToId'] == null)
//                       .toList();
//
//                   if (topLevel.isEmpty) {
//                     return Center(child: Text('No comments yet. Be first!',
//                         style: TextStyle(color: _grey600)));
//                   }
//
//                   return ListView.builder(
//                     controller: scrollController,
//                     itemCount: topLevel.length,
//                     itemBuilder: (_, i) {
//                       final doc     = topLevel[i];
//                       final c       = doc.data() as Map<String, dynamic>;
//                       final isMe    = c['userId'] == _uid;
//                       final replies = allDocs
//                           .where((d) =>
//                       (d.data() as Map)['replyToId'] == doc.id)
//                           .toList();
//
//                       return Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           _CommentTile(
//                             commentId: doc.id, data: c,
//                             isMe: isMe, isGuest: _isGuest,
//                             onReply: () =>
//                                 _setReply(doc.id, c['username'] ?? ''),
//                             onDelete: isMe
//                                 ? () => _deleteComment(doc.id) : null,
//                           ),
//                           if (replies.isNotEmpty)
//                             Padding(
//                               padding: const EdgeInsets.only(left: 48),
//                               child: Column(
//                                 children: replies.map((r) {
//                                   final rd   = r.data() as Map<String, dynamic>;
//                                   final rMe  = rd['userId'] == _uid;
//                                   return _CommentTile(
//                                     commentId: r.id, data: rd,
//                                     isMe: rMe, isGuest: _isGuest,
//                                     isReply: true,
//                                     onReply: () =>
//                                         _setReply(doc.id, rd['username'] ?? ''),
//                                     onDelete: rMe
//                                         ? () => _deleteComment(r.id) : null,
//                                   );
//                                 }).toList(),
//                               ),
//                             ),
//                         ],
//                       );
//                     },
//                   );
//                 },
//               ),
//             ),
//             if (_replyToUsername != null)
//               Container(
//                 color: _surface,
//                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
//                 child: Row(children: [
//                   const Icon(Icons.reply, color: _accent, size: 16),
//                   const SizedBox(width: 6),
//                   Text('Replying to @$_replyToUsername',
//                       style: TextStyle(color: _grey600, fontSize: 12)),
//                   const Spacer(),
//                   GestureDetector(onTap: _clearReply,
//                       child: Icon(Icons.close, color: _grey600, size: 16)),
//                 ]),
//               ),
//             Container(
//               color: _surface,
//               padding: EdgeInsets.fromLTRB(12, 8, 12,
//                   MediaQuery.of(context).padding.bottom + 8),
//               child: Row(children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _commentController,
//                     enabled: !_isGuest,
//                     style: const TextStyle(color: _grey900),
//                     decoration: InputDecoration(
//                       hintText: _isGuest ? 'Sign in to comment...'
//                           : _replyToUsername != null
//                           ? 'Reply to @$_replyToUsername...'
//                           : 'Add a comment...',
//                       hintStyle: TextStyle(color: _grey600),
//                       filled: true,
//                       fillColor: _grey200,
//                       contentPadding: const EdgeInsets.symmetric(
//                           horizontal: 14, vertical: 10),
//                       border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(24),
//                           borderSide: BorderSide.none),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 _sending
//                     ? const SizedBox(width: 24, height: 24,
//                     child: CircularProgressIndicator(
//                         strokeWidth: 2, color: _accent))
//                     : IconButton(
//                     icon: const Icon(Icons.send, color: _accent),
//                     onPressed: _isGuest ? null : _sendComment),
//               ]),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // ── Comment tile ──────────────────────────────────────────────────────────────
//
// class _CommentTile extends StatelessWidget {
//   final String commentId;
//   final Map<String, dynamic> data;
//   final bool isMe;
//   final bool isGuest;
//   final bool isReply;
//   final VoidCallback onReply;
//   final VoidCallback? onDelete;
//
//   static const Color _grey200 = Color(0xFFEEEEEE);
//   static const Color _grey600 = Color(0xFF757575);
//   static const Color _grey900 = Color(0xFF212121);
//   static const Color _accent  = Color(0xFF1E88E5);
//
//   const _CommentTile({
//     required this.commentId,
//     required this.data,
//     required this.isMe,
//     required this.isGuest,
//     required this.onReply,
//     this.onDelete,
//     this.isReply = false,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final avatarUrl = data['avatarUrl'] as String? ?? '';
//     final username  = data['username']  as String? ?? 'Anonymous';
//     final text      = data['text']      as String? ?? '';
//
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           CircleAvatar(
//             radius: isReply ? 14 : 18,
//             backgroundColor: _grey200,
//             backgroundImage: avatarUrl.isNotEmpty
//                 ? NetworkImage(avatarUrl) : null,
//             child: avatarUrl.isEmpty
//                 ? Icon(Icons.person, color: _grey600,
//                 size: isReply ? 14 : 18)
//                 : null,
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(children: [
//                   Text(username, style: const TextStyle(color: _grey900,
//                       fontWeight: FontWeight.bold, fontSize: 13)),
//                   const Spacer(),
//                   if (onDelete != null)
//                     GestureDetector(onTap: onDelete,
//                         child: Icon(Icons.delete_outline,
//                             color: _grey600, size: 16)),
//                 ]),
//                 const SizedBox(height: 2),
//                 Text(text, style: TextStyle(color: _grey600, fontSize: 13)),
//                 const SizedBox(height: 4),
//                 if (!isGuest)
//                   GestureDetector(onTap: onReply,
//                       child: const Text('Reply',
//                           style: TextStyle(color: _accent, fontSize: 12,
//                               fontWeight: FontWeight.w600))),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // ── Stock icon display in post sheet ─────────────────────────────────────────
//
// class _PostIconDisplay extends StatelessWidget {
//   final String iconLabel;
//   const _PostIconDisplay({required this.iconLabel});
//
//   @override
//   Widget build(BuildContext context) {
//     final opt = kStockOptions.firstWhere(
//           (o) => o.label == iconLabel,
//       orElse: () => const StockOption(
//           Icons.photo_camera, Color(0xFF546E7A), 'photo'),
//     );
//     return Container(
//       width: double.infinity,
//       height: 280,
//       decoration: BoxDecoration(
//         color: opt.color.withOpacity(0.08),
//         border: Border.symmetric(
//           horizontal: BorderSide(color: opt.color.withOpacity(0.15)),
//         ),
//       ),
//       child: Center(
//         child: Icon(opt.icon, color: opt.color, size: 96),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'moderation_service.dart';
import '../posts/create_post_screen.dart';

class PostBottomSheet extends StatefulWidget {
  final Map<String, dynamic> post;
  final String postId;
  final String collection;

  const PostBottomSheet({
    super.key,
    required this.post,
    required this.postId,
    this.collection = 'posts',
  });

  @override
  State<PostBottomSheet> createState() => _PostBottomSheetState();
}

class _PostBottomSheetState extends State<PostBottomSheet>
    with TickerProviderStateMixin {
  static const Color _bg      = Color(0xFF0D0D0D);
  static const Color _surface = Color(0xFF1A1A1A);
  static const Color _accent  = Color(0xFF1E88E5);
  static const Color _yellow  = Color(0xFFFFD600);
  static const Color _red     = Color(0xFFD32F2F);

  bool _liked       = false;
  bool _disliked    = false;
  bool _reposted    = false;
  bool _saved       = false;
  int  _myRating    = 0;
  bool _isPostOwnerBlocked = false;

  // ── Animation controllers ──────────────────────────────────────────────────
  late final AnimationController _likeCtrl;
  late final AnimationController _dislikeCtrl;
  late final AnimationController _repostCtrl;
  late final AnimationController _saveCtrl;
  // Star controllers — one per star
  late final List<AnimationController> _starCtrls;

  final String _uid     = FirebaseAuth.instance.currentUser?.uid ?? '';
  final bool   _isGuest = FirebaseAuth.instance.currentUser == null;
  final ModerationService _moderationService = ModerationService();

  DocumentReference get _postRef =>
      FirebaseFirestore.instance.collection(widget.collection).doc(widget.postId);

  String get _postOwnerId => (widget.post['userId'] ?? '').toString();

  // ── Helpers ────────────────────────────────────────────────────────────────

  AnimationController _bounceCtrl() => AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );

  void _bounce(AnimationController ctrl) async {
    await ctrl.forward();
    await ctrl.reverse();
  }

  @override
  void initState() {
    super.initState();
    _likeCtrl    = _bounceCtrl();
    _dislikeCtrl = _bounceCtrl();
    _repostCtrl  = _bounceCtrl();
    _saveCtrl    = _bounceCtrl();
    _starCtrls   = List.generate(5, (_) => _bounceCtrl());

    if (!_isGuest) {
      _checkIfLiked();
      _checkIfReposted();
      _checkIfSaved();
      _loadMyRating();
      _checkIfDisliked();
      _checkIfOwnerBlocked();
    }
  }

  @override
  void dispose() {
    _likeCtrl.dispose();
    _dislikeCtrl.dispose();
    _repostCtrl.dispose();
    _saveCtrl.dispose();
    for (final c in _starCtrls) c.dispose();
    super.dispose();
  }

  // ── Firestore checks ───────────────────────────────────────────────────────

  Future<void> _checkIfLiked() async {
    final doc = await _postRef.collection('likedBy').doc(_uid).get();
    if (mounted) setState(() => _liked = doc.exists);
  }

  Future<void> _checkIfReposted() async {
    final doc = await _postRef.collection('repostedBy').doc(_uid).get();
    if (mounted) setState(() => _reposted = doc.exists);
  }

  Future<void> _checkIfSaved() async {
    final doc = await FirebaseFirestore.instance
        .collection('users').doc(_uid)
        .collection('saved').doc(widget.postId)
        .get();
    if (mounted) setState(() => _saved = doc.exists);
  }

  Future<void> _checkIfDisliked() async {
    try {
      final disliked = await _moderationService.hasUserDisliked(widget.postId);
      if (mounted) setState(() => _disliked = disliked);
    } catch (_) {}
  }

  Future<void> _checkIfOwnerBlocked() async {
    try {
      final isBlocked = await _moderationService.isUserBlocked(_postOwnerId);
      if (mounted) setState(() => _isPostOwnerBlocked = isBlocked);
    } catch (_) {}
  }

  Future<void> _loadMyRating() async {
    final doc = await _postRef.collection('ratings').doc(_uid).get();
    if (!mounted) return;
    final data = doc.data() as Map<String, dynamic>?;
    setState(() {
      _myRating = data?['rating'] is num ? (data!['rating'] as num).toInt() : 0;
    });
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _toggleLike() async {
    if (_isGuest) { _snackLoginRequired(); return; }
    HapticFeedback.lightImpact();
    _bounce(_likeCtrl);

    final batch = FirebaseFirestore.instance.batch();
    if (_liked) {
      batch.update(_postRef, {'likes': FieldValue.increment(-1)});
      batch.delete(_postRef.collection('likedBy').doc(_uid));
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
      batch.update(_postRef, {'likes': FieldValue.increment(1)});
      batch.set(
        _postRef.collection('likedBy').doc(_uid),
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

  Future<void> _toggleSave() async {
    if (_isGuest) { _snackLoginRequired(); return; }
    HapticFeedback.lightImpact();
    _bounce(_saveCtrl);

    final savedRef = FirebaseFirestore.instance
        .collection('users').doc(_uid)
        .collection('saved').doc(widget.postId);

    if (_saved) {
      await savedRef.delete();
      if (mounted) setState(() => _saved = false);
    } else {
      await savedRef.set({
        'savedAt': FieldValue.serverTimestamp(),
        'collection': widget.collection,
      });
      if (mounted) setState(() => _saved = true);
    }
  }

  Future<void> _toggleDislike() async {
    if (_isGuest) { _snackLoginRequired(); return; }
    if (!_disliked) {
      _showDislikeReasonDialog();
    } else {
      _bounce(_dislikeCtrl);
      try {
        await _moderationService.toggleDislike(widget.postId, null);
        if (mounted) setState(() => _disliked = false);
        _snack('Dislike removed');
      } catch (e) {
        _snack('Error: $e');
      }
    }
  }

  void _showDislikeReasonDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _surface,
        title: const Text('Why are you disliking this?',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DislikeReasonButton(label: 'Inappropriate Content',
                onTap: () { Navigator.pop(context); _addDislike('Inappropriate Content'); }),
            _DislikeReasonButton(label: 'Spam or Misleading',
                onTap: () { Navigator.pop(context); _addDislike('Spam or Misleading'); }),
            _DislikeReasonButton(label: 'Low Quality',
                onTap: () { Navigator.pop(context); _addDislike('Low Quality'); }),
            _DislikeReasonButton(label: 'Other',
                onTap: () { Navigator.pop(context); _addDislike('Other'); }),
          ],
        ),
      ),
    );
  }

  Future<void> _addDislike(String reason) async {
    HapticFeedback.lightImpact();
    _bounce(_dislikeCtrl);
    try {
      await _moderationService.toggleDislike(widget.postId, reason);
      if (mounted) {
        setState(() => _disliked = true);
        _snack('Dislike recorded. Thank you for helping improve the community!');
      }
    } catch (e) {
      _snack('Error: $e');
    }
  }

  Future<void> _toggleRepost() async {
    if (_isGuest) { _snackLoginRequired(); return; }
    HapticFeedback.lightImpact();
    _bounce(_repostCtrl);

    final batch = FirebaseFirestore.instance.batch();
    if (_reposted) {
      batch.update(_postRef, {'reposts': FieldValue.increment(-1)});
      batch.delete(_postRef.collection('repostedBy').doc(_uid));
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
      batch.update(_postRef, {'reposts': FieldValue.increment(1)});
      batch.set(
        _postRef.collection('repostedBy').doc(_uid),
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
    if (_isGuest) { _snackLoginRequired(); return; }
    HapticFeedback.selectionClick();

    // Animate the tapped star (and clear others)
    _bounce(_starCtrls[rating - 1]);

    final ratingRef = _postRef.collection('ratings').doc(_uid);
    final ownerRef  = FirebaseFirestore.instance.collection('users').doc(_postOwnerId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final postSnap   = await transaction.get(_postRef);
      final ratingSnap = await transaction.get(ratingRef);

      final postData  = postSnap.data() as Map<String, dynamic>? ?? {};
      final oldRating = ratingSnap.exists
          ? ((ratingSnap.data() as Map<String, dynamic>?)?['rating'] as num?)?.toInt() ?? 0
          : 0;

      if (oldRating == rating) return;

      final oldTotal  = (postData['ratingTotal'] as num?)?.toInt() ?? 0;
      final oldCount  = (postData['ratingCount'] as num?)?.toInt() ?? 0;
      final bonusGiven = postData['qualityBonusAwarded'] == true;

      transaction.set(ratingRef,
          {'rating': rating, 'updatedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true));

      int newTotal = oldTotal;
      int newCount = oldCount;

      if (oldRating == 0) {
        newTotal += rating;
        newCount += 1;
        transaction.update(_postRef, {
          'ratingTotal': FieldValue.increment(rating),
          'ratingCount': FieldValue.increment(1),
        });
        if (_postOwnerId.isNotEmpty && _postOwnerId != _uid) {
          transaction.set(ownerRef, {'score': FieldValue.increment(1)},
              SetOptions(merge: true));
        }
      } else {
        newTotal += rating - oldRating;
        transaction.update(_postRef,
            {'ratingTotal': FieldValue.increment(rating - oldRating)});
      }

      final avg = newCount > 0 ? newTotal / newCount : 0.0;
      if (!bonusGiven && newCount >= 3 && avg >= 4.0 &&
          _postOwnerId.isNotEmpty && _postOwnerId != _uid) {
        transaction.set(ownerRef, {'score': FieldValue.increment(2)},
            SetOptions(merge: true));
        transaction.set(_postRef, {'qualityBonusAwarded': true},
            SetOptions(merge: true));
      }
    });

    if (mounted) setState(() => _myRating = rating);
  }

  Future<void> _showBlockUserOptions() async {
    if (_isGuest) { _snackLoginRequired(); return; }
    showModalBottomSheet(
      context: context,
      backgroundColor: _bg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_isPostOwnerBlocked ? 'User Blocked' : 'Block User?',
                style: const TextStyle(color: Colors.white, fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (_isPostOwnerBlocked) ...[
              const Text('You have blocked this user.',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _unblockUser,
                  style: ElevatedButton.styleFrom(backgroundColor: _accent),
                  child: const Text('Unblock User')),
            ] else ...[
              const Text('Blocking this user will hide their posts from your feed.',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _blockUser,
                  style: ElevatedButton.styleFrom(backgroundColor: _red),
                  child: const Text('Block User')),
              const SizedBox(height: 8),
              OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24)),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.white))),
            ],
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
    } catch (e) { _snack('Error blocking user: $e'); }
  }

  Future<void> _unblockUser() async {
    try {
      await _moderationService.unblockUser(_postOwnerId);
      if (mounted) {
        setState(() => _isPostOwnerBlocked = false);
        Navigator.pop(context);
        _snack('User unblocked');
      }
    } catch (e) { _snack('Error unblocking user: $e'); }
  }

  void _openComments() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CommentsSheet(
        postId: widget.postId,
        postOwnerId: _postOwnerId,
        collection: widget.collection,
      ),
    );
  }

  void _snackLoginRequired() => ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sign in to interact with posts.')));

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  String _getReputationLabel(int score) {
    if (score >= 150) return 'Community Leader';
    if (score >= 75)  return 'Local Guide';
    if (score >= 25)  return 'Explorer';
    return 'Newcomer';
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final post      = widget.post;
    final avatarUrl = post['avatarUrl'] as String? ?? '';
    final username  = post['username']  as String? ?? 'Anonymous';
    final imageUrl  = post['imageUrl']  as String? ?? '';
    final caption   = post['caption']   as String? ?? '';
    final isRemoved = post['isRemoved'] as bool?   ?? false;

    if (isRemoved) {
      return Container(
        decoration: const BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.block, color: _red, size: 48),
            const SizedBox(height: 16),
            const Text('This post has been removed',
                style: TextStyle(color: Colors.white, fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(post['removalReason'] ?? 'Post removed by moderation',
                style: const TextStyle(color: Colors.white54, fontSize: 14),
                textAlign: TextAlign.center),
            const SizedBox(height: 40),
          ],
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),

          // Header
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
                      ? const Icon(Icons.person, color: Colors.white54) : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users').doc(_postOwnerId).get(),
                    builder: (context, snapshot) {
                      int score = 0;
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final d = snapshot.data!.data() as Map<String, dynamic>?;
                        final raw = d?['score'];
                        score = raw is num ? raw.toInt()
                            : int.tryParse(raw?.toString() ?? '') ?? 0;
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(username,
                              style: const TextStyle(color: Colors.white,
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text('${_getReputationLabel(score)} • Score $score',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12)),
                        ],
                      );
                    },
                  ),
                ),
                if (_uid != _postOwnerId)
                  IconButton(
                    icon: Icon(Icons.more_vert,
                        color: _isPostOwnerBlocked ? _red : Colors.white54),
                    onPressed: _showBlockUserOptions,
                  ),
              ],
            ),
          ),

          // Image / stock icon
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
                    child: CircularProgressIndicator(color: _accent)),
              ),
            )
          else if ((post['postIcon'] as String?) != null)
            _PostIconDisplay(iconLabel: post['postIcon'] as String),

          // Live stats + action buttons
          StreamBuilder<DocumentSnapshot>(
            stream: _postRef.snapshots(),
            builder: (context, snapshot) {
              final data        = snapshot.data?.data() as Map<String, dynamic>?;
              final likes       = (data?['likes']       as num?)?.toInt() ?? 0;
              final comments    = (data?['comments']    as num?)?.toInt() ?? 0;
              final reposts     = (data?['reposts']     as num?)?.toInt() ?? 0;
              final dislikes    = (data?['dislikes']    as num?)?.toInt() ?? 0;
              final ratingTotal = (data?['ratingTotal'] as num?) ?? 0;
              final ratingCount = (data?['ratingCount'] as num?) ?? 0;
              final avg = ratingCount > 0
                  ? ratingTotal.toDouble() / ratingCount.toDouble() : 0.0;

              return Column(
                children: [
                  // Rating row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
                    child: Row(children: [
                      const Text('Area Rating',
                          style: TextStyle(color: Colors.white,
                              fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(width: 10),
                      if (ratingCount > 0) ...[
                        Text('${avg.toStringAsFixed(1)} ★',
                            style: const TextStyle(color: _yellow,
                                fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(width: 8),
                      ],
                      Text(
                          ratingCount > 0
                              ? '(${ratingCount.toInt()} ratings)'
                              : 'No ratings yet',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12)),
                    ]),
                  ),

                  // ── Animated star row ──────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
                    child: Row(
                      children: List.generate(5, (i) {
                        final val    = i + 1;
                        final filled = val <= _myRating;
                        return _BounceButton(
                          controller: _starCtrls[i],
                          onTap: _isGuest
                              ? _snackLoginRequired
                              : () => _submitRating(val),
                          child: Icon(
                            filled ? Icons.star : Icons.star_border,
                            color: _yellow, size: 28,
                          ),
                        );
                      }),
                    ),
                  ),

                  // ── Animated action bar ────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    child: Row(children: [
                      _BounceButton(
                        controller: _likeCtrl,
                        onTap: _toggleLike,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _liked ? Icons.favorite : Icons.favorite_border,
                              color: _liked ? Colors.redAccent : Colors.white70,
                              size: 26,
                            ),
                            const SizedBox(width: 5),
                            Text('$likes',
                                style: TextStyle(
                                  color: _liked ? Colors.redAccent : Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),

                      // Comments — no dedicated controller needed (opens sheet)
                      _ActionButton(
                        icon: Icons.chat_bubble_outline,
                        color: Colors.white70,
                        count: comments,
                        onTap: _openComments,
                      ),
                      const SizedBox(width: 4),

                      _BounceButton(
                        controller: _repostCtrl,
                        onTap: _toggleRepost,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.repeat,
                              color: _reposted ? _yellow : Colors.white70,
                              size: 26,
                            ),
                            const SizedBox(width: 5),
                            Text('$reposts',
                                style: TextStyle(
                                  color: _reposted ? _yellow : Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),

                      _BounceButton(
                        controller: _dislikeCtrl,
                        onTap: _toggleDislike,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _disliked
                                  ? Icons.thumb_down : Icons.thumb_down_outlined,
                              color: _disliked ? _red : Colors.white70,
                              size: 26,
                            ),
                            const SizedBox(width: 5),
                            Text('$dislikes',
                                style: TextStyle(
                                  color: _disliked ? _red : Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                )),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // ── Animated save button ─────────────────────────
                      _BounceButton(
                        controller: _saveCtrl,
                        onTap: _toggleSave,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        child: Icon(
                          _saved ? Icons.bookmark : Icons.bookmark_border,
                          color: _saved ? _accent : Colors.white70,
                          size: 26,
                        ),
                      ),
                    ]),
                  ),

                  if (dislikes >= 3)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _red.withOpacity(0.3)),
                        ),
                        child: Row(children: [
                          Icon(Icons.warning_outlined, color: _red, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                                'This post has received many dislikes ($dislikes)',
                                style: TextStyle(
                                    color: _red.withOpacity(0.8), fontSize: 12)),
                          ),
                        ]),
                      ),
                    ),
                ],
              );
            },
          ),

          // Caption
          if (caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: RichText(
                  text: TextSpan(children: [
                    TextSpan(text: '$username ',
                        style: const TextStyle(color: Colors.white,
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    TextSpan(text: caption,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14)),
                  ]),
                ),
              ),
            ),

          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

// ── Bounce button (scale animation) ──────────────────────────────────────────

class _BounceButton extends StatelessWidget {
  final AnimationController controller;
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _BounceButton({
    required this.controller,
    required this.onTap,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, child) {
          // Maps 0→1→0 animation to scale 1.0→1.35→1.0
          final scale = 1.0 + (0.35 * Curves.easeOut.transform(
              controller.value <= 0.5
                  ? controller.value * 2
                  : (1.0 - controller.value) * 2));
          return Transform.scale(scale: scale, child: child);
        },
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

// ── Plain action button (used for comments, no bounce controller needed) ──────

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
        child: Row(children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 5),
          Text('$count',
              style: TextStyle(color: color, fontSize: 14,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

// ── Dislike reason button ─────────────────────────────────────────────────────

class _DislikeReasonButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DislikeReasonButton({required this.label, required this.onTap});

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
              foregroundColor: Colors.white),
          child: Text(label),
        ),
      ),
    );
  }
}

// ── Comments sheet ────────────────────────────────────────────────────────────

class _CommentsSheet extends StatefulWidget {
  final String postId;
  final String postOwnerId;
  final String collection;

  const _CommentsSheet({
    required this.postId,
    required this.postOwnerId,
    this.collection = 'posts',
  });

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  static const Color _bg      = Color(0xFF0D0D0D);
  static const Color _surface = Color(0xFF1A1A1A);
  static const Color _accent  = Color(0xFF1E88E5);

  final _commentController = TextEditingController();
  bool    _sending = false;
  String? _replyToId;
  String? _replyToUsername;

  final String? _uid     = FirebaseAuth.instance.currentUser?.uid;
  final bool    _isGuest = FirebaseAuth.instance.currentUser == null;

  DocumentReference get _postRef => FirebaseFirestore.instance
      .collection(widget.collection).doc(widget.postId);

  void _setReply(String commentId, String username) {
    setState(() { _replyToId = commentId; _replyToUsername = username; });
    FocusScope.of(context).unfocus();
  }

  void _clearReply() =>
      setState(() { _replyToId = null; _replyToUsername = null; });

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isGuest) return;
    setState(() => _sending = true);

    final user  = FirebaseAuth.instance.currentUser!;
    final batch = FirebaseFirestore.instance.batch();

    batch.set(_postRef.collection('comments').doc(), {
      'userId':    user.uid,
      'username':  user.displayName ?? 'Anonymous',
      'avatarUrl': user.photoURL ?? '',
      'text':      text,
      'replyToId': _replyToId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(_postRef, {'comments': FieldValue.increment(1)});

    await batch.commit();
    _commentController.clear();
    _clearReply();
    if (mounted) setState(() => _sending = false);
  }

  Future<void> _deleteComment(String commentId) async {
    final batch = FirebaseFirestore.instance.batch();
    batch.delete(_postRef.collection('comments').doc(commentId));
    batch.update(_postRef, {'comments': FieldValue.increment(-1)});
    await batch.commit();
  }

  @override
  void dispose() { _commentController.dispose(); super.dispose(); }

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
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white24,
                borderRadius: BorderRadius.circular(2)),
          ),
          const Text('Comments', style: TextStyle(color: Colors.white,
              fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(color: Colors.white12, height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _postRef.collection('comments')
                  .orderBy('createdAt', descending: false).snapshots(),
              builder: (_, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: _accent));
                }
                final allDocs  = snapshot.data!.docs;
                final topLevel = allDocs
                    .where((d) => (d.data() as Map)['replyToId'] == null)
                    .toList();

                if (topLevel.isEmpty) {
                  return const Center(child: Text('No comments yet. Be first!',
                      style: TextStyle(color: Colors.white38)));
                }

                return ListView.builder(
                  controller: scrollController,
                  itemCount: topLevel.length,
                  itemBuilder: (_, i) {
                    final doc     = topLevel[i];
                    final c       = doc.data() as Map<String, dynamic>;
                    final isMe    = c['userId'] == _uid;
                    final replies = allDocs
                        .where((d) =>
                    (d.data() as Map)['replyToId'] == doc.id)
                        .toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CommentTile(
                          commentId: doc.id, data: c,
                          isMe: isMe, isGuest: _isGuest,
                          onReply: () =>
                              _setReply(doc.id, c['username'] ?? ''),
                          onDelete: isMe ? () => _deleteComment(doc.id) : null,
                        ),
                        if (replies.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 48),
                            child: Column(
                              children: replies.map((r) {
                                final rd   = r.data() as Map<String, dynamic>;
                                final rMe  = rd['userId'] == _uid;
                                return _CommentTile(
                                  commentId: r.id, data: rd,
                                  isMe: rMe, isGuest: _isGuest,
                                  isReply: true,
                                  onReply: () =>
                                      _setReply(doc.id, rd['username'] ?? ''),
                                  onDelete: rMe
                                      ? () => _deleteComment(r.id) : null,
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
              child: Row(children: [
                const Icon(Icons.reply, color: _accent, size: 16),
                const SizedBox(width: 6),
                Text('Replying to @$_replyToUsername',
                    style: const TextStyle(color: Colors.white60, fontSize: 12)),
                const Spacer(),
                GestureDetector(onTap: _clearReply,
                    child: const Icon(Icons.close,
                        color: Colors.white38, size: 16)),
              ]),
            ),
          Container(
            color: _bg,
            padding: EdgeInsets.fromLTRB(12, 8, 12,
                MediaQuery.of(context).padding.bottom + 8),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  enabled: !_isGuest,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: _isGuest ? 'Sign in to comment...'
                        : _replyToUsername != null
                        ? 'Reply to @$_replyToUsername...'
                        : 'Add a comment...',
                    hintStyle: const TextStyle(color: Colors.white30),
                    filled: true, fillColor: _surface,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _sending
                  ? const SizedBox(width: 24, height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _accent))
                  : IconButton(
                  icon: const Icon(Icons.send, color: _accent),
                  onPressed: _isGuest ? null : _sendComment),
            ]),
          ),
        ],
      ),
    );
  }
}

// ── Comment tile ──────────────────────────────────────────────────────────────

class _CommentTile extends StatelessWidget {
  final String commentId;
  final Map<String, dynamic> data;
  final bool isMe;
  final bool isGuest;
  final bool isReply;
  final VoidCallback onReply;
  final VoidCallback? onDelete;

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
                ? Icon(Icons.person, color: Colors.white54,
                size: isReply ? 14 : 18)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(username, style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.bold, fontSize: 13)),
                  const Spacer(),
                  if (onDelete != null)
                    GestureDetector(onTap: onDelete,
                        child: const Icon(Icons.delete_outline,
                            color: Colors.white30, size: 16)),
                ]),
                const SizedBox(height: 2),
                Text(text, style: const TextStyle(
                    color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                if (!isGuest)
                  GestureDetector(onTap: onReply,
                      child: const Text('Reply',
                          style: TextStyle(color: _accent, fontSize: 12,
                              fontWeight: FontWeight.w600))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stock icon display ────────────────────────────────────────────────────────

class _PostIconDisplay extends StatelessWidget {
  final String iconLabel;
  const _PostIconDisplay({required this.iconLabel});

  @override
  Widget build(BuildContext context) {
    final opt = kStockOptions.firstWhere(
          (o) => o.label == iconLabel,
      orElse: () => const StockOption(
          Icons.photo_camera, Color(0xFF546E7A), 'photo'),
    );
    return Container(
      width: double.infinity,
      height: 280,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            opt.color.withOpacity(0.30),
            opt.color.withOpacity(0.07),
          ],
        ),
      ),
      child: Center(
        child: Icon(opt.icon, color: opt.color, size: 96),
      ),
    );
  }
}