import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:local_link_web/features/places/places_service.dart';
import 'package:local_link_web/features/posts/create_post_screen.dart';
import 'package:local_link_web/features/posts/post_bottom_sheet.dart';
import 'package:local_link_web/features/places/directions_screen.dart';

class PlaceBottomSheet extends StatefulWidget {
  final Map<String, dynamic> osmNode;
  final Map<String, dynamic> placeDetails;
  final LatLng? userLocation;

  const PlaceBottomSheet({
    super.key,
    required this.osmNode,
    required this.placeDetails,
    this.userLocation,
  });

  @override
  State<PlaceBottomSheet> createState() => _PlaceBottomSheetState();
}

class _PlaceBottomSheetState extends State<PlaceBottomSheet> {
  static const Color _bg      = Color(0xFFFAFAFA);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _accent  = Color(0xFF1E88E5);
  static const Color _yellow  = Color(0xFFFFD600);
  static const Color _grey200 = Color(0xFFEEEEEE);
  static const Color _grey600 = Color(0xFF757575);
  static const Color _grey900 = Color(0xFF212121);

  static const double _postRadius = 150;

  List<Map<String, dynamic>> _posts        = [];
  bool                       _loadingPosts = true;
  bool                       _canPost      = false;
  bool                       _isPinned     = false;

  String get _placeId => 'osm_${widget.osmNode['id']}';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final results = await Future.wait([
      _fetchPlacePosts(),
      _checkProximity(),
    ]);
    _checkIfPinned();

    if (mounted) {
      setState(() {
        _posts        = results[0] as List<Map<String, dynamic>>;
        _canPost      = results[1] as bool;
        _loadingPosts = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchPlacePosts() async {
    final snap = await FirebaseFirestore.instance
        .collection('place_posts')
        .where('placeId', isEqualTo: _placeId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs
        .map((d) => <String, dynamic>{...d.data(), 'postId': d.id})
        .toList();
  }

  Future<bool> _checkProximity() async {
    try {
      final pos      = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final placeLat = widget.placeDetails['lat'] as double;
      final placeLng = widget.placeDetails['lng'] as double;
      final dist     = Geolocator.distanceBetween(
        pos.latitude, pos.longitude,
        placeLat, placeLng,
      );
      return dist <= _postRadius;
    } catch (_) {
      return false;
    }
  }

  Future<void> _checkIfPinned() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final lat   = widget.placeDetails['lat'] as double;
    final lng   = widget.placeDetails['lng'] as double;
    final pinId = '${lat.toStringAsFixed(5)}_${lng.toStringAsFixed(5)}';
    final doc   = await FirebaseFirestore.instance
        .collection('users').doc(uid)
        .collection('pins').doc(pinId).get();
    if (mounted) setState(() => _isPinned = doc.exists);
  }

  Future<void> _togglePin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    HapticFeedback.selectionClick();

    final tags     = widget.osmNode['tags'] as Map<String, dynamic>? ?? {};
    final name     = tags['name'] as String? ?? 'Unnamed area';
    final lat      = widget.placeDetails['lat'] as double;
    final lng      = widget.placeDetails['lng'] as double;
    final category = categoryForNode(widget.osmNode);
    final pinId    = '${lat.toStringAsFixed(5)}_${lng.toStringAsFixed(5)}';
    final pinRef   = FirebaseFirestore.instance
        .collection('users').doc(uid)
        .collection('pins').doc(pinId);

    if (_isPinned) {
      await pinRef.delete();
      if (mounted) setState(() => _isPinned = false);
      if (mounted) ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Area unpinned')));
    } else {
      await pinRef.set({
        'name':     name,
        'category': category,
        'lat':      lat,
        'lng':      lng,
        'osmId':    widget.osmNode['id'],
        'pinnedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) setState(() => _isPinned = true);
      if (mounted) ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Area pinned!')));
    }
  }

  Future<void> _openCreatePost() async {
    final allowed = await _checkProximity();
    if (!allowed) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need to be within 150 m to post here.'),
        ),
      );
      return;
    }

    final posted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePostScreen(
          pinnedLocation: LatLng(
            widget.placeDetails['lat'] as double,
            widget.placeDetails['lng'] as double,
          ),
          placeId: _placeId,
        ),
      ),
    );

