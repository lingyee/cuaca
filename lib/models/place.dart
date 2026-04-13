import 'package:latlong2/latlong.dart';

class Place {
  final String displayName;
  final String shortName;
  final double lat;
  final double lon;

  const Place({
    required this.displayName,
    required this.shortName,
    required this.lat,
    required this.lon,
  });

  LatLng get latLng => LatLng(lat, lon);

  factory Place.fromNominatim(Map<String, dynamic> json) {
    final name = json['name'] as String? ??
        json['display_name']?.toString().split(',').first ??
        'Unknown';
    return Place(
      displayName: json['display_name'] as String? ?? name,
      shortName: name,
      lat: double.parse(json['lat'].toString()),
      lon: double.parse(json['lon'].toString()),
    );
  }

  factory Place.fromPhoton(Map<String, dynamic> feature) {
    final props = feature['properties'] as Map<String, dynamic>? ?? {};
    final coords = (feature['geometry']?['coordinates'] as List?) ?? [];

    final name = props['name'] as String? ?? '';
    final city = props['city'] as String? ?? '';
    final state = props['state'] as String? ?? '';
    final street = props['street'] as String? ?? '';

    final shortName = name.isNotEmpty ? name : (city.isNotEmpty ? city : street);

    final parts = [name, street, city, state]
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    final displayName = parts.isNotEmpty ? parts.join(', ') : shortName;

    return Place(
      displayName: displayName,
      shortName: shortName,
      lat: coords.length >= 2 ? (coords[1] as num).toDouble() : 0.0,
      lon: coords.length >= 2 ? (coords[0] as num).toDouble() : 0.0,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Place && other.lat == lat && other.lon == lon;

  @override
  int get hashCode => Object.hash(lat, lon);
}
