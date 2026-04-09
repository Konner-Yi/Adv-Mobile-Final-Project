import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_compass/flutter_compass.dart';

class DirectionsScreen extends StatefulWidget {
  final double destinationLat;
  final double destinationLng;
  final String destinationName;

  const DirectionsScreen({
    super.key,
    required this.destinationLat,
    required this.destinationLng,
    required this.destinationName,
  });

  @override
  State<DirectionsScreen> createState() => _DirectionsScreenState();
}

class _DirectionsScreenState extends State<DirectionsScreen> {
  // ── Theme ────────────────────────────────────────────────────────────────
  static const Color _bg      = Color(0xFF0D0D0D);
  static const Color _surface = Color(0xFF1A1A1A);
  static const Color _accent  = Color(0xFF1E88E5);
  static const Color _yellow  = Color(0xFFFFD600);
  static const Color _white   = Color(0xFFFFFFFF);

  static const String _mapTilerKey = 'VW5tANDMk54qd1tNkopE';

  final MapController _mapController = MapController();

  LatLng? _userLocation;
  double  _heading      = 0;
  List<LatLng> _routePoints = [];
  bool   _loadingRoute  = true;
  String _routeError    = '';
  String _distanceText  = '';
  String _durationText  = '';
  String _instruction   = 'Getting your location...';

  StreamSubscription<Position>?     _positionStream;
  StreamSubscription<CompassEvent>? _compassStream;

  @override
  void initState() {
    super.initState();
    _initLocationAndRoute();

    _compassStream = FlutterCompass.events?.listen((event) {
      if (mounted) setState(() => _heading = event.heading ?? 0);
    });
  }

  Future<void> _initLocationAndRoute() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final userLatLng = LatLng(pos.latitude, pos.longitude);

      if (mounted) setState(() => _userLocation = userLatLng);

      await _fetchRoute(userLatLng);

      // Start live position updates
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((p) {
        final loc = LatLng(p.latitude, p.longitude);
        if (mounted) {
          setState(() {
            _userLocation = loc;
            _instruction  = _currentInstruction(loc);
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingRoute = false;
          _routeError   = 'Could not get location.';
        });
      }
    }
  }

  // ── OSRM routing (free, no key needed) ───────────────────────────────────
  Future<void> _fetchRoute(LatLng origin) async {
    final dest = LatLng(widget.destinationLat, widget.destinationLng);
    final url  = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
          '${origin.longitude},${origin.latitude};'
          '${dest.longitude},${dest.latitude}'
          '?overview=full&geometries=geojson&steps=true',
    );

    try {
      final res  = await http.get(url);
      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (body['code'] != 'Ok') {
        setState(() {
          _loadingRoute = false;
          _routeError   = 'Could not find a route.';
        });
        return;
      }

      final route    = body['routes'][0] as Map<String, dynamic>;
      final geometry = route['geometry']['coordinates'] as List;
      final points   = geometry
          .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();

      // Distance + duration
      final metres  = (route['distance'] as num).toDouble();
      final seconds = (route['duration'] as num).toDouble();
      final distStr = metres >= 1000
          ? '${(metres / 1000).toStringAsFixed(1)} km'
          : '${metres.toInt()} m';
      final mins    = (seconds / 60).ceil();
      final durStr  = mins >= 60
          ? '${(mins / 60).floor()}h ${mins % 60}min'
          : '${mins} min';

      if (mounted) {
        setState(() {
          _routePoints  = points;
          _distanceText = distStr;
          _durationText = durStr;
          _loadingRoute = false;
          _instruction  = _currentInstruction(origin);
        });

        // Fit map to show full route
        _fitRoute(origin, dest);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingRoute = false;
          _routeError   = 'Routing service unavailable.';
        });
      }
    }
  }

  void _fitRoute(LatLng origin, LatLng dest) {
    final bounds = LatLngBounds.fromPoints([origin, dest, ..._routePoints]);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.fromLTRB(40, 100, 40, 220),
      ),
    );
  }

  // ── Simple instruction: show remaining distance to destination ────────────
  String _currentInstruction(LatLng current) {
    if (_routePoints.isEmpty) return 'Follow the route';
    final dest = LatLng(widget.destinationLat, widget.destinationLng);
    final dist = Geolocator.distanceBetween(
      current.latitude, current.longitude,
      dest.latitude,    dest.longitude,
    );
    if (dist < 50)  return 'You have arrived!';
    if (dist < 200) return 'Destination is ${dist.toInt()} m away';
    if (dist < 1000) return '${dist.toInt()} m to ${widget.destinationName}';
    return '${(dist / 1000).toStringAsFixed(1)} km to ${widget.destinationName}';
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
          const Icon(Icons.navigation, size: 40, color: _accent),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _compassStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dest = LatLng(widget.destinationLat, widget.destinationLng);

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // ── Map ────────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: dest,
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate:
                'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=$_mapTilerKey',
                userAgentPackageName: 'com.example.gathering',
              ),

              // Route polyline
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: _accent,
                      strokeWidth: 5,
                    ),
                  ],
                ),

              MarkerLayer(
                markers: [
                  // Destination pin
                  Marker(
                    point: dest,
                    width: 44,
                    height: 44,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _accent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.destinationName,
                            style: const TextStyle(
                              color: _white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.location_on,
                            color: _accent, size: 28),
                      ],
                    ),
                  ),

                  // User location
                  if (_userLocation != null)
                    Marker(
                      point: _userLocation!,
                      width: 50,
                      height: 50,
                      child: _buildUserMarker(),
                    ),
                ],
              ),
            ],
          ),

          // ── Top bar ────────────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  16, MediaQuery.of(context).padding.top + 12, 16, 12),
              decoration: BoxDecoration(
                color: _bg.withOpacity(0.92),
                border: Border(
                    bottom: BorderSide(color: Colors.white10)),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white12),
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: _white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.destinationName,
                          style: const TextStyle(
                            color: _white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_distanceText.isNotEmpty)
                          Text(
                            '$_durationText  ·  $_distanceText',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Loading overlay ─────────────────────────────────────────────
          if (_loadingRoute)
            Positioned.fill(
              child: Container(
                color: Colors.black38,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: _accent),
                      SizedBox(height: 16),
                      Text(
                        'Finding route...',
                        style: TextStyle(color: _white),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Error state ─────────────────────────────────────────────────
          if (_routeError.isNotEmpty)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _routeError,
                  style: const TextStyle(color: _white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // ── Bottom instruction bar ──────────────────────────────────────
          if (!_loadingRoute && _routeError.isEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                    16, 16, 16,
                    MediaQuery.of(context).padding.bottom + 16),
                decoration: BoxDecoration(
                  color: _bg.withOpacity(0.95),
                  border: Border(top: BorderSide(color: Colors.white10)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Instruction
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _accent.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.navigation,
                              color: _accent, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _instruction,
                            style: const TextStyle(
                              color: _white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Stats row
                    Row(
                      children: [
                        _StatChip(
                          icon: Icons.access_time_outlined,
                          label: _durationText,
                          color: _yellow,
                        ),
                        const SizedBox(width: 10),
                        _StatChip(
                          icon: Icons.straighten_outlined,
                          label: _distanceText,
                          color: _accent,
                        ),
                        const Spacer(),
                        // Re-center button
                        GestureDetector(
                          onTap: () {
                            if (_userLocation != null) {
                              _mapController.move(_userLocation!, 16);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: const Icon(Icons.my_location,
                                color: _white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Stat chip ─────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;

  static const Color _surface = Color(0xFF1A1A1A);

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── User direction triangle ────────────────────────────────────────────────
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