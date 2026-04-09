import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/services/auth_service.dart';
import '../friends/friends_page.dart';
import '../profile/profile_page.dart';
import 'map_preview_widget.dart';
import 'package:local_link_web/features/places/places_service.dart';
import 'package:local_link_web/features/places/place_bottom_sheet.dart';

class HomePage extends StatefulWidget {
  final VoidCallback onOpenMap;

  const HomePage({super.key, required this.onOpenMap});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // ── Theme ─────────────────────────────────────────────────────────────────
  static const Color blue    = Color(0xFF1E88E5);
  static const Color yellow  = Color(0xFFFFD600);
  static const Color white   = Color(0xFFFFFFFF);
  static const Color grey50  = Color(0xFFFAFAFA);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey900 = Color(0xFF212121);

  // ── State ─────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _allPlaces      = [];
  List<Map<String, dynamic>> _filteredPlaces = [];
  bool    _loading        = true;
  bool    _searching      = false;
  String  _activeChip     = 'Near Me';
  String  _searchQuery    = '';
  LatLng? _userLocation;
  bool    _savingLocation = false;

  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  // ── Chip definitions ──────────────────────────────────────────────────────
  static const Map<String, List<String>> _chipFilters = {
    'Near Me':   [],
    'Food':      ['restaurant', 'fast_food', 'food_court', 'cafe', 'bar', 'pub', 'biergarten'],
    'Coffee':    ['cafe'],
    'Shopping':  ['shop', 'supermarket', 'mall', 'convenience', 'clothes', 'electronics'],
    'Health':    ['pharmacy', 'hospital', 'clinic', 'doctors', 'dentist', 'gym', 'fitness_centre'],
    'Parks':     ['park', 'playground', 'nature_reserve', 'garden'],
    'Education': ['school', 'university', 'college', 'library'],
    'Transit':   ['bus_station', 'subway_entrance', 'train_station', 'fuel'],
  };

