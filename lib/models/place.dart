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

  @override
  bool operator ==(Object other) =>
      other is Place && other.lat == lat && other.lon == lon;

  @override
  int get hashCode => Object.hash(lat, lon);
}
