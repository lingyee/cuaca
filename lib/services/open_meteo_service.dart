import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/forecast.dart';
import '../models/place.dart';

class OpenMeteoService {
  Future<Forecast> getForecast(Place place) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': place.lat.toString(),
      'longitude': place.lon.toString(),
      'daily': [
        'temperature_2m_max',
        'temperature_2m_min',
        'precipitation_sum',
        'weathercode',
        'precipitation_probability_max',
        'windspeed_10m_max',
      ].join(','),
      'hourly': [
        'temperature_2m',
        'precipitation_probability',
        'weathercode',
        'windspeed_10m',
      ].join(','),
      'timezone': 'Asia/Kuala_Lumpur',
      'forecast_days': '7',
    });

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to load forecast: ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    return _parse(data);
  }

  Forecast _parse(Map<String, dynamic> data) {
    final daily = data['daily'] as Map<String, dynamic>;
    final hourly = data['hourly'] as Map<String, dynamic>;

    final dailyDates = (daily['time'] as List).cast<String>();
    final dailyList = List.generate(dailyDates.length, (i) {
      return DailyForecast(
        date: DateTime.parse(dailyDates[i]),
        maxTemp: (daily['temperature_2m_max'][i] as num).toDouble(),
        minTemp: (daily['temperature_2m_min'][i] as num).toDouble(),
        precipitationSum: (daily['precipitation_sum'][i] as num? ?? 0).toDouble(),
        precipitationProbabilityMax:
            (daily['precipitation_probability_max'][i] as num? ?? 0).toInt(),
        weatherCode: (daily['weathercode'][i] as num).toInt(),
        windSpeedMax: (daily['windspeed_10m_max'][i] as num).toDouble(),
      );
    });

    final hourlyTimes = (hourly['time'] as List).cast<String>();
    final now = DateTime.now();
    final hourlyList = <HourlyForecast>[];
    for (int i = 0; i < hourlyTimes.length; i++) {
      final t = DateTime.parse(hourlyTimes[i]);
      if (t.isAfter(now.subtract(const Duration(hours: 1))) &&
          hourlyList.length < 48) {
        hourlyList.add(HourlyForecast(
          time: t,
          temperature: (hourly['temperature_2m'][i] as num).toDouble(),
          precipitationProbability:
              (hourly['precipitation_probability'][i] as num? ?? 0).toInt(),
          weatherCode: (hourly['weathercode'][i] as num).toInt(),
          windSpeed: (hourly['windspeed_10m'][i] as num).toDouble(),
        ));
      }
    }

    return Forecast(daily: dailyList, hourly: hourlyList);
  }
}
