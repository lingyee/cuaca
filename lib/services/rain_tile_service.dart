import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import '../config.dart';

// In-memory tile cache: URL → raw PNG bytes
final _tileCache = <String, Uint8List>{};

// Zoom-3 tiles covering all of Malaysia (centre 4°N 109.5°E).
// 2 tiles vs 8 at zoom 4 — 75% fewer API calls, slight upscale on overlay.
const _overviewTiles = [
  (3, 6, 3),
  (3, 6, 4),
];

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

/// Returns the current UTC time rounded down to the nearest 10 minutes,
/// formatted as an ISO 8601 string for the timeline slider.
String nowcastTime10() {
  final now = DateTime.now().toUtc();
  final rounded = DateTime.utc(
    now.year,
    now.month,
    now.day,
    now.hour,
    now.minute - (now.minute % 10),
  );
  return '${rounded.toIso8601String().split('.').first}Z';
}

/// Converts a lat/lon to the zoom-3 tile (x, y) that contains it.
/// Matches maxNativeZoom: 3 used in the TileLayer overlay.
(int x, int y) _latLonToTile3(double lat, double lon) {
  final x = ((lon + 180) / 360 * 8).floor();
  final latRad = lat * math.pi / 180;
  final y = ((1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) / 2 * 8).floor();
  return (x, y);
}

// Cache path: <app_docs>/rain_tiles/<tileTime>/<z>_<x>_<y>.png
// Uses the documents directory (getFilesDir on Android) which persists
// across app restarts and is only cleared on uninstall.
Future<File> _tileFile(int z, int x, int y, String tileTime) async {
  final dir = await getApplicationDocumentsDirectory();
  final folder = Directory('${dir.path}/rain_tiles/$tileTime');
  await folder.create(recursive: true);
  return File('${folder.path}/${z}_${x}_${y}.png');
}

Future<Uint8List?> _loadFromDisk(int z, int x, int y, String tileTime) async {
  try {
    final f = await _tileFile(z, x, y, tileTime);
    if (await f.exists()) return await f.readAsBytes();
  } catch (_) {}
  return null;
}

Future<void> _saveToDisk(
    int z, int x, int y, String tileTime, Uint8List bytes) async {
  try {
    final f = await _tileFile(z, x, y, tileTime);
    await f.writeAsBytes(bytes, flush: true);
  } catch (_) {}
}

/// Deletes slot subdirectories whose names are not in [keepSlots].
/// Pass the full list of active timeline slots to preserve all cached history.
Future<void> evictOldSlots(List<String> keepSlots) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final parent = Directory('${dir.path}/rain_tiles');
    if (!await parent.exists()) return;
    final keepSet = keepSlots.toSet();
    await for (final entity in parent.list()) {
      if (entity is Directory &&
          !keepSet.contains(entity.path.split('/').last)) {
        await entity.delete(recursive: true);
      }
    }
  } catch (_) {}
}

/// Pre-fetches zoom-3 rain tiles. Checks memory → disk → network in order.
///
/// If [centre] is provided (GPS/selected place), only the single zoom-3 tile
/// containing that location is fetched — 1 API call.
/// If [centre] is null (no place pinned), the 2 overview tiles covering
/// all of Malaysia are fetched.
Future<void> prefetchMalaysiaTiles(String tileTime, {LatLng? centre}) async {
  final List<(int, int, int)> tiles;
  if (centre != null) {
    final (x, y) = _latLonToTile3(centre.latitude, centre.longitude);
    tiles = [(3, x, y)];
  } else {
    tiles = _overviewTiles;
  }

  for (final (z, x, y) in tiles) {
    final url = 'https://api.tomorrow.io/v4/map/tile/$z/$x/$y'
        '/precipitationIntensity/$tileTime.png'
        '?apikey=$tomorrowIoApiKey';

    // 1. Memory hit — already warm, nothing to do
    if (_tileCache.containsKey(url)) continue;

    // 2. Disk hit — tile was cached from a previous app session
    final disk = await _loadFromDisk(z, x, y, tileTime);
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
        await _saveToDisk(z, x, y, tileTime, response.bodyBytes);
      }
    } catch (_) {}
  }
}

/// Returns cached tile bytes for [url], or null if not yet cached.
Uint8List? getCachedTile(String url) => _tileCache[url];
