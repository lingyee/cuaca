import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
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

Future<File> _tileFile(String url) async {
  final dir = await getTemporaryDirectory();
  final folder = Directory('${dir.path}/rain_tiles');
  await folder.create(recursive: true);
  final name = base64Url.encode(utf8.encode(url));
  return File('${folder.path}/$name');
}

Future<Uint8List?> _loadFromDisk(String url) async {
  try {
    final f = await _tileFile(url);
    if (await f.exists()) return await f.readAsBytes();
  } catch (_) {}
  return null;
}

Future<void> _saveToDisk(String url, Uint8List bytes) async {
  try {
    final f = await _tileFile(url);
    await f.writeAsBytes(bytes, flush: true);
  } catch (_) {}
}

/// Pre-fetches the 2 zoom-4 tiles that cover all of Malaysia.
/// Checks memory cache → disk cache → network, in that order.
/// Only hits the network when the tile is not cached anywhere.
Future<void> prefetchMalaysiaTiles(String tileTime) async {
  for (final (z, x, y) in _malaysiaTiles) {
    final url = 'https://api.tomorrow.io/v4/map/tile/$z/$x/$y'
        '/precipitationIntensity/$tileTime.png'
        '?apikey=$tomorrowIoApiKey';

    // 1. Memory hit — already warm, nothing to do
    if (_tileCache.containsKey(url)) continue;

    // 2. Disk hit — tile was cached from a previous app session
    final disk = await _loadFromDisk(url);
    if (disk != null) {
      _tileCache[url] = disk;
      continue;
    }

    // 3. Network fetch — only reached when data is genuinely new
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'cuaca-app/1.0'},
      );
      if (response.statusCode == 200) {
        _tileCache[url] = response.bodyBytes;
        await _saveToDisk(url, response.bodyBytes);
      }
    } catch (_) {}
  }
}

/// Returns cached tile bytes for [url], or null if not yet cached.
Uint8List? getCachedTile(String url) => _tileCache[url];