  static const Map<String, IconData> _chipIcons = {
    'Near Me':   Icons.near_me,
    'Food':      Icons.restaurant,
    'Coffee':    Icons.local_cafe,
    'Shopping':  Icons.shopping_bag_outlined,
    'Health':    Icons.local_hospital_outlined,
    'Parks':     Icons.park,
    'Education': Icons.school_outlined,
    'Transit':   Icons.directions_bus_outlined,
  };

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadNearbyPlaces();
    _saveCurrentUserLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  // ── Location save (peer addition) ─────────────────────────────────────────
  Future<void> _saveCurrentUserLocation() async {
    if (_savingLocation) return;
    final user = AuthService.instance.currentUser;
    if (user == null) return;
    _savingLocation = true;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await AuthService.instance.updateUserProfile({
        'latitude':          position.latitude,
        'longitude':         position.longitude,
        'locationUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
    } finally {
      _savingLocation = false;
    }
  }

  // ── User search (peer addition) ───────────────────────────────────────────
  Stream<List<Map<String, dynamic>>> _searchUsers(String query) {
    if (query.isEmpty) return Stream.value([]);
    return FirebaseFirestore.instance.collection('users').snapshots().map(
          (snapshot) {
        final lowerQuery = query.toLowerCase();
        final users = snapshot.docs
            .map((doc) => {'uid': doc.id, ...doc.data()})
            .where((u) {
          final username = (u['username'] ?? '').toString().toLowerCase();
          final realName = (u['realName'] ?? '').toString().toLowerCase();
          return username.contains(lowerQuery) ||
              realName.contains(lowerQuery);
        })
            .toList();
        users.sort((a, b) {
          return (a['username'] ?? '').toString().toLowerCase().compareTo(
            (b['username'] ?? '').toString().toLowerCase(),
          );
        });
        return users;
      },
    );
  }

  // ── Places loading ────────────────────────────────────────────────────────
  Future<void> _loadNearbyPlaces() async {
    setState(() => _loading = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final loc    = LatLng(pos.latitude, pos.longitude);
      final places = await fetchNearbyPlaces(loc, radiusMetres: 1500);
      if (mounted) {
        setState(() {
          _userLocation = loc;
          _allPlaces    = places;
          _loading      = false;
        });
        _applyChipFilter();
      }
    } catch (e) {
      debugPrint('loadNearbyPlaces error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Chip filter ───────────────────────────────────────────────────────────
  void _applyChipFilter() {
    final keywords = _chipFilters[_activeChip] ?? [];
    final results  = _allPlaces.where((node) {
      final tags    = node['tags'] as Map<String, dynamic>? ?? {};
      final amenity = (tags['amenity'] as String? ?? '').toLowerCase();
      final shop    = (tags['shop']    as String? ?? '').toLowerCase();
      final leisure = (tags['leisure'] as String? ?? '').toLowerCase();
      final tourism = (tags['tourism'] as String? ?? '').toLowerCase();
      final typeStr = '$amenity $shop $leisure $tourism';
      return keywords.isEmpty ||
          keywords.any((k) => typeStr.contains(k.toLowerCase()));
    }).toList();
    _sortByDistance(results);
    setState(() => _filteredPlaces = results);
  }

  // ── Name search ───────────────────────────────────────────────────────────
  void _onSearchChanged(String val) {
    setState(() => _searchQuery = val);
    if (val.trim().isEmpty) {
      _searchDebounce?.cancel();
      setState(() => _searching = false);
      _applyChipFilter();
      return;
    }
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 600), () async {
      if (_userLocation == null) return;
      setState(() => _searching = true);
      final results = await searchPlacesByName(val.trim(), _userLocation!);
      _sortByDistance(results);
      if (mounted) {
        setState(() {
          _filteredPlaces = results;
          _searching      = false;
        });
      }
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  void _sortByDistance(List<Map<String, dynamic>> list) {
    if (_userLocation == null) return;
    list.sort((a, b) => _distanceTo(a).compareTo(_distanceTo(b)));
  }

  double _distanceTo(Map<String, dynamic> node) {
    if (_userLocation == null) return 0;
    final lat = (node['lat'] as num?)?.toDouble() ?? 0;
    final lng = (node['lon'] as num?)?.toDouble() ?? 0;
    return Geolocator.distanceBetween(
      _userLocation!.latitude, _userLocation!.longitude, lat, lng,
    );
  }

  String _formatDistance(double metres) {
    if (metres < 50)   return 'Here';
    if (metres < 1000) return '${metres.toInt()} m away';
    return '${(metres / 1000).toStringAsFixed(1)} km away';
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
        userLocation: _userLocation,
      ),
    );
  }

  void _openFriendsPage() {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FriendsPage()),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bool showSpinner = _loading || _searching;

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
              decoration: const BoxDecoration(color: blue, shape: BoxShape.circle),
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
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search by name — Subway, Tim Hortons…',
                  hintStyle: const TextStyle(color: grey600, fontSize: 14),
                  prefixIcon: _searching
                      ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: blue),
                    ),
                  )
                      : const Icon(Icons.search, color: blue),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.close, color: grey600, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  )
                      : Container(
                    margin: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                        color: yellow, shape: BoxShape.circle),
                    child: const Icon(Icons.tune, color: grey900, size: 18),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),

          // ── User search results (visible while typing) ───────────────────
          if (_searchQuery.isNotEmpty)
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _searchUsers(_searchQuery),
              builder: (context, snapshot) {
                final users = snapshot.data ?? [];
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: SizedBox(
                      height: 60,
                      child: Center(
                          child: CircularProgressIndicator(color: blue)),
                    ),
                  );
                }
                if (users.isEmpty) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: grey200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: users.length > 5 ? 5 : users.length,
                    separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: grey200),
                    itemBuilder: (context, index) {
                      final user     = users[index];
                      final uid      = (user['uid']      ?? '').toString();
                      final username = (user['username'] ?? 'User').toString();
                      final realName = (user['realName'] ?? '').toString();
                      final photoUrl = (user['photoUrl'] ?? '').toString();
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: grey200,
                          backgroundImage: photoUrl.isNotEmpty
                              ? NetworkImage(photoUrl)
                              : null,
                          child: photoUrl.isEmpty
                              ? const Icon(Icons.person, color: grey600)
                              : null,
                        ),
                        title: Text(
                          username,
                          style: const TextStyle(
                            color: grey900,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: realName.isNotEmpty
                            ? Text(realName,
                            style: const TextStyle(
                                color: grey600, fontSize: 12))
                            : null,
                        trailing: const Icon(Icons.chevron_right,
                            color: grey600, size: 18),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ProfilePage(uid: uid)),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),

          // ── Category chips (hidden during search) ────────────────────────
          if (_searchQuery.isEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // Friends chip — navigates to FriendsPage
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: _openFriendsPage,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: grey200),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people_outline,
                                size: 15, color: grey600),
                            SizedBox(width: 5),
                            Text(
                              'Friends',
                              style: TextStyle(
                                  color: grey600,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Dynamic place-filter chips
                  ..._chipFilters.keys.map((label) {
                    final active = _activeChip == label;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _activeChip = label);
                          _applyChipFilter();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: active ? blue : white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: active ? blue : grey200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _chipIcons[label] ?? Icons.place,
                                size: 15,
                                color: active ? white : grey600,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                label,
                                style: TextStyle(
                                  color: active ? white : grey600,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),

          // ── Map preview (hidden during search) ───────────────────────────
          if (_searchQuery.isEmpty)
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: MapPreviewWidget(onExpand: widget.onOpenMap),
            ),

          // ── Feed header ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _searchQuery.isNotEmpty
                      ? 'Results for "$_searchQuery"'
                      : _activeChip == 'Near Me'
                      ? 'Nearby Places'
                      : _activeChip,
                  style: const TextStyle(
                    color: grey900,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!showSpinner)
                  Text(
                    '${_filteredPlaces.length} found',
                    style: const TextStyle(color: grey600, fontSize: 13),
                  ),
              ],
            ),
          ),

          // ── Place feed ───────────────────────────────────────────────────
          Expanded(
            child: showSpinner
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: blue),
                  const SizedBox(height: 16),
                  Text(
                    _searching
                        ? 'Searching for "$_searchQuery"…'
                        : 'Finding nearby places…',
                    style: const TextStyle(color: grey600),
                  ),
                ],
              ),
            )
                : _filteredPlaces.isEmpty
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.search_off,
                      color: grey200, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'No results for "$_searchQuery" nearby'
                        : 'No places found nearby',
                    style:
                    const TextStyle(color: grey600),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _loadNearbyPlaces,
                    child: const Text('Retry',
                        style: TextStyle(color: blue)),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              color: blue,
              onRefresh: _loadNearbyPlaces,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                    16, 0, 16, 100),
                itemCount: _filteredPlaces.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final node = _filteredPlaces[i];
                  return _PlaceCard(
                    node:           node,
                    distance:       _distanceTo(node),
                    formatDistance: _formatDistance,
                    onTap:          () => _openPlace(node),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Place card ────────────────────────────────────────────────────────────────

class _PlaceCard extends StatelessWidget {
  final Map<String, dynamic>    node;
  final double                  distance;
  final String Function(double) formatDistance;
  final VoidCallback            onTap;

  static const Color blue    = Color(0xFF1E88E5);
  static const Color white   = Color(0xFFFFFFFF);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey900 = Color(0xFF212121);

  const _PlaceCard({
    required this.node,
    required this.distance,
    required this.formatDistance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tags    = node['tags'] as Map<String, dynamic>? ?? {};
    final name    = tags['name']    as String? ?? 'Unknown place';
    final amenity = tags['amenity'] as String? ?? '';
    final shop    = tags['shop']    as String? ?? '';
    final leisure = tags['leisure'] as String? ?? '';
    final tourism = tags['tourism'] as String? ?? '';
    final cuisine = tags['cuisine'] as String?;
    final phone   = tags['phone']   as String?;
    final website = tags['website'] as String?;
    final hours   = tags['opening_hours'] as String?;

    final typeRaw   = amenity.isNotEmpty ? amenity
        : shop.isNotEmpty    ? shop
        : leisure.isNotEmpty ? leisure
        : tourism;
    final typeLabel = typeRaw.replaceAll('_', ' ');
    final icon      = _iconForType(typeRaw);
    final color     = _colorForType(typeRaw);
    final is247     = hours?.trim() == '24/7';

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                        color: grey900,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    cuisine != null
                        ? '$typeLabel · ${cuisine.replaceAll(';', ', ')}'
                        : typeLabel,
                    style: const TextStyle(color: grey600, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.near_me, color: blue, size: 12),
                      const SizedBox(width: 3),
                      Text(
                        formatDistance(distance),
                        style: const TextStyle(color: blue, fontSize: 12),
                      ),
                      if (is247) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '24/7',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      if (phone != null) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.phone_outlined,
                            color: grey600, size: 12),
                      ],
                      if (website != null) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.language_outlined,
                            color: grey600, size: 12),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: grey600, size: 18),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'restaurant':
      case 'fast_food':
      case 'food_court':     return Icons.restaurant;
      case 'bar':
      case 'pub':
      case 'nightclub':      return Icons.local_bar;
      case 'cafe':           return Icons.local_cafe;
      case 'gym':
      case 'fitness_centre': return Icons.fitness_center;
      case 'pharmacy':       return Icons.local_pharmacy_outlined;
      case 'hospital':
      case 'clinic':         return Icons.local_hospital_outlined;
      case 'bank':           return Icons.account_balance_outlined;
      case 'atm':            return Icons.atm;
      case 'fuel':           return Icons.local_gas_station_outlined;
      case 'school':         return Icons.school_outlined;
      case 'university':
      case 'college':        return Icons.account_balance_outlined;
      case 'library':        return Icons.local_library_outlined;
      case 'hotel':
      case 'hostel':         return Icons.hotel;
      case 'park':
      case 'playground':     return Icons.park;
      case 'supermarket':
      case 'convenience':    return Icons.shopping_cart_outlined;
      case 'bus_station':    return Icons.directions_bus_outlined;
      default:               return Icons.storefront;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'restaurant':
      case 'fast_food':
      case 'cafe':
      case 'bar':
      case 'pub':            return const Color(0xFFE53935);
      case 'gym':
      case 'fitness_centre':
      case 'pharmacy':
      case 'hospital':       return const Color(0xFF43A047);
      case 'park':
      case 'playground':     return const Color(0xFF7CB342);
      case 'hotel':
      case 'hostel':         return const Color(0xFF00ACC1);
      case 'bank':
      case 'atm':            return const Color(0xFF8E24AA);
      case 'school':
      case 'university':
      case 'library':        return const Color(0xFF1E88E5);
      case 'supermarket':
      case 'convenience':    return const Color(0xFFFB8C00);
      case 'bus_station':    return const Color(0xFF546E7A);
      default:               return const Color(0xFF757575);
    }
  }
}