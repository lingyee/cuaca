import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../config.dart';

// In-memory tile cache: URL → raw PNG bytes
final _tileCache = <String, Uint8List>{};

// Fixed zoom-4 tile coordinates covering all of Malaysia.
// The default view (zoom 6, center 4°N 109.5°E) extends slightly below the
// equator on every phone screen, so y=8 tiles are needed alongside y=7.
const _malaysiaTiles = [(4, 12, 7), (4, 13, 7), (4, 12, 8), (4, 13, 8)];

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

/// Deletes all slot subdirectories that don't match [currentTileTime].
/// Keeps storage tidy — at most 2 tiny PNG files (~50 KB total) per slot.
Future<void> _evictOldSlots(String currentTileTime) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final parent = Directory('${dir.path}/rain_tiles');
    if (!await parent.exists()) return;
    await for (final entity in parent.list()) {
      if (entity is Directory &&
          entity.path.split('/').last != currentTileTime) {
        await entity.delete(recursive: true);
      }
    }
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
  // Fire-and-forget cleanup of old slot directories; safe because all
  // tiles for currentTileTime are already loaded into _tileCache by this point.
  _evictOldSlots(tileTime);
}

/// Returns cached tile bytes for [url], or null if not yet cached.
Uint8List? getCachedTile(String url) => _tileCache[url];
