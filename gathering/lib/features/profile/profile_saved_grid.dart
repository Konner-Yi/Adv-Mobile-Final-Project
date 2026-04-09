import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../posts/post_bottom_sheet.dart';

class ProfileSavedGrid extends StatelessWidget {
  final String uid;
  const ProfileSavedGrid({super.key, required this.uid});

  static const Color _bg      = Color(0xFF0D0D0D);
  static const Color _surface = Color(0xFF1A1A1A);
  static const Color _accent  = Color(0xFF1E88E5);
  static const Color grey200  = Color(0xFFEEEEEE);
  static const Color grey400  = Color(0xFFBDBDBD);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('saved')
          .orderBy('savedAt', descending: true)
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
                Icon(Icons.bookmark_border, size: 48, color: grey200),
                SizedBox(height: 10),
                Text('No saved posts yet', style: TextStyle(color: grey400, fontSize: 14)),
                SizedBox(height: 6),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Tap the bookmark on any post to save it here',
                    style: TextStyle(color: grey400, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
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
          itemCount: docs.length,
            itemBuilder: (context, i) {
              final savedDoc  = docs[i];
              final postId    = savedDoc.id;
              final savedData = savedDoc.data() as Map<String, dynamic>;                    // ADD
              final collection = savedData['collection'] as String? ?? 'posts';             // ADD

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection(collection)                                                  // CHANGE: was 'posts'
                    .doc(postId)
                    .get(),
                builder: (context, postSnap) {
                  if (!postSnap.hasData) return Container(color: const Color(0xFFEEEEEE));
                  if (!postSnap.data!.exists) return const SizedBox.shrink();

                  final data      = postSnap.data!.data() as Map<String, dynamic>;
                  final imageUrl  = data['imageUrl'] as String? ?? '';
                  final isRemoved = data['isRemoved'] as bool? ?? false;
                  if (isRemoved) return const SizedBox.shrink();

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (_) => PostBottomSheet(
                          post: {...data, 'postId': postId},
                          postId: postId,
                          collection: collection,                                            // ADD
                        ),
                      );
                    },
                    child: Stack(                                                            // unchanged below
                      fit: StackFit.expand,
                      children: [
                        imageUrl.isNotEmpty
                            ? Image.network(imageUrl, fit: BoxFit.cover)
                            : Container(color: _surface,
                            child: const Icon(Icons.photo, color: Colors.white24)),
                        const Positioned(
                          top: 6, right: 6,
                          child: Icon(Icons.bookmark, color: _accent, size: 16,
                              shadows: [Shadow(color: Colors.black54, blurRadius: 4)]),
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