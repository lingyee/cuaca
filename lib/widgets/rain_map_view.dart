import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../config.dart';
import '../models/place.dart';
import '../providers/weather_provider.dart';
import '../services/rain_tile_service.dart';

// Malaysia bounding center
const _malaysiaCentre = LatLng(4.0, 109.5);
const _malaysiaZoom = 4.0;
const _placeZoom = 10.0;

class _PrefetchedTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer tileLayer) {
    final url = tileLayer.urlTemplate!
        .replaceAll('{z}', coordinates.z.toString())
        .replaceAll('{x}', coordinates.x.toString())
        .replaceAll('{y}', coordinates.y.toString());
    final cached = getCachedTile(url);
    if (cached != null) return MemoryImage(cached);
    return NetworkImage(url, headers: headers);
  }
}

class RainMapView extends ConsumerStatefulWidget {
  const RainMapView({super.key});

  @override
  ConsumerState<RainMapView> createState() => _RainMapViewState();
}

class _RainMapViewState extends ConsumerState<RainMapView>
    with WidgetsBindingObserver {
  Timer? _timer;
  DateTime? _lastRefreshed;
  bool _tilesReady = false;

  // Timeline slider state — 5 slots: index 0 = -40m, index 4 = Now
  int _sliderIndex = 4;  // thumb position + label (updates on drag)
  int _displayIndex = 4; // drives _tileTime (only updates when tiles ready)
  List<String> _timeSlots = []; // 5 timestamps, oldest→newest
  final _loadedSlots = <String>{}; // slots already prefetched
  bool _isFetchingSlot = false;
  int _prefetchProgress = 0; // 0–5, how many slots loaded so far

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastRefreshed = DateTime.now();
    _prefetch();
    _startTimer();
    // The mapController is a persistent singleton, so its last position is
    // retained across tab switches. Explicitly reset to Malaysia overview when
    // no place is pinned, so the user always gets the full-country view.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final place = ref.read(selectedPlaceProvider);
      final ctrl = ref.read(mapControllerProvider);
      if (place == null) {
        ctrl.move(_malaysiaCentre, _malaysiaZoom);
      } else {
        ctrl.move(place.latLng, _placeZoom);
      }
    });
  }

  /// Builds the 5-slot timeline: -40m, -30m, -20m, -10m, now (oldest→newest).
  List<String> _buildTimeSlots() {
    final base = DateTime.parse(nowcastTime10());
    return List.generate(5, (i) {
      final t = base.subtract(Duration(minutes: (4 - i) * 10));
      return '${t.toIso8601String().split('.').first}Z';
    });
  }

  Future<void> _prefetch() async {
    _timeSlots = _buildTimeSlots();
    final place = ref.read(selectedPlaceProvider);

    // Fetch latest first — show map immediately
    await prefetchMalaysiaTiles(_timeSlots[4], centre: place?.latLng);
    if (!mounted) return;
    _loadedSlots.add(_timeSlots[4]);
    setState(() {
      _displayIndex = 4;
      _tilesReady = true;
      _prefetchProgress = 1;
    });

    // Fetch remaining slots newest→oldest in background
    for (int i = 3; i >= 0; i--) {
      await prefetchMalaysiaTiles(_timeSlots[i], centre: place?.latLng);
      if (!mounted) return;
      _loadedSlots.add(_timeSlots[i]);
      setState(() => _prefetchProgress = 5 - i); // counts 2→5
    }
  }

  /// Fallback fetch for [index] when user drags to a not-yet-loaded slot.
  Future<void> _fetchSlot(int index) async {
    final t = _timeSlots[index];
    if (_loadedSlots.contains(t)) {
      setState(() {
        _sliderIndex = index;
        _displayIndex = index;
        _tilesReady = true;
      });
      return;
    }
    setState(() {
      _sliderIndex = index;
      _isFetchingSlot = true;
      _tilesReady = false;
    });
    final place = ref.read(selectedPlaceProvider);
    await prefetchMalaysiaTiles(t, centre: place?.latLng);
    if (mounted) {
      _loadedSlots.add(t);
      setState(() {
        _displayIndex = index;
        _isFetchingSlot = false;
        _tilesReady = true;
      });
    }
  }

  /// Formats a UTC ISO timestamp as local HH:mm.
  String _slotLabel(int index) {
    if (_timeSlots.isEmpty) return '';
    final utc = DateTime.parse(_timeSlots[index]);
    final local = utc.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(minutes: 10), (_) async {
      final newSlots = _buildTimeSlots();
      final newLatest = newSlots[4];
      final place = ref.read(selectedPlaceProvider);

      if (_sliderIndex == 4) {
        // User is at Now — fetch new latest and update display.
        if (mounted) setState(() => _tilesReady = false);
        await prefetchMalaysiaTiles(newLatest, centre: place?.latLng);
        if (mounted) {
          _loadedSlots.add(newLatest);
          _timeSlots = newSlots;
          setState(() {
            _sliderIndex = 4;
            _displayIndex = 4;
            _lastRefreshed = DateTime.now();
            _tilesReady = true;
          });
        }
      } else {
        // User is viewing history — update slot list silently, don't interrupt.
        if (mounted) {
          setState(() => _timeSlots = newSlots);
        }
        // Background fetch new latest without disrupting current view.
        prefetchMalaysiaTiles(newLatest, centre: place?.latLng)
            .then((_) => _loadedSlots.add(newLatest));
      }
      evictOldSlots(newSlots);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _timer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      final newSlots = _buildTimeSlots();
      final newLatest = newSlots[4];
      final latestChanged = _timeSlots.isEmpty || newLatest != _timeSlots[4];
      if (latestChanged && _sliderIndex == 4) {
        // Slot has advanced and user is at Now — hide stale overlay, re-fetch.
        if (mounted) setState(() => _tilesReady = false);
        final place = ref.read(selectedPlaceProvider);
        await prefetchMalaysiaTiles(newLatest, centre: place?.latLng);
        if (mounted) {
          _loadedSlots.add(newLatest);
          _timeSlots = newSlots;
          setState(() {
            _sliderIndex = 4;
            _displayIndex = 4;
            _lastRefreshed = DateTime.now();
            _tilesReady = true;
          });
        }
      } else {
        if (mounted) setState(() => _timeSlots = newSlots);
      }
      _startTimer();
    }
  }

  String get _tileTime =>
      _timeSlots.length > _displayIndex ? _timeSlots[_displayIndex] : nowcastTime10();

  String get _precipTileUrl =>
      'https://api.tomorrow.io/v4/map/tile/{z}/{x}/{y}'
      '/precipitationIntensity/$_tileTime.png'
      '?apikey=$tomorrowIoApiKey';

  @override
  Widget build(BuildContext context) {
    final place = ref.watch(selectedPlaceProvider);
    final mapController = ref.watch(mapControllerProvider);

    ref.listen<Place?>(selectedPlaceProvider, (_, place) {
      if (place != null) {
        mapController.move(place.latLng, _placeZoom);
      } else {
        mapController.move(_malaysiaCentre, _malaysiaZoom);
      }
    });

    final initialCenter = place?.latLng ?? _malaysiaCentre;
    final initialZoom = place != null ? _placeZoom : _malaysiaZoom;

    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: initialZoom,
            minZoom: 4.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            // Base OSM layer
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.cuaca',
            ),
            // Tomorrow.io precipitation overlay — cross-fades between frames
            // for smooth slider animation. Keyed by _tileTime so
            // AnimatedSwitcher detects timestamp changes.
            // maxNativeZoom=3: 2 zoom-3 tiles cover all Malaysia, upscaled
            // when zoomed in. Keeps API usage minimal.
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _tilesReady
                  ? Opacity(
                      key: ValueKey(_tileTime),
                      opacity: 0.9,
                      child: TileLayer(
                        urlTemplate: _precipTileUrl,
                        userAgentPackageName: 'com.cuaca',
                        maxNativeZoom: 3,
                        panBuffer: 0,
                        tileProvider: _PrefetchedTileProvider(),
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('loading')),
            ),
            // Marker for selected place
            if (place != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: place.latLng,
                    width: 160,
                    height: 60,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            place.shortName,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const Icon(Icons.location_pin,
                            color: Colors.red, size: 28),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
        // Centered refresh pill
        Positioned(
          top: 12,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _lastRefreshed == null
                    ? 'Updating...'
                    : 'Updated ${DateFormat('d MMM yyyy, HH:mm').format(_lastRefreshed!)}',
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ),
        ),
        // Timeline slider
        Positioned(
          bottom: 16,
          left: 12,
          right: 100, // leave room for legend
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Fixed-width label so slider length never changes
                SizedBox(
                  width: 40,
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _slotLabel(_sliderIndex),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                        if (_isFetchingSlot) ...[
                          const SizedBox(width: 6),
                          const SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  ), // Column
                ), // SizedBox
                const SizedBox(width: 4),
                Expanded(
                  child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 12),
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white38,
                    thumbColor: Colors.white,
                    overlayColor: Colors.white24,
                  ),
                  child: Slider(
                    min: 0,
                    max: 4,
                    divisions: 4,
                    value: _sliderIndex.toDouble(),
                    onChanged: (v) {
                      final idx = v.round();
                      setState(() => _sliderIndex = idx);
                      // Switch display instantly if slot already in memory
                      if (_timeSlots.isNotEmpty &&
                          _loadedSlots.contains(_timeSlots[idx])) {
                        setState(() {
                          _displayIndex = idx;
                          _tilesReady = true;
                        });
                      }
                    },
                    onChangeEnd: (v) {
                      final idx = v.round();
                      if (_timeSlots.isNotEmpty &&
                          !_loadedSlots.contains(_timeSlots[idx])) {
                        _fetchSlot(idx); // fallback for not-yet-loaded slot
                      }
                    },
                  ),
                ),
                ), // Expanded
              ],
            ),
          ),
        ),
        // Rain legend
        Positioned(
          bottom: 16,
          right: 12,
          child: _RainLegend(),
        ),
        // No GPS fallback label
        if (place == null)
          Positioned(
            top: 52,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Search a place to pin location',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RainLegend extends StatelessWidget {
  final List<(Color, String)> _entries = const [
    (Color(0xFF00BFFF), 'Light'),
    (Color(0xFF00C400), 'Shower'),
    (Color(0xFFFFAA00), 'Heavy'),
    (Color(0xFFCC0000), 'Torrential'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Rain Intensity',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          ..._entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: e.$1,
                          borderRadius: BorderRadius.circular(2),
                        )),
                    const SizedBox(width: 6),
                    Text(e.$2,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 11)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
