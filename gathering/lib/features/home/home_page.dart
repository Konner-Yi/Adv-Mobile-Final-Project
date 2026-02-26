import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HomePage extends StatelessWidget {
  final VoidCallback onOpenMap;

  const HomePage({
    super.key,
    required this.onOpenMap,
  });

  // Bright theme accents (match your gradient nav)
  static const Color cyan = Color(0xFF00C6FF);
  static const Color purple = Color(0xFF7F00FF);
  static const Color heading = Color(0xFF00E5FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Let the gradient show through
      backgroundColor: Colors.transparent,

      appBar: AppBar(
        backgroundColor: const Color(0xFF3949AB),
        elevation: 0,
        title: const Text(
          'Local Link',
          style: TextStyle(
            color: Color(0xFF00E5FF),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: cyan),
            onPressed: () {
              // Notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle, color: cyan),
            onPressed: () {
              // Profile
            },
          ),
        ],
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF5C6BC0), // soft cyan
              Color(0xFF5C6BC0), // soft purple
            ],
          ),
        ),
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: cyan.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search for places...',
                    prefixIcon: const Icon(Icons.search, color: cyan),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
            ),

            // Map preview
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  image: const DecorationImage(
                    image: NetworkImage(
                      'https://images.unsplash.com/photo-1526778548025-fa2f459cd5c1?auto=format&fit=crop&w=800',
                    ),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: purple.withOpacity(0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      onOpenMap(); // ✅ keeps tab switch functionality
                    },
                    icon: const Icon(Icons.map),
                    label: const Text('Open Interactive Map'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cyan,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 26,
                        vertical: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 8,
                    ),
                  ),
                ),
              ),
            ),

            // Categories
            const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Categories',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: HomePage.heading,
                    ),
                  ),
                  SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        CategoryChip(icon: Icons.restaurant, label: 'Food'),
                        SizedBox(width: 10),
                        CategoryChip(icon: Icons.local_cafe, label: 'Coffee'),
                        SizedBox(width: 10),
                        CategoryChip(icon: Icons.park, label: 'Parks'),
                        SizedBox(width: 10),
                        CategoryChip(icon: Icons.shopping_bag, label: 'Shopping'),
                        SizedBox(width: 10),
                        CategoryChip(icon: Icons.nightlife, label: 'Nightlife'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Recent places
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nearby Places',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: heading,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView(
                        children: const [
                          PlaceCard(
                            name: 'Central Park Cafe',
                            category: 'Coffee • 0.5 mi',
                            imageUrl:
                                'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&w=400',
                          ),
                          PlaceCard(
                            name: 'Sunset Viewpoint',
                            category: 'Park • 1.2 mi',
                            imageUrl:
                                'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?auto=format&fit=crop&w=400',
                          ),
                          PlaceCard(
                            name: 'Urban Bistro',
                            category: 'Restaurant • 0.8 mi',
                            imageUrl:
                                'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?auto=format&fit=crop&w=400',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const CategoryChip({
    super.key,
    required this.icon,
    required this.label,
  });

  static const Color cyan = HomePage.cyan;
  static const Color purple = HomePage.purple;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18, color: purple),
      label: Text(label),
      backgroundColor: cyan.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: cyan.withOpacity(0.35)),
      ),
    );
  }
}

class PlaceCard extends StatelessWidget {
  final String name;
  final String category;
  final String imageUrl;

  const PlaceCard({
    super.key,
    required this.name,
    required this.category,
    required this.imageUrl,
  });

  static const Color cyan = HomePage.cyan;
  static const Color purple = HomePage.purple;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 5,
      shadowColor: cyan.withOpacity(0.18),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                bottomLeft: Radius.circular(15),
              ),
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    category,
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      const Text('4.5'),
                      const SizedBox(width: 16),
                      const Icon(Icons.location_on, color: cyan, size: 16),
                      const SizedBox(width: 4),
                      const Text('15 min'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border, color: purple),
            onPressed: () {
              HapticFeedback.lightImpact();
              // Save place
            },
          ),
        ],
      ),
    );
  }
}