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
          .snapshots(),
      builder: (context, postsSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('place_posts')
              .where('userId', isEqualTo: uid)
              .snapshots(),
          builder: (context, placeSnap) {
            if (postsSnap.connectionState == ConnectionState.waiting ||
                placeSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final postsDocs = postsSnap.data?.docs ?? [];
            final placeDocs = placeSnap.data?.docs ?? [];

            // 🔥 Merge both lists
            final allDocs = [...postsDocs, ...placeDocs];

            // 🔥 Sort manually (VERY IMPORTANT)
            allDocs.sort((a, b) {
              final aTime = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
              final bTime = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
              return bTime.compareTo(aTime);
            });

            if (allDocs.isEmpty) {
              return const Center(child: Text('No posts yet'));
            }

            return GridView.builder(
              padding: EdgeInsets.fromLTRB(
                12,
                12,
                12,
                MediaQuery.of(context).padding.bottom + 80,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 3,
                mainAxisSpacing: 3,
              ),
              itemCount: allDocs.length,
              itemBuilder: (context, i) {
                final doc  = allDocs[i];
                final data = doc.data() as Map<String, dynamic>;

                final imageUrl = data['imageUrl'] as String? ?? '';
                final likes    = data['likes'] as int? ?? 0;

                final isPlacePost = data.containsKey('placeId');
                final collection = isPlacePost ? 'place_posts' : 'posts';

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
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
      },
    );
  }
}