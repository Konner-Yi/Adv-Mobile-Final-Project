import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../posts/post_bottom_sheet.dart';

class ProfilePostsGrid extends StatelessWidget {
  final String uid;
  const ProfilePostsGrid({super.key, required this.uid});

  static const Color _bg      = Color(0xFF0D0D0D);
  static const Color _surface = Color(0xFF1A1A1A);
  static const Color _accent  = Color(0xFF1E88E5);
  static const Color grey200  = Color(0xFFEEEEEE);
  static const Color grey400  = Color(0xFFBDBDBD);

  @override
  Widget build(BuildContext context) {
    print('ProfilePostsGrid building with uid: "$uid"');
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: uid)
          //.where('isRemoved', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator(color: _accent)),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Column(
              children: [
                Icon(Icons.grid_off_outlined, size: 48, color: grey200),
                SizedBox(height: 10),
                Text('No posts yet', style: TextStyle(color: grey400, fontSize: 14)),
              ],
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 3,
            mainAxisSpacing: 3,
          ),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final doc  = docs[i];
            final data = doc.data() as Map<String, dynamic>;
            final imageUrl = data['imageUrl'] as String? ?? '';
            final likes    = data['likes']    as int?    ?? 0;

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                final collection = data.containsKey('placeId') ? 'place_posts' : 'posts';
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (_) => PostBottomSheet(
                    post: {...data, 'postId': doc.id},
                    postId: doc.id,
                    collection: collection,
                  ),
                );
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  imageUrl.isNotEmpty
                      ? Image.network(imageUrl, fit: BoxFit.cover)
                      : Container(color: _surface,
                      child: const Icon(Icons.photo, color: Colors.white24)),
                  // Like count overlay
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Row(
                      children: [
                        const Icon(Icons.favorite, color: Colors.white, size: 13),
                        const SizedBox(width: 3),
                        Text(
                          '$likes',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}