import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/place.dart';

class NominatimService {
  static const _headers = {
    'User-Agent': 'CuacaApp/1.0 (malaysia-weather-app)',
    'Accept-Language': 'en',
  };

  Future<List<Place>> search(String query) async {
    if (query.trim().isEmpty) return [];
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query,
      'format': 'jsonv2',
      'countrycodes': 'my',
      'limit': '5',
      'addressdetails': '1',
    });
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) return [];
    final List<dynamic> data = json.decode(response.body);
    return data.map((e) => Place.fromNominatim(e as Map<String, dynamic>)).toList();
  }

  Future<Place?> reverseGeocode(double lat, double lon) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'lat': lat.toString(),
      'lon': lon.toString(),
      'format': 'jsonv2',
      'zoom': '16',
    });
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) return null;
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (data.containsKey('error')) return null;
    return Place.fromNominatim(data);
  }
}
