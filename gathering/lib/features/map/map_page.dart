import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:local_link_web/features/posts/create_post_screen.dart';
import 'package:local_link_web/features/posts/post_bottom_sheet.dart';
import 'package:local_link_web/features/places/place_bottom_sheet.dart';
import 'package:local_link_web/features/places/places_service.dart';
import 'package:local_link_web/features/posts/create_post_screen.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapPage>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();

  static const String mapTilerKey = 'VW5tANDMk54qd1tNkopE';

  // ── Theme colours ────────────────────────────────────────────────────────
  static const Color blue    = Color(0xFF1E88E5);
  static const Color yellow  = Color(0xFFFFD600);
  static const Color white   = Color(0xFFFFFFFF);
  static const Color grey900 = Color(0xFF212121);

  LatLng? _currentLocation;
  double  _heading = 0;

  // Separate map center for place loading — doesn't affect GPS dot
  LatLng? _mapCenter;

  // ── Markers ──────────────────────────────────────────────────────────────
  final List<Marker> _postMarkers  = [];
  final List<Marker> _placeMarkers = [];

  // ── Marker-placement toggle ──────────────────────────────────────────────
  bool _isPlacingMarker = false;

  // ── Pulse animation ──────────────────────────────────────────────────────
  late final AnimationController _pulseController;
  late final Animation<double>   _pulseAnim;

  // ── Streams ──────────────────────────────────────────────────────────────
  StreamSubscription<Position>?     _positionStream;
  StreamSubscription<CompassEvent>? _compassStream;

  Timer? _placeDebounce;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _loadPosts();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Widget _buildPostMarkerIcon(Map<String, dynamic> data) {
    final imageUrl = data['imageUrl'] as String? ?? '';
    final postIcon = data['postIcon'] as String?;

    if (imageUrl.isNotEmpty) {
      // Real photo post
      return Container(
        decoration: BoxDecoration(
          color: blue,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.network(imageUrl, fit: BoxFit.cover),
        ),
      );
    }

    if (postIcon != null) {
      // Stock icon post — find the matching option
      final opt = kStockOptions.firstWhere(
            (o) => o.label == postIcon,
        orElse: () => const StockOption(Icons.place, blue, 'default'),
      );
      return Container(
        decoration: BoxDecoration(
          color: opt.color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: opt.color.withOpacity(0.45),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(opt.icon, color: Colors.white, size: 22),
      );
    }

    // Fallback
    return Container(
      decoration: BoxDecoration(
        color: blue,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: const Icon(Icons.place, color: Colors.white, size: 22),
    );
  }

  // ── Load user posts ───────────────────────────────────────────────────────
  Future<void> _loadPosts() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .get();

    final markers = <Marker>[];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final lat  = data['lat'] as double?;
      final lng  = data['lng'] as double?;
      if (lat == null || lng == null) continue;

      markers.add(
        Marker(
          point: LatLng(lat, lng),
          width: 44,
          height: 44,
          child: GestureDetector(
            onTap: () => _openPost({...data, 'postId': doc.id}),
            child: _buildPostMarkerIcon(data),

          ),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _postMarkers
          ..clear()
          ..addAll(markers);
      });
    }
  }

  // ── Load nearby OSM places ────────────────────────────────────────────────
  Future<void> _loadPlaces() async {
    final center = _mapCenter ?? _currentLocation;
    if (center == null) return;

    try {
      final nodes   = await fetchNearbyPlaces(center);
      final markers = <Marker>[];

      for (final node in nodes) {
        final lat  = (node['lat'] as num?)?.toDouble();
        final lng  = (node['lon'] as num?)?.toDouble();
        final tags = node['tags'] as Map<String, dynamic>? ?? {};
        final name = tags['name'] as String? ?? '';

        if (lat == null || lng == null || name.isEmpty) continue;

        final category = categoryForNode(node);
        final icon     = _iconForCategory(category);
        final color    = _colorForCategory(category);

        markers.add(
          Marker(
            point: LatLng(lat, lng),
            width: 38,
            height: 38,
            child: GestureDetector(
              onTap: () => _openPlace(node),
              child: Container(
                decoration: BoxDecoration(
                  color: white,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ),
          ),
        );
      }

      if (mounted) {
        setState(() {
          _placeMarkers
            ..clear()
            ..addAll(markers);
        });
      }
    } catch (e) {
      debugPrint('Places load error: $e');
    }
  }

  // ── Category helpers ──────────────────────────────────────────────────────
  IconData _iconForCategory(String category) {
    switch (category) {
      case 'food':      return Icons.restaurant;
      case 'bar':       return Icons.local_bar;
      case 'cafe':      return Icons.local_cafe;
      case 'gym':       return Icons.fitness_center;
      case 'health':    return Icons.local_pharmacy_outlined;
      case 'bank':      return Icons.account_balance_outlined;
      case 'fuel':      return Icons.local_gas_station_outlined;
      case 'education': return Icons.school_outlined;
      case 'lodging':   return Icons.hotel;
      case 'park':      return Icons.park;
      case 'shop':      return Icons.shopping_bag_outlined;
      case 'tourism':   return Icons.photo_camera_outlined;
      default:          return Icons.storefront;
    }
  }

  Color _colorForCategory(String category) {
    switch (category) {
      case 'food':
      case 'bar':
      case 'cafe':      return const Color(0xFFE53935);
      case 'gym':
      case 'health':    return const Color(0xFF43A047);
      case 'bank':
      case 'fuel':      return const Color(0xFF8E24AA);
      case 'education': return const Color(0xFF1E88E5);
      case 'lodging':   return const Color(0xFF00ACC1);
      case 'park':      return const Color(0xFF7CB342);
      case 'shop':      return const Color(0xFFFB8C00);
      case 'tourism':   return const Color(0xFF3949AB);
      default:          return const Color(0xFF757575);
    }
  }

  // ── Open sheets ───────────────────────────────────────────────────────────
  void _openPost(Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => PostBottomSheet(
        post: post,
        postId: post['postId'] as String,
      ),
    );
  }

  void _openPlace(Map<String, dynamic> osmNode) {
    final details = buildPlaceDetails(osmNode);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => PlaceBottomSheet(
        osmNode:      osmNode,
        placeDetails: details,
        userLocation: _currentLocation,
      ),
    );
  }

  // ── Location init ─────────────────────────────────────────────────────────
  Future<void> _initLocation() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      final lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) {
        final last = LatLng(lastPosition.latitude, lastPosition.longitude);
        _mapController.move(last, 15);
        if (mounted) {
          setState(() {
            _currentLocation = last;
            _mapCenter       = last;
          });
          _loadPlaces();
        }
      }

      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 20,
        ),
      ).listen((Position position) {
        final newLocation = LatLng(position.latitude, position.longitude);
        if (mounted) setState(() => _currentLocation = newLocation);
      });

      _compassStream = FlutterCompass.events?.listen((event) {
        if (mounted) setState(() => _heading = event.heading ?? 0);
      });
    } catch (e) {
      debugPrint('Location init error: $e');
    }
  }

  // ── Recenter on user ──────────────────────────────────────────────────────
  void _recenterOnUser() {
    HapticFeedback.selectionClick();
    final loc = _currentLocation;
    if (loc != null) {
      _mapController.move(loc, 16);
    } else {
      // GPS not ready yet — fetch fresh
      Geolocator.getCurrentPosition().then((pos) {
        final newLoc = LatLng(pos.latitude, pos.longitude);
        if (mounted) setState(() => _currentLocation = newLoc);
        _mapController.move(newLoc, 16);
      });
    }
  }

  // ── Map tap ───────────────────────────────────────────────────────────────
  void _togglePlacingMarker() {
    HapticFeedback.selectionClick();
    setState(() => _isPlacingMarker = !_isPlacingMarker);
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) async {
    if (!_isPlacingMarker) return;
    HapticFeedback.mediumImpact();
    setState(() => _isPlacingMarker = false);

    final posted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePostScreen(pinnedLocation: point),
      ),
    );

    if (posted == true) _loadPosts();
  }

  // ── Camera move → reload places (debounced, no GPS overwrite) ────────────
  void _onMapEvent(MapEvent event) {
    if (event is MapEventMoveEnd || event is MapEventScrollWheelZoom) {
      _mapCenter = event.camera.center; // only update map center, not GPS
      _placeDebounce?.cancel();
      _placeDebounce = Timer(const Duration(milliseconds: 700), _loadPlaces);
    }
  }

  // ── User marker ───────────────────────────────────────────────────────────
  Widget _buildUserMarker() {
    return Transform.rotate(
      angle: _heading * (pi / 180),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 0,
            child: CustomPaint(
              size: const Size(40, 30),
              painter: _TrianglePainter(),
            ),
          ),
          const Icon(Icons.navigation, size: 40, color: blue),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _compassStream?.cancel();
    _pulseController.dispose();
    _placeDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double navBarClearance =
        14 + 60 + MediaQuery.of(context).padding.bottom + 16;

    return Scaffold(
      body: Stack(
        children: [
          // ── Map ────────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(43.7, -79.4),
              initialZoom: 6,
              onTap: _onMapTap,
              onMapEvent: _onMapEvent,
            ),
            children: [
              TileLayer(
                urlTemplate:
                'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=$mapTilerKey',
                userAgentPackageName: 'com.example.gathering',
              ),
              MarkerLayer(
                markers: [
                  ..._placeMarkers,
                  ..._postMarkers,
                  if (_currentLocation != null)
                    Marker(
                      point: _currentLocation!,
                      width: 50,
                      height: 50,
                      child: _buildUserMarker(),
                    ),
                ],
              ),
            ],
          ),

          // ── Placement-mode hint ────────────────────────────────────────
          if (_isPlacingMarker)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: grey900.withOpacity(0.82),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.20),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app, color: yellow, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Tap the map to drop a pin',
                        style: TextStyle(
                          color: white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            right: 16,
            bottom: navBarClearance + 128, // sits above recenter
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                final currentZoom = _mapController.camera.zoom;
                _mapController.move(
                  _mapController.camera.center,
                  (currentZoom - 1.5).clamp(2.0, 18.0),
                );
              },
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: white,
                  shape: BoxShape.circle,
                  border: Border.all(color: blue, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.zoom_out, color: blue, size: 26),
              ),
            ),
          ),
          // ── Recenter button ────────────────────────────────────────────
          Positioned(
            right: 16,
            bottom: navBarClearance + 64, // sits above pin toggle
            child: GestureDetector(
              onTap: _recenterOnUser,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: white,
                  shape: BoxShape.circle,
                  border: Border.all(color: blue, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.my_location, color: blue, size: 24),
              ),
            ),
          ),

          // ── Pin toggle button ──────────────────────────────────────────
          Positioned(
            right: 16,
            bottom: navBarClearance,
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (context, child) {
                final scale = _isPlacingMarker ? _pulseAnim.value : 1.0;
                return Transform.scale(scale: scale, child: child);
              },
              child: GestureDetector(
                onTap: _togglePlacingMarker,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _isPlacingMarker ? yellow : white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isPlacingMarker ? yellow : blue,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _isPlacingMarker
                            ? yellow.withOpacity(0.45)
                            : Colors.black.withOpacity(0.15),
                        blurRadius: _isPlacingMarker ? 16 : 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isPlacingMarker
                        ? Icons.location_on
                        : Icons.add_location_alt_outlined,
                    color: _isPlacingMarker ? grey900 : blue,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E88E5).withOpacity(0.35)
      ..style = PaintingStyle.fill;

    final path = ui.Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}