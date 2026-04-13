import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/place.dart';

// Malaysia bounding box: minLon,minLat,maxLon,maxLat
const _malaysiaBbox = '99.6,0.85,119.3,7.4';
// Malaysia geographical centre — for location bias (boosts nearby results)
const _malaysiaCentreLon = '109.5';
const _malaysiaCentreLat = '4.0';
const _userAgent = 'cuaca-app/1.0 (weather app for Malaysia)';

class PhotonService {
  Future<List<Place>> search(String query) async {
    if (query.trim().isEmpty) return [];
    final uri = Uri.https('photon.komoot.io', '/api/', {
      'q': query,
      'limit': '5',
      'lang': 'en',
      'bbox': _malaysiaBbox,
      'lon': _malaysiaCentreLon,
      'lat': _malaysiaCentreLat,
      'location_bias_scale': '0.2',
    });
    final response = await http.get(uri, headers: {'User-Agent': _userAgent});
    debugPrint('Photon search status: ${response.statusCode}');
    if (response.statusCode != 200) return [];
    final data = json.decode(response.body) as Map<String, dynamic>;
    final features = data['features'] as List? ?? [];
    debugPrint('Photon features count: ${features.length}');
    final places = features
        .where((e) {
          final props = (e as Map<String, dynamic>)['properties']
              as Map<String, dynamic>? ?? {};
          return (props['countrycode'] as String?)?.toUpperCase() == 'MY';
        })
        .map((e) => Place.fromPhoton(e as Map<String, dynamic>))
        .where((p) => p.shortName.isNotEmpty)
        .toList();
    debugPrint('Photon places after filter: ${places.length}');
    return places;
  }

  Future<Place?> reverseGeocode(double lat, double lon) async {
    final uri = Uri.https('photon.komoot.io', '/reverse', {
      'lat': lat.toString(),
      'lon': lon.toString(),
      'limit': '1',
      'lang': 'en',
    });
    final response = await http.get(uri, headers: {'User-Agent': _userAgent});
    if (response.statusCode != 200) return null;
    final data = json.decode(response.body) as Map<String, dynamic>;
    final features = data['features'] as List? ?? [];
    if (features.isEmpty) return null;
    return Place.fromPhoton(features.first as Map<String, dynamic>);
  }
}
