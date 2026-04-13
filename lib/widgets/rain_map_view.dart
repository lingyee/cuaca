import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../models/place.dart';
import '../providers/weather_provider.dart';

// Malaysia bounding center
const _malaysiaCentre = LatLng(4.0, 109.5);
const _malaysiaZoom = 5.0;
const _placeZoom = 11.0;

class RainMapView extends ConsumerStatefulWidget {
  const RainMapView({super.key});

  @override
  ConsumerState<RainMapView> createState() => _RainMapViewState();
}

class _RainMapViewState extends ConsumerState<RainMapView> {
  Timer? _timer;
  DateTime? _lastRefreshed;

  @override
  void initState() {
    super.initState();
    // If radar data is already cached, show the time immediately on remount
    ref.read(radarPathProvider).whenData((_) {
      _lastRefreshed = DateTime.now();
    });
    _timer = Timer.periodic(const Duration(minutes: 10), (_) {
      ref.invalidate(radarPathProvider);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final place = ref.watch(selectedPlaceProvider);
    final radarAsync = ref.watch(radarPathProvider);
    final mapController = ref.watch(mapControllerProvider);

    ref.listen<AsyncValue<String?>>(radarPathProvider, (_, next) {
      next.whenData((_) => setState(() => _lastRefreshed = DateTime.now()));
    });

    ref.listen<Place?>(selectedPlaceProvider, (_, place) {
      if (place != null) {
        mapController.move(place.latLng, _placeZoom);
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
            // RainViewer radar overlay
            radarAsync.when(
              data: (path) {
                if (path == null) return const SizedBox();
                return Opacity(
                  opacity: 0.7,
                  child: TileLayer(
                    urlTemplate:
                        'https://tilecache.rainviewer.com$path/256/{z}/{x}/{y}/2/1_1.png',
                    userAgentPackageName: 'com.cuaca',
                    maxNativeZoom: 7,
                  ),
                );
              },
              loading: () => const SizedBox(),
              error: (error, stack) => const SizedBox(),
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
                              color:
                                  Theme.of(context).colorScheme.onPrimary,
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
            child: GestureDetector(
              onTap: () => ref.invalidate(radarPathProvider),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.refresh, color: Colors.white, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      _lastRefreshed == null
                          ? 'Updating...'
                          : 'Updated ${DateFormat('d MMM yyyy, HH:mm').format(_lastRefreshed!)}',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ],
                ),
              ),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
    (Color(0xFF04D6F5), 'Light'),
    (Color(0xFF00C400), 'Moderate'),
    (Color(0xFFFFAA00), 'Heavy'),
    (Color(0xFFCC0000), 'Intense'),
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
          const Text('Rain',
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
