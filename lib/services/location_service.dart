import 'package:geolocator/geolocator.dart';
import '../models/place.dart';
import 'nominatim_service.dart';

class LocationService {
  final NominatimService _nominatim = NominatimService();

  Future<Place?> getInitialLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 10),
      );
      final place =
          await _nominatim.reverseGeocode(position.latitude, position.longitude);
      if (place != null) return place;
      // Fallback: return a Place with just coordinates if reverse geocode fails
      return Place(
        displayName: '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
        shortName: 'Current Location',
        lat: position.latitude,
        lon: position.longitude,
      );
    } catch (_) {
      return null;
    }
  }
}
