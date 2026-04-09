import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_link_web/features/posts/post_bottom_sheet.dart';

class MapPreviewWidget extends StatefulWidget {
  final VoidCallback onExpand;

  const MapPreviewWidget({super.key, required this.onExpand});

  @override
  State<MapPreviewWidget> createState() => _MapPreviewWidgetState();
}

class _MapPreviewWidgetState extends State<MapPreviewWidget> {
  static const Color blue         = Color(0xFF1E88E5);
  static const Color yellow       = Color(0xFFFFD600);
  static const Color grey900      = Color(0xFF212121);
  static const String mapTilerKey = "VW5tANDMk54qd1tNkopE";

  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  List<Marker> _postMarkers = [];

  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) return;

      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        final loc = LatLng(last.latitude, last.longitude);
        if (mounted) setState(() => _currentLocation = loc);
        _mapController.move(loc, 15);
        _loadNearbyPosts(loc);
      }

      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((pos) {
        final loc = LatLng(pos.latitude, pos.longitude);
        if (mounted) setState(() => _currentLocation = loc);
        _mapController.move(loc, 15);
      });
    } catch (e) {
      debugPrint('MapPreview location error: $e');
    }
  }

  Future<void> _loadNearbyPosts(LatLng center) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();

    final markers = <Marker>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final lat  = data['lat'] as double?;
      final lng  = data['lng'] as double?;
      if (lat == null || lng == null) continue;

      // Only show posts within 1.5 km
      final dist = const Distance().as(
        LengthUnit.Kilometer,
        center,
        LatLng(lat, lng),
      );
      if (dist > 1.5) continue;

      markers.add(Marker(
        point: LatLng(lat, lng),
        width: 36,
        height: 36,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: blue,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: (data['imageUrl'] as String?)?.isNotEmpty == true
                ? Image.network(data['imageUrl'], fit: BoxFit.cover)
                : const Icon(Icons.photo, color: Colors.white, size: 18),
          ),
        ),
      ));
    }

    if (mounted) setState(() => _postMarkers = markers);
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Entire preview is one big tap target — opens full map
      onTap: widget.onExpand,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 180,
          child: Stack(
            children: [
              // ── Map (non-interactive) ──────────────────────────────────
              IgnorePointer(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentLocation ?? const LatLng(43.7, -79.4),
                    initialZoom: 15,
                    // Disable all gestures
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                      'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=$mapTilerKey',
                      userAgentPackageName: 'com.example.gathering',
                    ),
                    MarkerLayer(
                      markers: [
                        ..._postMarkers,
                        if (_currentLocation != null)
                          Marker(
                            point: _currentLocation!,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.navigation,
                              color: blue,
                              size: 36,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Tap overlay — "Explore" pill ───────────────────────────
              Positioned(
                bottom: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: yellow,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.open_in_full, color: grey900, size: 13),
                      SizedBox(width: 5),
                      Text(
                        'Open Map',
                        style: TextStyle(
                          color: grey900,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Post count badge ───────────────────────────────────────
              if (_postMarkers.isNotEmpty)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: grey900.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on,
                            color: yellow, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          '${_postMarkers.length} nearby',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}