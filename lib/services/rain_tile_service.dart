import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config.dart';

// In-memory tile cache: URL → raw PNG bytes
final _tileCache = <String, Uint8List>{};

// Fixed zoom-4 tile coordinates covering all of Malaysia
const _malaysiaTiles = [(4, 12, 7), (4, 13, 7)]; // (z, x, y)

/// Returns the current UTC time rounded down to the nearest 5 minutes,
/// formatted as an ISO 8601 string for the Tomorrow.io tile URL.
String nowcastTime() {
  final now = DateTime.now().toUtc();
  final rounded = DateTime.utc(
    now.year,
    now.month,
    now.day,
    now.hour,
    now.minute - (now.minute % 5),
  );
  return '${rounded.toIso8601String().split('.').first}Z';
}

/// Pre-fetches the 2 zoom-4 tiles that cover all of Malaysia and stores them
/// in the in-memory cache. Fire-and-forget: errors are silently swallowed.
Future<void> prefetchMalaysiaTiles(String tileTime) async {
  for (final (z, x, y) in _malaysiaTiles) {
    final url = 'https://api.tomorrow.io/v4/map/tile/$z/$x/$y'
        '/precipitationIntensity/$tileTime.png'
        '?apikey=$tomorrowIoApiKey';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'cuaca-app/1.0'},
      );
      if (response.statusCode == 200) {
        _tileCache[url] = response.bodyBytes;
      }
    } catch (_) {}
  }
}

/// Returns cached tile bytes for [url], or null if not yet cached.
Uint8List? getCachedTile(String url) => _tileCache[url];
