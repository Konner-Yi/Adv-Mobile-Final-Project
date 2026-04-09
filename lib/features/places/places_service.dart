import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

// No API key needed — Overpass is completely free and open.
const _overpassUrl = 'https://overpass-api.de/api/interpreter';

// ── Fetch nearby places ───────────────────────────────────────────────────
// Queries OSM for amenities, shops, tourism, and leisure nodes
// within [radiusMetres] of [center]. Nodes without a name are filtered out.
Future<List<Map<String, dynamic>>> fetchNearbyPlaces(
    LatLng center, {
      int radiusMetres = 1000,
    }) async {
  final query = '''
[out:json][timeout:10];
(
  node["amenity"](around:$radiusMetres,${center.latitude},${center.longitude});
  node["shop"](around:$radiusMetres,${center.latitude},${center.longitude});
  node["tourism"](around:$radiusMetres,${center.latitude},${center.longitude});
  node["leisure"](around:$radiusMetres,${center.latitude},${center.longitude});
);
out body;
''';

  try {
    final res = await http.post(
      Uri.parse(_overpassUrl),
      body: {'data': query},
    );

    if (res.statusCode != 200) return [];

    final body     = jsonDecode(res.body) as Map<String, dynamic>;
    final elements = List<Map<String, dynamic>>.from(body['elements'] ?? []);

    // Only return nodes that have a name tag
    return elements
        .where((e) => (e['tags']?['name'] as String?)?.isNotEmpty == true)
        .toList();
  } catch (_) {
    return [];
  }
}

// ── Normalise an OSM node into a details map ──────────────────────────────
// Converts the flat OSM tags structure into something the UI can consume
// directly — matching roughly the same shape as before so the bottom
// sheet needs minimal changes.
Map<String, dynamic> buildPlaceDetails(Map<String, dynamic> osmNode) {
  final tags = Map<String, dynamic>.from(osmNode['tags'] as Map? ?? {});
  final lat  = (osmNode['lat'] as num?)?.toDouble() ?? 0.0;
  final lng  = (osmNode['lon'] as num?)?.toDouble() ?? 0.0;

  final rawHours    = tags['opening_hours'] as String?;
  final weekdayText = rawHours != null ? _parseHours(rawHours) : <String>[];
  final isOpenNow   = rawHours != null ? _guessOpenNow(rawHours) : null;

  return {
    'osm_id':  osmNode['id'],
    'name':    tags['name'] ?? '',
    'type':    _primaryType(tags),

    'lat': lat,
    'lng': lng,
    'formatted_address': _buildAddress(tags),

    'formatted_phone_number': tags['phone'] ?? tags['contact:phone'],
    'website':                tags['website'] ?? tags['contact:website'],

    'opening_hours': {
      'raw':          rawHours,
      'open_now':     isOpenNow,
      'weekday_text': weekdayText,
    },

    // OSM has no star ratings — both stay null and the UI hides them
    'rating':             null,
    'user_ratings_total': null,

    'tags': tags,
  };
}

// ── Category helper (used by map_page.dart for marker icons) ─────────────
String categoryForNode(Map<String, dynamic> osmNode) {
  final tags    = Map<String, dynamic>.from(osmNode['tags'] as Map? ?? {});
  final amenity = tags['amenity'] as String? ?? '';
  final shop    = tags['shop']    as String? ?? '';
  final tourism = tags['tourism'] as String? ?? '';
  final leisure = tags['leisure'] as String? ?? '';

  if (['restaurant', 'fast_food', 'food_court'].contains(amenity)) return 'food';
  if (['bar', 'pub', 'nightclub', 'biergarten'].contains(amenity))  return 'bar';
  if (amenity == 'cafe')                                             return 'cafe';
  if (amenity == 'gym' || leisure == 'fitness_centre')              return 'gym';
  if (['pharmacy', 'hospital', 'clinic'].contains(amenity))         return 'health';
  if (['bank', 'atm'].contains(amenity))                            return 'bank';
  if (amenity == 'fuel')                                            return 'fuel';
  if (['school', 'university', 'college'].contains(amenity))        return 'education';
  if (amenity == 'hotel' || tourism == 'hotel' || tourism == 'hostel') return 'lodging';
  if (leisure == 'park' || leisure == 'playground')                 return 'park';
  if (shop.isNotEmpty)                                              return 'shop';
  if (tourism.isNotEmpty)                                           return 'tourism';
  return 'other';
}

// ── Private helpers ───────────────────────────────────────────────────────

String _primaryType(Map<String, dynamic> tags) {
  final raw = (tags['amenity'] ?? tags['shop'] ?? tags['tourism'] ?? tags['leisure'] ?? '') as String;
  return raw.replaceAll('_', ' ');
}

String _buildAddress(Map<String, dynamic> tags) {
  final parts  = <String>[];
  final number = tags['addr:housenumber'] as String?;
  final street = tags['addr:street']      as String?;
  final city   = tags['addr:city']        as String?;

  if (number != null && street != null) {
    parts.add('$number $street');
  } else if (street != null) {
    parts.add(street);
  }
  if (city != null) parts.add(city);
  return parts.join(', ');
}

bool? _guessOpenNow(String raw) {
  if (raw.trim() == '24/7') return true;
  return null; // full OSM hours parsing is complex — unknown = null
}

List<String> _parseHours(String raw) {
  if (raw.trim() == '24/7') return ['Open 24 hours, 7 days a week'];
  return raw.split(';').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
}

Future<List<Map<String, dynamic>>> searchPlacesByName(
    String query,
    LatLng center, {
      int radiusMetres = 2000,
    }) async {
  if (query.trim().isEmpty) return [];

  // Overpass regex search on the name tag — case insensitive
  final escaped = query.trim().replaceAll('"', '\\"');
  final overpassQuery = '''
[out:json][timeout:10];
(
  node["name"~"$escaped",i](around:$radiusMetres,${center.latitude},${center.longitude});
  way["name"~"$escaped",i](around:$radiusMetres,${center.latitude},${center.longitude});
);
out center body;
''';

  try {
    final res  = await http.post(
      Uri.parse(_overpassUrl),
      body: {'data': overpassQuery},
    );
    if (res.statusCode != 200) return [];

    final body     = jsonDecode(res.body) as Map<String, dynamic>;
    final elements = List<Map<String, dynamic>>.from(body['elements'] ?? []);

    // Ways return a `center` instead of direct lat/lon — normalise them
    return elements.map((e) {
      if (e['type'] == 'way' && e['center'] != null) {
        return {
          ...e,
          'lat': e['center']['lat'],
          'lon': e['center']['lon'],
        };
      }
      return e;
    }).where((e) => e['lat'] != null && e['lon'] != null).toList();
  } catch (_) {
    return [];
  }
}