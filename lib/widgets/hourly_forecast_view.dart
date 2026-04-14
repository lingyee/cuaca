import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/forecast.dart';

class HourlyForecastView extends StatelessWidget {
  final List<HourlyForecast> hours;

  const HourlyForecastView({super.key, required this.hours});

  @override
  Widget build(BuildContext context) {
    if (hours.isEmpty) {
      return const Center(child: Text('No hourly data available'));
    }

    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final currentHour = DateTime(now.year, now.month, now.day, now.hour);
    final upcoming = hours
        .where((h) => !h.time.isBefore(currentHour))
        .take(12)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('Next 12 Hours',
              style: Theme.of(context).textTheme.titleMedium),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: upcoming.length,
            itemBuilder: (_, i) {
              final h = upcoming[i];
              final isNow = h.time.year == now.year &&
                  h.time.month == now.month &&
                  h.time.day == now.day &&
                  h.time.hour == now.hour;
              final contentColor = isNow
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant;

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isNow
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    // Time
                    SizedBox(
                      width: 44,
                      child: Text(
                        isNow ? 'Now' : DateFormat('HH:mm').format(h.time),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isNow ? FontWeight.bold : FontWeight.normal,
                          color: contentColor,
                        ),
                      ),
                    ),
                    // Emoji
                    SizedBox(
                      width: 32,
                      child: Text(weatherEmoji(h.weatherCode),
                          style: const TextStyle(fontSize: 26)),
                    ),
                    const SizedBox(width: 8),
                    // Description + stats
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            weatherDescription(h.weatherCode),
                            style: TextStyle(fontSize: 13, color: contentColor),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(Icons.water_drop, size: 12, color: contentColor),
                              const SizedBox(width: 2),
                              Text('${h.precipitationProbability}%',
                                  style: TextStyle(fontSize: 11, color: contentColor)),
                              const SizedBox(width: 10),
                              Icon(Icons.air, size: 12, color: contentColor),
                              const SizedBox(width: 2),
                              Text('${h.windSpeed.round()} km/h',
                                  style: TextStyle(fontSize: 11, color: contentColor)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Temperature
                    SizedBox(
                      width: 48,
                      child: Text(
                        '${h.temperature.round()}°C',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isNow
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
