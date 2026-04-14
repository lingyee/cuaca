class DailyForecast {
  final DateTime date;
  final double maxTemp;
  final double minTemp;
  final double precipitationSum;
  final int precipitationProbabilityMax;
  final int weatherCode;
  final double windSpeedMax;

  const DailyForecast({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.precipitationSum,
    required this.precipitationProbabilityMax,
    required this.weatherCode,
    required this.windSpeedMax,
  });
}

class HourlyForecast {
  final DateTime time;
  final double temperature;
  final int precipitationProbability;
  final int weatherCode;
  final double windSpeed;

  const HourlyForecast({
    required this.time,
    required this.temperature,
    required this.precipitationProbability,
    required this.weatherCode,
    required this.windSpeed,
  });
}

class Forecast {
  final List<DailyForecast> daily;
  final List<HourlyForecast> hourly;

  const Forecast({required this.daily, required this.hourly});
}

String weatherDescription(int code) {
  if (code == 0) return 'Clear sky';
  if (code <= 2) return 'Partly cloudy';
  if (code == 3) return 'Cloudy';
  if (code <= 49) return 'Foggy';
  if (code <= 57) return 'Drizzle';
  if (code <= 67) return 'Rain';
  if (code <= 77) return 'Snow';
  if (code <= 82) return 'Rain showers';
  if (code <= 86) return 'Snow showers';
  if (code <= 99) return 'Thunderstorm';
  return 'Unknown';
}

String weatherEmoji(int code) {
  if (code == 0) return '☀️';
  if (code <= 2) return '⛅';
  if (code == 3) return '☁️';
  if (code <= 49) return '🌫️';
  if (code <= 57) return '🌦️';
  if (code <= 67) return '🌧️';
  if (code <= 77) return '❄️';
  if (code <= 82) return '🌦️';
  if (code <= 86) return '🌨️';
  if (code <= 99) return '⛈️';
  return '🌡️';
}