    if (posted == true) {
      final fresh = await _fetchPlacePosts();
      if (mounted) setState(() => _posts = fresh);
    }
  }

  void _openPostDetail(Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => PostBottomSheet(
        post: post,
        postId: post['postId'] as String,
        collection: 'place_posts',
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(
      url.startsWith('http') ? url : 'https://$url',
    );
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _launchDirections(double lat, double lng) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DirectionsScreen(
          destinationLat:  lat,
          destinationLng:  lng,
          destinationName: widget.placeDetails['name'] as String? ?? 'Destination',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scroll) => Container(
        decoration: const BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: _buildContent(scroll),
      ),
    );
  }

  Widget _buildContent(ScrollController scroll) {
    final details  = widget.placeDetails;
    final name     = details['name']             as String? ?? '';
    final type     = details['type']             as String? ?? '';
    final address  = details['formatted_address'] as String? ?? '';
    final phone    = details['formatted_phone_number'] as String?;
    final website  = details['website']          as String?;
    final hoursMap = details['opening_hours']    as Map<String, dynamic>? ?? {};
    final isOpen   = hoursMap['open_now']        as bool?;
    final weekday  = List<String>.from(hoursMap['weekday_text'] as List? ?? []);
    final lat      = details['lat']              as double;
    final lng      = details['lng']              as double;
    final tags     = details['tags']             as Map<String, dynamic>? ?? {};

    final cuisine     = tags['cuisine']     as String?;
    final wheelchair  = tags['wheelchair']  as String?;
    final description = tags['description'] as String?;

    return CustomScrollView(
      controller: scroll,
      slivers: [

        // Drag handle
        SliverToBoxAdapter(
          child: Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: _grey200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),

        // Icon header
        SliverToBoxAdapter(
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: _colorForType(type).withOpacity(0.08),
              border: Border(bottom: BorderSide(color: _grey200)),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _colorForType(type).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _iconForType(type),
                      color: _colorForType(type),
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    name,
                    style: TextStyle(
                      color: _grey600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Name + chips + address
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: _grey900,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    if (type.isNotEmpty)
                      _Chip(label: _capitalise(type), color: _colorForType(type)),
                    if (cuisine != null)
                      _Chip(
                        label: _capitalise(cuisine.replaceAll(';', ' · ')),
                        color: Colors.orange,
                      ),
                    if (isOpen != null)
                      _Chip(
                        label: isOpen ? 'Open now' : 'Closed',
                        color: isOpen ? Colors.green : Colors.red,
                      ),
                    if (wheelchair == 'yes')
                      _Chip(label: 'Wheelchair accessible', color: Colors.blueGrey),
                  ],
                ),
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_outlined, color: _grey600, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          address,
                          style: TextStyle(color: _grey600, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
                if (description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(color: _grey600, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Action buttons
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _ActionBtn(
                  icon: Icons.directions_outlined,
                  label: 'Directions',
                  onTap: () => _launchDirections(lat, lng),
                ),
                if (phone != null)
                  _ActionBtn(
                    icon: Icons.phone_outlined,
                    label: 'Call',
                    onTap: () => _launchPhone(phone),
                  ),
                if (website != null)
                  _ActionBtn(
                    icon: Icons.language_outlined,
                    label: 'Website',
                    onTap: () => _launchUrl(website),
                  ),
                _ActionBtn(
                  icon: _isPinned
                      ? Icons.location_on
                      : Icons.add_location_alt_outlined,
                  label: _isPinned ? 'Pinned' : 'Pin area',
                  onTap: _togglePin,
                ),
              ],
            ),
          ),
        ),

        if (weekday.isNotEmpty)
          SliverToBoxAdapter(
            child: _HoursSection(weekdayText: weekday),
          ),

        // Divider
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            height: 1,
            color: _grey200,
          ),
        ),

        // Posts header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                const Text(
                  'Posts here',
                  style: TextStyle(
                    color: _grey900,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_posts.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${_posts.length}',
                    style: TextStyle(color: _grey600, fontSize: 14),
                  ),
                ],
                const Spacer(),
                GestureDetector(
                  onTap: _openCreatePost,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _canPost ? _accent : _surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _canPost ? _accent : _grey200,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _canPost
                              ? Icons.add_a_photo_outlined
                              : Icons.lock_outline,
                          color: _canPost ? Colors.white : _grey600,
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _canPost ? 'Post here' : 'Visit to post',
                          style: TextStyle(
                            color: _canPost ? Colors.white : _grey600,
                            fontSize: 13,
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

        if (_loadingPosts)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator(color: _accent)),
            ),
          )
        else if (_posts.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      _canPost
                          ? Icons.add_photo_alternate_outlined
                          : Icons.photo_library_outlined,
                      color: _grey200,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _canPost ? 'Be the first to post here!' : 'No posts yet.',
                      style: TextStyle(color: _grey600),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverGrid(
            delegate: SliverChildBuilderDelegate(
                  (_, i) {
                final post   = _posts[i];
                final imgUrl = post['imageUrl'] as String? ?? '';
                return GestureDetector(
                  onTap: () => _openPostDetail(post),
                  child: Container(
                    color: _grey200,
                    child: imgUrl.isNotEmpty
                        ? Image.network(imgUrl, fit: BoxFit.cover)
                        : Icon(Icons.photo, color: _grey600),
                  ),
                );
              },
              childCount: _posts.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
            ),
          ),

        SliverToBoxAdapter(
          child: SizedBox(
            height: MediaQuery.of(context).padding.bottom + 24,
          ),
        ),
      ],
    );
  }

  IconData _iconForType(String type) {
    if (['restaurant', 'fast food', 'food court'].contains(type)) return Icons.restaurant;
    if (['bar', 'pub', 'nightclub'].contains(type)) return Icons.local_bar;
    if (type == 'cafe') return Icons.local_cafe;
    if (type == 'gym' || type == 'fitness centre') return Icons.fitness_center;
    if (['pharmacy', 'hospital', 'clinic'].contains(type)) return Icons.local_pharmacy_outlined;
    if (['bank', 'atm'].contains(type)) return Icons.account_balance_outlined;
    if (type == 'fuel') return Icons.local_gas_station_outlined;
    if (['school', 'university', 'college'].contains(type)) return Icons.school_outlined;
    if (['hotel', 'hostel'].contains(type)) return Icons.hotel;
    if (type == 'park' || type == 'playground') return Icons.park;
    return Icons.storefront;
  }

  Color _colorForType(String type) {
    if (['restaurant', 'fast food', 'cafe', 'bar', 'pub'].contains(type)) {
      return const Color(0xFFE53935);
    }
    if (['gym', 'fitness centre', 'pharmacy', 'hospital'].contains(type)) {
      return const Color(0xFF43A047);
    }
    if (type == 'park' || type == 'playground') return const Color(0xFF7CB342);
    if (['hotel', 'hostel'].contains(type)) return const Color(0xFF00ACC1);
    return _accent;
  }

  String _capitalise(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

// ── Chip ──────────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final Color  color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Action button ─────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final VoidCallback onTap;

  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _accent  = Color(0xFF1E88E5);
  static const Color _grey200 = Color(0xFFEEEEEE);
  static const Color _grey700 = Color(0xFF616161);

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _grey200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _accent, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: _grey700, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hours section ─────────────────────────────────────────────────────────────

class _HoursSection extends StatefulWidget {
  final List<String> weekdayText;
  const _HoursSection({required this.weekdayText});

  @override
  State<_HoursSection> createState() => _HoursSectionState();
}

class _HoursSectionState extends State<_HoursSection> {
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _accent  = Color(0xFF1E88E5);
  static const Color _grey200 = Color(0xFFEEEEEE);
  static const Color _grey600 = Color(0xFF757575);
  static const Color _grey900 = Color(0xFF212121);

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _grey200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.access_time_outlined, color: _accent, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'Opening hours',
                  style: TextStyle(
                    color: _grey900,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Icon(
                  _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: _grey600,
                  size: 18,
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 10),
              ...widget.weekdayText.map(
                    (line) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    line,
                    style: const TextStyle(color: _grey600, fontSize: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}