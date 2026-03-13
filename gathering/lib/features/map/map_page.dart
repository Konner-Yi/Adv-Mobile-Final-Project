// import 'dart:async';
// import 'dart:math';
// import 'dart:ui' as ui;
// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:flutter_compass/flutter_compass.dart';
// import 'package:local_link_web/features/home/home_page.dart';
//
// class MapPage extends StatefulWidget {
//   const MapPage({Key? key}) : super(key: key);
//
//   @override
//   State<MapPage> createState() => _MapScreenState();
// }
//
// class _MapScreenState extends State<MapPage> {
//   final MapController _mapController = MapController();
//
//   static const String mapTilerKey = "VW5tANDMk54qd1tNkopE";
//
//   final LatLngBounds ontarioBounds = LatLngBounds(
//     const LatLng(41.7, -95.2),
//     const LatLng(56.9, -74.3),
//   );
//
//   LatLng? _currentLocation;
//   double _heading = 0;
//
//   final List<Marker> _postMarkers = [];
//
//   StreamSubscription<Position>? _positionStream;
//   StreamSubscription<CompassEvent>? _compassStream;
//
//   @override
//   void initState() {
//     super.initState();
//     _initLocation();
//   }
//
//   Future<void> _initLocation() async {
//     try {
//       LocationPermission permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied ||
//           permission == LocationPermission.deniedForever) {
//         return;
//       }
//
//       final serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         return;
//       }
//
//       // get last known position first
//       final lastPosition = await Geolocator.getLastKnownPosition();
//       if (lastPosition != null) {
//         final last = LatLng(lastPosition.latitude, lastPosition.longitude);
//         _mapController.move(last, 16);
//
//         if (mounted) {
//           setState(() {
//             _currentLocation = last;
//           });
//         }
//       }
//
//       // stream live updates
//       _positionStream = Geolocator.getPositionStream(
//         locationSettings: const LocationSettings(
//           accuracy: LocationAccuracy.high,
//           distanceFilter: 5,
//         ),
//       ).listen((Position position) {
//         final newLocation = LatLng(position.latitude, position.longitude);
//
//         if (mounted) {
//           setState(() {
//             _currentLocation = newLocation;
//           });
//         }
//
//         _mapController.move(newLocation, 16);
//       });
//
//       _compassStream = FlutterCompass.events?.listen((event) {
//         if (mounted) {
//           setState(() {
//             _heading = event.heading ?? 0;
//           });
//         }
//       });
//     } catch (e) {
//       debugPrint("Location init error: $e");
//     }
//   }
//
//   void _addPostMarker(LatLng point) {
//     setState(() {
//       _postMarkers.add(
//         Marker(
//           point: point,
//           width: 40,
//           height: 40,
//           child: const Icon(
//             Icons.location_on,
//             size: 40,
//             color: Colors.red,
//           ),
//         ),
//       );
//     });
//   }
//
//   Widget _buildUserMarker() {
//     return Transform.rotate(
//       angle: _heading * (pi / 180),
//       child: Stack(
//         alignment: Alignment.center,
//         children: [
//           Positioned(
//             top: 0,
//             child: CustomPaint(
//               size: const Size(40, 30),
//               painter: _TrianglePainter(),
//             ),
//           ),
//           const Icon(
//             Icons.navigation,
//             size: 40,
//             color: Colors.blue,
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _positionStream?.cancel();
//     _compassStream?.cancel();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           Navigator.of(context).pushAndRemoveUntil(
//             MaterialPageRoute(builder: (context) => HomePage(onOpenMap: () {  },)),
//                 (route) => false,
//           );
//         },
//         child: const Icon(Icons.home),
//       ),
//       body: SizedBox.expand(
//         child: FlutterMap(
//           mapController: _mapController,
//           options: MapOptions(
//             initialCenter: const LatLng(43.7, -79.4),
//             initialZoom: 6,
//             onTap: (tapPosition, point) {
//               _addPostMarker(point);
//             },
//           ),
//           children: [
//             TileLayer(
//               urlTemplate:
//               'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=$mapTilerKey',
//               userAgentPackageName: 'com.example.gathering',
//             ),
//             MarkerLayer(
//               markers: [
//                 ..._postMarkers,
//                 if (_currentLocation != null)
//                   Marker(
//                     point: _currentLocation!,
//                     width: 50,
//                     height: 50,
//                     child: _buildUserMarker(),
//                   ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class _TrianglePainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = Colors.blue.withOpacity(0.35)
//       ..style = PaintingStyle.fill;
//
//     final path = ui.Path();
//     path.moveTo(size.width / 2, 0);
//     path.lineTo(size.width, size.height);
//     path.lineTo(0, size.height);
//     path.close();
//
//     canvas.drawPath(path, paint);
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }

import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapPage> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();

  static const String mapTilerKey = "VW5tANDMk54qd1tNkopE";

  // ── Theme colours ────────────────────────────────────────────────────────
  static const Color blue    = Color(0xFF1E88E5);
  static const Color yellow  = Color(0xFFFFD600);
  static const Color white   = Color(0xFFFFFFFF);
  static const Color grey900 = Color(0xFF212121);

  LatLng? _currentLocation;
  double _heading = 0;

  final List<Marker> _postMarkers = [];

  // ── Marker-placement toggle ──────────────────────────────────────────────
  bool _isPlacingMarker = false;

  // ── Pulse animation for the active toggle state ──────────────────────────
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  StreamSubscription<Position>? _positionStream;
  StreamSubscription<CompassEvent>? _compassStream;

  @override
  void initState() {
    super.initState();
    _initLocation();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

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
        _mapController.move(last, 16);
        if (mounted) setState(() => _currentLocation = last);
      }

      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen((Position position) {
        final newLocation = LatLng(position.latitude, position.longitude);
        if (mounted) setState(() => _currentLocation = newLocation);
        _mapController.move(newLocation, 16);
      });

      _compassStream = FlutterCompass.events?.listen((event) {
        if (mounted) setState(() => _heading = event.heading ?? 0);
      });
    } catch (e) {
      debugPrint("Location init error: $e");
    }
  }

  void _togglePlacingMarker() {
    HapticFeedback.selectionClick();
    setState(() => _isPlacingMarker = !_isPlacingMarker);
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    if (!_isPlacingMarker) return; // ← only place when mode is active

    HapticFeedback.mediumImpact();
    setState(() {
      _postMarkers.add(
        Marker(
          point: point,
          width: 40,
          height: 40,
          child: const Icon(Icons.location_on, size: 40, color: Colors.red),
        ),
      );
      _isPlacingMarker = false; // auto-deactivate after placing one marker
    });
  }

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Height of the floating nav bar so we don't overlap it:
    // 14px bottom padding + ~60px bar + safe-area bottom
    final double navBarClearance =
        14 + 60 + MediaQuery.of(context).padding.bottom + 16;

    return Scaffold(
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(43.7, -79.4),
              initialZoom: 6,
              onTap: _onMapTap,
              // Change cursor feel when placing mode is active
              // (pointer change is a nice touch on desktop/web)
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
                      width: 50,
                      height: 50,
                      child: _buildUserMarker(),
                    ),
                ],
              ),
            ],
          ),

          // ── Placement-mode overlay hint ───────────────────────────────────
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

          // ── Place-marker toggle button ────────────────────────────────────
          Positioned(
            right: 16,
            bottom: navBarClearance,
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (context, child) {
                final scale = _isPlacingMarker ? _pulseAnim.value : 1.0;
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
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
                    _isPlacingMarker ? Icons.location_on : Icons.add_location_alt_outlined,
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