// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class CreatePostScreen extends StatefulWidget {
//   final LatLng pinnedLocation;
//
//   /// If set, the post is saved to `place_posts` and tagged with this placeId.
//   /// If null, saves to the regular `posts` collection (free map post).
//   final String? placeId;
//
//   const CreatePostScreen({
//     super.key,
//     required this.pinnedLocation,
//     this.placeId,
//   });
//
//   @override
//   State<CreatePostScreen> createState() => _CreatePostScreenState();
// }
//
// class _CreatePostScreenState extends State<CreatePostScreen> {
//   File? _pickedImage;
//   final _captionController = TextEditingController();
//   bool _isLoading = false;
//
//   // ── Theme ───────────────────────────────────────────────────
//   static const Color _bg      = Color(0xFF0D0D0D);
//   static const Color _surface = Color(0xFF1A1A1A);
//   static const Color _accent  = Color(0xFF1E88E5);
//   static const Color _yellow  = Color(0xFFFFD600);
//
//   bool get _isPlacePost => widget.placeId != null;
//
//   Future<void> _pickImage() async {
//     final picked = await ImagePicker().pickImage(
//       source: ImageSource.gallery,
//       imageQuality: 80,
//     );
//     if (picked != null) {
//       setState(() => _pickedImage = File(picked.path));
//     }
//   }
//
//   Future<void> _submitPost() async {
//     if (_captionController.text.trim().isEmpty) {
//       _snack('Please add a caption.');
//       return;
//     }
//
//     if (_pickedImage == null) {
//       _snack('Please add a photo.');
//       return;
//     }
//
//     setState(() => _isLoading = true);
//
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user == null) {
//         _snack('You must be logged in to post.');
//         setState(() => _isLoading = false);
//         return;
//       }
//
//       // Use correct collection based on whether this is a place post
//       final collection = _isPlacePost ? 'place_posts' : 'posts';
//       final postId = FirebaseFirestore.instance.collection(collection).doc().id;
//
//       // 1 — Upload image
//       final ref = FirebaseStorage.instance.ref().child('$collection/$postId.jpg');
//       await ref.putFile(_pickedImage!);
//       final imageUrl = await ref.getDownloadURL();
//
//       // 2 — Build the document with moderation fields
//       final docData = <String, dynamic>{
//         'userId': user.uid,
//         'username': user.displayName ?? 'Anonymous',
//         'avatarUrl': user.photoURL ?? '',
//         'imageUrl': imageUrl,
//         'caption': _captionController.text.trim(),
//         'lat': widget.pinnedLocation.latitude,
//         'lng': widget.pinnedLocation.longitude,
//         'likes': 0,
//         'dislikes': 0,
//         'comments': 0,
//         'reposts': 0,
//         'ratingTotal': 0,
//         'ratingCount': 0,
//         'createdAt': FieldValue.serverTimestamp(),
//         'isRemoved': false,
//         'removalReason': null,
//         'removedAt': null,
//       };
//
//       if (_isPlacePost) {
//         docData['placeId'] = widget.placeId;
//       }
//
//       final batch = FirebaseFirestore.instance.batch();
//
//       batch.set(
//         FirebaseFirestore.instance.collection(collection).doc(postId),
//         docData,
//       );
//
//       batch.set(
//         FirebaseFirestore.instance.collection('users').doc(user.uid),
//         {'score': FieldValue.increment(5)},
//         SetOptions(merge: true),
//       );
//
//       await batch.commit();
//
//       if (mounted) Navigator.pop(context, true);
//     } catch (e) {
//       _snack('Error: $e');
//       setState(() => _isLoading = false);
//     }
//   }
//
//   void _snack(String msg) =>
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: _bg,
//       appBar: AppBar(
//         backgroundColor: _bg,
//         foregroundColor: Colors.white,
//         elevation: 0,
//         title: Text(
//           _isPlacePost ? 'Post at this place' : 'New Post',
//           style: const TextStyle(fontWeight: FontWeight.bold),
//         ),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 12),
//             child: _isLoading
//                 ? const Center(
//               child: SizedBox(
//                 width: 20,
//                 height: 20,
//                 child: CircularProgressIndicator(
//                   strokeWidth: 2,
//                   color: _accent,
//                 ),
//               ),
//             )
//                 : TextButton(
//               onPressed: _submitPost,
//               child: const Text(
//                 'Share',
//                 style: TextStyle(
//                   color: _accent,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             GestureDetector(
//               onTap: _isLoading ? null : _pickImage,
//               child: AnimatedContainer(
//                 duration: const Duration(milliseconds: 200),
//                 width: double.infinity,
//                 height: 280,
//                 decoration: BoxDecoration(
//                   color: _surface,
//                   borderRadius: BorderRadius.circular(18),
//                   border: Border.all(
//                     color: _pickedImage != null ? _accent : Colors.white12,
//                     width: _pickedImage != null ? 2 : 1,
//                   ),
//                 ),
//                 child: _pickedImage != null
//                     ? ClipRRect(
//                   borderRadius: BorderRadius.circular(17),
//                   child: Image.file(
//                     _pickedImage!,
//                     fit: BoxFit.cover,
//                   ),
//                 )
//                     : Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: _accent.withOpacity(0.1),
//                         shape: BoxShape.circle,
//                       ),
//                       child: const Icon(
//                         Icons.add_photo_alternate_outlined,
//                         color: _accent,
//                         size: 40,
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     const Text(
//                       'Add a photo',
//                       style: TextStyle(
//                         color: Colors.white70,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     const Text(
//                       'Tap to pick from gallery',
//                       style: TextStyle(
//                         color: Colors.white30,
//                         fontSize: 12,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//             TextField(
//               controller: _captionController,
//               maxLines: 4,
//               enabled: !_isLoading,
//               style: const TextStyle(color: Colors.white),
//               decoration: InputDecoration(
//                 hintText: 'Write a caption...',
//                 hintStyle: const TextStyle(color: Colors.white30),
//                 filled: true,
//                 fillColor: _surface,
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(14),
//                   borderSide: BorderSide.none,
//                 ),
//                 focusedBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(14),
//                   borderSide: const BorderSide(color: _accent, width: 1.5),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//               decoration: BoxDecoration(
//                 color: _surface,
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: _yellow.withOpacity(0.4)),
//               ),
//               child: Row(
//                 children: [
//                   const Icon(Icons.location_on, color: _yellow, size: 18),
//                   const SizedBox(width: 8),
//                   Text(
//                     '${widget.pinnedLocation.latitude.toStringAsFixed(5)}, '
//                         '${widget.pinnedLocation.longitude.toStringAsFixed(5)}',
//                     style: const TextStyle(
//                       color: Colors.white70,
//                       fontSize: 13,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _captionController.dispose();
//     super.dispose();
//   }
// }

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ── Stock icon definitions ────────────────────────────────────────────────────
class StockOption {
  final IconData icon;
  final Color color;
  final String label;
  const StockOption(this.icon, this.color, this.label);
}

const List<StockOption> kStockOptions = [
  StockOption(Icons.restaurant,      Color(0xFFE53935), 'food'),
  StockOption(Icons.local_cafe,      Color(0xFF795548), 'coffee'),
  StockOption(Icons.local_bar,       Color(0xFF8E24AA), 'nightlife'),
  StockOption(Icons.park,            Color(0xFF43A047), 'nature'),
  StockOption(Icons.location_city,   Color(0xFF1E88E5), 'city'),
  StockOption(Icons.fitness_center,  Color(0xFFF57C00), 'fitness'),
  StockOption(Icons.music_note,      Color(0xFFD81B60), 'music'),
  StockOption(Icons.shopping_bag,    Color(0xFF00ACC1), 'shopping'),
  StockOption(Icons.photo_camera,    Color(0xFF546E7A), 'photo'),
  StockOption(Icons.directions_run,  Color(0xFFFF7043), 'outdoors'),
];

class CreatePostScreen extends StatefulWidget {
  final LatLng pinnedLocation;
  final String? placeId;

  const CreatePostScreen({
    super.key,
    required this.pinnedLocation,
    this.placeId,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  File? _pickedImage;
  int?  _selectedStockIndex;

  final _captionController = TextEditingController();
  bool _isLoading = false;

  static const Color _bg      = Color(0xFF0D0D0D);
  static const Color _surface = Color(0xFF1A1A1A);
  static const Color _accent  = Color(0xFF1E88E5);
  static const Color _yellow  = Color(0xFFFFD600);

  bool get _isPlacePost => widget.placeId != null;
  bool get _hasContent  => _pickedImage != null || _selectedStockIndex != null;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        _pickedImage         = File(picked.path);
        _selectedStockIndex  = null; // clear stock selection
      });
    }
  }

  void _selectStock(int index) {
    setState(() {
      _selectedStockIndex = _selectedStockIndex == index ? null : index;
      _pickedImage        = null; // clear photo selection
    });
  }

  Future<void> _submitPost() async {
    if (_captionController.text.trim().isEmpty) {
      _snack('Please add a caption.');
      return;
    }
    if (!_hasContent) {
      _snack('Please add a photo or choose a stock icon.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _snack('You must be logged in to post.');
        setState(() => _isLoading = false);
        return;
      }

      final collection = _isPlacePost ? 'place_posts' : 'posts';
      final postId     = FirebaseFirestore.instance.collection(collection).doc().id;

      // Upload real image if one was picked, otherwise leave imageUrl empty
      String imageUrl = '';
      if (_pickedImage != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('$collection/$postId.jpg');
        await ref.putFile(_pickedImage!);
        imageUrl = await ref.getDownloadURL();
      }

      final docData = <String, dynamic>{
        'userId':    user.uid,
        'username':  user.displayName ?? 'Anonymous',
        'avatarUrl': user.photoURL ?? '',
        'imageUrl':  imageUrl,
        // stock icon key — null when a real photo was used
        'postIcon':  _pickedImage == null
            ? kStockOptions[_selectedStockIndex!].label
            : null,
        'caption':   _captionController.text.trim(),
        'lat':       widget.pinnedLocation.latitude,
        'lng':       widget.pinnedLocation.longitude,
        'likes':        0,
        'dislikes':     0,
        'comments':     0,
        'reposts':      0,
        'ratingTotal':  0,
        'ratingCount':  0,
        'createdAt':    FieldValue.serverTimestamp(),
        'isRemoved':    false,
        'removalReason': null,
        'removedAt':    null,
      };
      if (_isPlacePost) docData['placeId'] = widget.placeId;

      final batch = FirebaseFirestore.instance.batch();
      batch.set(
        FirebaseFirestore.instance.collection(collection).doc(postId),
        docData,
      );
      batch.set(
        FirebaseFirestore.instance.collection('users').doc(user.uid),
        {'score': FieldValue.increment(5)},
        SetOptions(merge: true),
      );
      await batch.commit();

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _snack('Error: $e');
      setState(() => _isLoading = false);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _isPlacePost ? 'Post at this place' : 'New Post',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _isLoading
                ? const Center(
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: _accent),
              ),
            )
                : TextButton(
              onPressed: _submitPost,
              child: const Text(
                'Share',
                style: TextStyle(
                    color: _accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Photo picker / preview ───────────────────────────────────
            GestureDetector(
              onTap: _isLoading ? null : _pickImage,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                height: 240,
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _pickedImage != null
                        ? _accent
                        : _selectedStockIndex != null
                        ? Colors.white12
                        : Colors.white12,
                    width: _pickedImage != null ? 2 : 1,
                  ),
                ),
                child: _pickedImage != null
                // Real photo preview
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child: Image.file(_pickedImage!, fit: BoxFit.cover),
                )
                    : _selectedStockIndex != null
                // Stock icon "preview"
                    ? StockPreview(
                    option: kStockOptions[_selectedStockIndex!])
                // Empty state
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                          Icons.add_photo_alternate_outlined,
                          color: _accent, size: 36),
                    ),
                    const SizedBox(height: 10),
                    const Text('Tap to add a photo',
                        style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    const Text('or choose a stock icon below',
                        style: TextStyle(
                            color: Colors.white30, fontSize: 12)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Stock icon row ───────────────────────────────────────────
            const Text(
              'Stock icons',
              style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: kStockOptions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final opt      = kStockOptions[i];
                  final selected = _selectedStockIndex == i;
                  return GestureDetector(
                    onTap: _isLoading ? null : () => _selectStock(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: selected
                            ? opt.color
                            : opt.color.withOpacity(0.18),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? opt.color : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: selected
                            ? [
                          BoxShadow(
                            color: opt.color.withOpacity(0.45),
                            blurRadius: 10,
                          )
                        ]
                            : [],
                      ),
                      child: Icon(opt.icon,
                          color: selected ? Colors.white : opt.color,
                          size: 26),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // ── Caption ──────────────────────────────────────────────────
            TextField(
              controller: _captionController,
              maxLines: 4,
              enabled: !_isLoading,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Write a caption...',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: _surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                  const BorderSide(color: _accent, width: 1.5),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Location chip ────────────────────────────────────────────
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _yellow.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: _yellow, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.pinnedLocation.latitude.toStringAsFixed(5)}, '
                        '${widget.pinnedLocation.longitude.toStringAsFixed(5)}',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }
}

// ── Stock icon "preview" shown in the large picker area ───────────────────────
class StockPreview extends StatelessWidget {
  final StockOption option;
  const StockPreview({required this.option});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        gradient: RadialGradient(
          colors: [
            option.color.withOpacity(0.35),
            option.color.withOpacity(0.08),
          ],
        ),
      ),
      child: Center(
        child: Icon(option.icon, color: option.color, size: 72),
      ),
    );
  }
}