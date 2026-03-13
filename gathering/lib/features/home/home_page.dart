// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
//
// class HomePage extends StatelessWidget {
//   final VoidCallback onOpenMap;
//
//   const HomePage({
//     super.key,
//     required this.onOpenMap,
//   });
//
//   // Bright theme accents
//   static const Color cyan = Color(0xFF00C6FF);
//   static const Color purple = Color(0xFF7F00FF);
//   static const Color heading = Color(0xFF00E5FF);
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // Lets the gradient show through
//       backgroundColor: Colors.transparent,
//
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF3949AB),
//         elevation: 0,
//         title: const Text(
//           'Local Link',
//           style: TextStyle(
//             color: Color(0xFF00E5FF),
//             fontWeight: FontWeight.bold,
//             letterSpacing: 1.2,
//           ),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.notifications, color: cyan),
//             onPressed: () {
//               // Notifications
//             },
//           ),
//           IconButton(
//             icon: const Icon(Icons.account_circle, color: cyan),
//             onPressed: () {
//               // Profile
//             },
//           ),
//         ],
//       ),
//
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Color(0xFF5C6BC0),
//               Color(0xFF5C6BC0),
//             ],
//           ),
//         ),
//         child: Column(
//           children: [
//             // Search bar
//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: Container(
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(28),
//                   color: Colors.white,
//                   boxShadow: [
//                     BoxShadow(
//                       color: cyan.withOpacity(0.15),
//                       blurRadius: 12,
//                       offset: const Offset(0, 6),
//                     ),
//                   ],
//                 ),
//                 child: TextField(
//                   decoration: InputDecoration(
//                     hintText: 'Search for places...',
//                     prefixIcon: const Icon(Icons.search, color: cyan),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(28),
//                       borderSide: BorderSide.none,
//                     ),
//                     filled: true,
//                     fillColor: Colors.white,
//                   ),
//                 ),
//               ),
//             ),
//
//             // Map preview
//             Expanded(
//               child: Container(
//                 margin: const EdgeInsets.symmetric(horizontal: 16),
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(22),
//                   image: const DecorationImage(
//                     image: NetworkImage(
//                       'https://images.unsplash.com/photo-1526778548025-fa2f459cd5c1?auto=format&fit=crop&w=800',
//                     ),
//                     fit: BoxFit.cover,
//                   ),
//                   boxShadow: [
//                     BoxShadow(
//                       color: purple.withOpacity(0.22),
//                       blurRadius: 18,
//                       offset: const Offset(0, 10),
//                     ),
//                   ],
//                 ),
//                 child: Center(
//                   child: ElevatedButton.icon(
//                     onPressed: () {
//                       HapticFeedback.mediumImpact();
//                       onOpenMap();
//                     },
//                     icon: const Icon(Icons.map),
//                     label: const Text('Open Interactive Map'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: cyan,
//                       foregroundColor: Colors.white,
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 26,
//                         vertical: 13,
//                       ),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(30),
//                       ),
//                       elevation: 8,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//
//             // Categories
//             const Padding(
//               padding: EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Categories',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: HomePage.heading,
//                     ),
//                   ),
//                   SizedBox(height: 10),
//                   SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: Row(
//                       children: [
//                         CategoryChip(icon: Icons.restaurant, label: 'Food'),
//                         SizedBox(width: 10),
//                         CategoryChip(icon: Icons.local_cafe, label: 'Coffee'),
//                         SizedBox(width: 10),
//                         CategoryChip(icon: Icons.park, label: 'Parks'),
//                         SizedBox(width: 10),
//                         CategoryChip(icon: Icons.shopping_bag, label: 'Shopping'),
//                         SizedBox(width: 10),
//                         CategoryChip(icon: Icons.nightlife, label: 'Nightlife'),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//
//             // Recent places
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Nearby Places',
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: heading,
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     Expanded(
//                       child: ListView(
//                         children: const [
//                           PlaceCard(
//                             name: 'Central Park Cafe',
//                             category: 'Coffee • 0.5 mi',
//                             imageUrl:
//                                 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&w=400',
//                           ),
//                           PlaceCard(
//                             name: 'Sunset Viewpoint',
//                             category: 'Park • 1.2 mi',
//                             imageUrl:
//                                 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?auto=format&fit=crop&w=400',
//                           ),
//                           PlaceCard(
//                             name: 'Urban Bistro',
//                             category: 'Restaurant • 0.8 mi',
//                             imageUrl:
//                                 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?auto=format&fit=crop&w=400',
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class CategoryChip extends StatelessWidget {
//   final IconData icon;
//   final String label;
//
//   const CategoryChip({
//     super.key,
//     required this.icon,
//     required this.label,
//   });
//
//   static const Color cyan = HomePage.cyan;
//   static const Color purple = HomePage.purple;
//
//   @override
//   Widget build(BuildContext context) {
//     return Chip(
//       avatar: Icon(icon, size: 18, color: purple),
//       label: Text(label),
//       backgroundColor: cyan.withOpacity(0.15),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(22),
//         side: BorderSide(color: cyan.withOpacity(0.35)),
//       ),
//     );
//   }
// }
//
// class PlaceCard extends StatelessWidget {
//   final String name;
//   final String category;
//   final String imageUrl;
//
//   const PlaceCard({
//     super.key,
//     required this.name,
//     required this.category,
//     required this.imageUrl,
//   });
//
//   static const Color cyan = HomePage.cyan;
//   static const Color purple = HomePage.purple;
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 10),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(15),
//       ),
//       elevation: 5,
//       shadowColor: cyan.withOpacity(0.18),
//       child: Row(
//         children: [
//           Container(
//             width: 80,
//             height: 80,
//             decoration: BoxDecoration(
//               borderRadius: const BorderRadius.only(
//                 topLeft: Radius.circular(15),
//                 bottomLeft: Radius.circular(15),
//               ),
//               image: DecorationImage(
//                 image: NetworkImage(imageUrl),
//                 fit: BoxFit.cover,
//               ),
//             ),
//           ),
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.all(12),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     name,
//                     style: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16,
//                     ),
//                   ),
//                   const SizedBox(height: 5),
//                   Text(
//                     category,
//                     style: const TextStyle(
//                       color: Colors.grey,
//                     ),
//                   ),
//                   const SizedBox(height: 5),
//                   Row(
//                     children: [
//                       const Icon(Icons.star, color: Colors.amber, size: 16),
//                       const SizedBox(width: 4),
//                       const Text('4.5'),
//                       const SizedBox(width: 16),
//                       const Icon(Icons.location_on, color: cyan, size: 16),
//                       const SizedBox(width: 4),
//                       const Text('15 min'),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           IconButton(
//             icon: const Icon(Icons.favorite_border, color: purple),
//             onPressed: () {
//               HapticFeedback.lightImpact();
//               // Save place
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HomePage extends StatelessWidget {
  final VoidCallback onOpenMap;

  const HomePage({
    super.key,
    required this.onOpenMap,
  });

  // ── Theme colours ────────────────────────────────────────────────────────
  static const Color blue    = Color(0xFF1E88E5);
  static const Color yellow  = Color(0xFFFFD600);
  static const Color white   = Color(0xFFFFFFFF);
  static const Color grey50  = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey900 = Color(0xFF212121);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: grey50,

      appBar: AppBar(
        backgroundColor: white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: blue,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.location_on, color: yellow, size: 16),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Local Link',
              style: TextStyle(
                color: grey900,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: grey600),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: grey600),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: grey200),
        ),
      ),

      body: Column(
        children: [
          // ── Search bar ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: white,
                border: Border.all(color: grey200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search places, events, people…',
                  hintStyle: const TextStyle(color: grey600, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: blue),
                  suffixIcon: Container(
                    margin: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: yellow,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.tune, color: grey900, size: 18),
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

          // ── Quick-action chips ───────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _Chip(label: 'Near Me',  icon: Icons.near_me,        active: true),
                _Chip(label: 'Events',   icon: Icons.event,           active: false),
                _Chip(label: 'Friends',  icon: Icons.people_outline,  active: false),
                _Chip(label: 'Food',     icon: Icons.restaurant,      active: false),
                _Chip(label: 'Traffic',  icon: Icons.traffic,         active: false),
              ],
            ),
          ),

          // ── Open Map CTA ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                onOpenMap();
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: blue,
                  image: const DecorationImage(
                    image: AssetImage('assets/map_preview.png'),
                    fit: BoxFit.cover,
                    opacity: 0.25,
                  ),
                ),
                child: Stack(
                  children: [
                    // Yellow accent bar
                    Positioned(
                      left: 0, top: 0, bottom: 0,
                      child: Container(
                        width: 6,
                        decoration: const BoxDecoration(
                          color: yellow,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.map, color: white, size: 32),
                          const SizedBox(height: 8),
                          const Text(
                            'Open Live Map',
                            style: TextStyle(
                              color: white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'See what\'s happening around you',
                            style: TextStyle(
                              color: white.withOpacity(0.85),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: yellow,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Explore →',
                          style: TextStyle(
                            color: grey900,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Feed header ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Nearby Activity',
                  style: TextStyle(
                    color: grey900,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'See all',
                    style: TextStyle(color: blue, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          // ── Placeholder feed ─────────────────────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              itemCount: 5,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _FeedCard(index: i),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;

  const _Chip({
    required this.label,
    required this.icon,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? HomePage.blue : HomePage.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? HomePage.blue : HomePage.grey200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: active ? HomePage.white : HomePage.grey600,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: active ? HomePage.white : HomePage.grey600,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedCard extends StatelessWidget {
  final int index;
  const _FeedCard({required this.index});

  static const Color blue    = Color(0xFF1E88E5);
  static const Color yellow  = Color(0xFFFFD600);
  static const Color white   = Color(0xFFFFFFFF);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey900 = Color(0xFF212121);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: grey200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: index.isEven ? blue.withOpacity(0.15) : yellow.withOpacity(0.25),
            child: Icon(
              index.isEven ? Icons.place : Icons.event,
              color: index.isEven ? blue : grey900,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  index.isEven ? 'New spot reported nearby' : 'Event happening soon',
                  style: const TextStyle(
                    color: grey900,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  '0.3 km away · just now',
                  style: TextStyle(color: grey600, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: grey600, size: 18),
        ],
      ),
    );
  }
}