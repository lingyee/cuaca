import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/weather_provider.dart';
import '../widgets/place_search_bar.dart';
import '../widgets/daily_forecast_view.dart';
import '../widgets/hourly_forecast_view.dart';
import '../widgets/rain_map_view.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tabIndex = 0;
  bool _showHourly = false;
  bool _initialLocationApplied = false;

  @override
  Widget build(BuildContext context) {
    // Apply GPS location once on first load
    final initialAsync = ref.watch(initialPlaceProvider);
    initialAsync.whenData((place) {
      if (!_initialLocationApplied && place != null) {
        _initialLocationApplied = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(selectedPlaceProvider.notifier).set(place);
        });
      }
    });

    final place = ref.watch(selectedPlaceProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: PlaceSearchBar(
                onPlaceSelected: () {
                  if (_tabIndex == 1) setState(() {}); // refresh map
                },
              ),
            ),
            // Location subtitle
            if (place != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.location_on,
                        size: 14,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        place.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            // Tab body
            Expanded(
              child: _tabIndex == 0
                  ? _ForecastTab(
                      showHourly: _showHourly,
                      onToggle: (v) => setState(() => _showHourly = v),
                    )
                  : const RainMapView(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.cloud_outlined),
            selectedIcon: Icon(Icons.cloud),
            label: 'Forecast',
          ),
          NavigationDestination(
            icon: Icon(Icons.radar_outlined),
            selectedIcon: Icon(Icons.radar),
            label: 'Rain Map',
          ),
        ],
      ),
    );
  }
}

class _ForecastTab extends ConsumerWidget {
  final bool showHourly;
  final ValueChanged<bool> onToggle;

  const _ForecastTab({required this.showHourly, required this.onToggle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final place = ref.watch(selectedPlaceProvider);

    if (place == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('Search for a place above',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final forecastAsync = ref.watch(forecastProvider(place));

    return forecastAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text('Failed to load forecast', style: TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.invalidate(forecastProvider(place)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (forecast) => Column(
        children: [
          // Toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Daily'), icon: Icon(Icons.calendar_today, size: 16)),
                ButtonSegment(value: true, label: Text('Hourly'), icon: Icon(Icons.schedule, size: 16)),
              ],
              selected: {showHourly},
              onSelectionChanged: (s) => onToggle(s.first),
            ),
          ),
          Expanded(
            child: showHourly
                ? HourlyForecastView(hours: forecast.hourly)
                : DailyForecastView(days: forecast.daily),
          ),
        ],
      ),
    );
  }
}
