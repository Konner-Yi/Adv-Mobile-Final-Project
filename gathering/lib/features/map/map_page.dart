import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  static const String mapTilerKey = "VW5tANDMk54qd1tNkopE";

  final LatLngBounds ontarioBounds = LatLngBounds(
    const LatLng(41.7, -95.2),
    const LatLng(56.9, -74.3),
  );

  LatLng? _currentLocation;
  double _heading = 0;

  final List<Marker> _postMarkers = [];

  StreamSubscription<Position>? _positionStream;
  StreamSubscription<CompassEvent>? _compassStream;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      // get last known position first
      final lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) {
        final last = LatLng(lastPosition.latitude, lastPosition.longitude);
        _mapController.move(last, 16);

        if (mounted) {
          setState(() {
            _currentLocation = last;
          });
        }
      }

      // stream live updates
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen((Position position) {
        final newLocation = LatLng(position.latitude, position.longitude);

        if (mounted) {
          setState(() {
            _currentLocation = newLocation;
          });
        }

        _mapController.move(newLocation, 16);
      });

      _compassStream = FlutterCompass.events?.listen((event) {
        if (mounted) {
          setState(() {
            _heading = event.heading ?? 0;
          });
        }
      });
    } catch (e) {
      debugPrint("Location init error: $e");
    }
  }

  void _addPostMarker(LatLng point) {
    setState(() {
      _postMarkers.add(
        Marker(
          point: point,
          width: 40,
          height: 40,
          child: const Icon(
            Icons.location_on,
            size: 40,
            color: Colors.red,
          ),
        ),
      );
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
          const Icon(
            Icons.navigation,
            size: 40,
            color: Colors.blue,
          ),
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
    return Scaffold(
      body: SizedBox.expand(
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: const LatLng(43.7, -79.4),
            initialZoom: 6,
            onTap: (tapPosition, point) {
              _addPostMarker(point);
            },
          ),
          children: [
            TileLayer(
              urlTemplate:
              'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=$mapTilerKey',
              userAgentPackageName: 'com.example.gathering',
            ),
            MarkerLayer(
              markers: [
                // temporary post markers (visual only)
                ..._postMarkers,

                // user location marker
                if (_currentLocation != null)
                  Marker(
                    point: _currentLocation!,
                    width: 50,
                    height: 50,
                    child: _buildUserMarker(
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.35)
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