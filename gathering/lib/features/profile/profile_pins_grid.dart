import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:local_link_web/features/places/place_bottom_sheet.dart';

class ProfilePinsGrid extends StatelessWidget {
  final String uid;
  const ProfilePinsGrid({super.key, required this.uid});

  static const Color blue    = Color(0xFF1E88E5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey900 = Color(0xFF212121);

  Future<void> _removePin(BuildContext context, String pinId) async {
    HapticFeedback.mediumImpact();
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('pins')
        .doc(pinId)
        .delete();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pin removed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('pins')
          .orderBy('pinnedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator(color: blue)),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Column(
              children: [
                Icon(Icons.bookmark_border_outlined, size: 48, color: grey200),
                SizedBox(height: 10),
                Text('No pinned areas yet',
                    style: TextStyle(color: grey400, fontSize: 14)),
                SizedBox(height: 6),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Tap "Pin area" on any place or map location to save it here',
                    style: TextStyle(color: grey400, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          MediaQuery.of(context).padding.bottom + 80, // 👈 ADD THIS
          ),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final doc      = docs[i];
            final data     = doc.data() as Map<String, dynamic>;
            final name     = data['name']     as String? ?? 'Unnamed area';
            final category = data['category'] as String? ?? '';
            final lat      = (data['lat']     as num?)?.toDouble();
            final lng      = (data['lng']     as num?)?.toDouble();

            return ListTile(
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              onTap: () {
                if (lat == null || lng == null) return;
                final osmId = data['osmId'];
                final osmNode = {
                  'id': osmId,
                  'lat': lat,
                  'lon': lng,
                  'tags': {
                    'name': name,
                    'amenity': category,
                  },
                };

                final placeDetails = {
                  'name': name,
                  'type': category,
                  'lat': lat,
                  'lng': lng,
                  'formatted_address': '',
                  'tags': {
                    'name': name,
                    'amenity': category,
                  },
                };

                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (_) => PlaceBottomSheet(
                    osmNode: osmNode,
                    placeDetails: placeDetails,
                  ),
                );
              },
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: blue.withOpacity(0.10),
                  shape: BoxShape.circle,
                  border: Border.all(color: blue.withOpacity(0.25)),
                ),
                child: const Icon(Icons.location_on, color: blue, size: 22),
              ),
              title: Text(
                name,
                style: const TextStyle(
                  color: grey900,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              subtitle: lat != null && lng != null
                  ? Text(
                category.isNotEmpty
                    ? category
                    : '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                style: const TextStyle(color: grey600, fontSize: 12),
              )
                  : null,
              trailing: IconButton(
                icon: const Icon(Icons.close, color: grey400, size: 18),
                onPressed: () => _removePin(context, doc.id),
              ),
            );
          },
        );
      },
    );
  }
}