import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import '../models/place.dart';
import '../models/forecast.dart';
import '../services/location_service.dart';
import '../services/open_meteo_service.dart';
import '../services/rainviewer_service.dart';

// Selected place (null = no location chosen)
final selectedPlaceProvider = StateProvider<Place?>((ref) => null);

// GPS + reverse geocode on startup
final initialPlaceProvider = FutureProvider<Place?>((ref) async {
  return LocationService().getInitialLocation();
});

// Weather forecast for a given place
final forecastProvider = FutureProvider.family<Forecast, Place>((ref, place) {
  return OpenMeteoService().getForecast(place);
});

// Latest RainViewer radar path
final radarPathProvider = FutureProvider<String?>((ref) {
  return RainViewerService().getLatestRadarPath();
});

// Map controller (used to programmatically move the map)
final mapControllerProvider = Provider<MapController>((ref) => MapController());
