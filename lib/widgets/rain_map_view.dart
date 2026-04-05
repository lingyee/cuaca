import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../providers/weather_provider.dart';

// Malaysia bounding center
const _malaysiaCentre = LatLng(4.0, 109.5);
const _malaysiaZoom = 5.0;
const _placeZoom = 15.0;

class RainMapView extends ConsumerStatefulWidget {
  const RainMapView({super.key});

  @override
  ConsumerState<RainMapView> createState() => _RainMapViewState();
}

class _RainMapViewState extends ConsumerState<RainMapView> {
  @override
  Widget build(BuildContext context) {
    final place = ref.watch(selectedPlaceProvider);
    final radarAsync = ref.watch(radarPathProvider);
    final mapController = ref.watch(mapControllerProvider);

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
              flags: InteractiveFlag.all,
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
        // Refresh button
        Positioned(
          top: 12,
          right: 12,
          child: FloatingActionButton.small(
            heroTag: 'refresh_radar',
            onPressed: () => ref.invalidate(radarPathProvider),
            tooltip: 'Refresh radar',
            child: const Icon(Icons.refresh),
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
            top: 12,
            left: 12,
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
      ],
    );
  }
}

class _RainLegend extends StatelessWidget {
  final List<(Color, String)> _entries = const [
    (Color(0xFF00D8FF), 'Light'),
    (Color(0xFF00FF00), 'Moderate'),
    (Color(0xFFFFFF00), 'Heavy'),
    (Color(0xFFFF0000), 'Intense'),
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
