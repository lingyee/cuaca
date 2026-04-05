import 'dart:convert';
import 'package:http/http.dart' as http;

class RainViewerService {
  Future<String?> getLatestRadarPath() async {
    final response = await http.get(
      Uri.parse('https://api.rainviewer.com/public/weather-maps.json'),
    );
    if (response.statusCode != 200) return null;
    final data = json.decode(response.body) as Map<String, dynamic>;
    final radar = data['radar'] as Map<String, dynamic>?;
    final past = radar?['past'] as List?;
    if (past == null || past.isEmpty) return null;
    return (past.last as Map<String, dynamic>)['path'] as String?;
  }

  String tileUrl(String radarPath) {
    return 'https://tilecache.rainviewer.com$radarPath/256/{z}/{x}/{y}/2/1_1.png';
  }
}
