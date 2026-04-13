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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('Next 24 Hours',
              style: Theme.of(context).textTheme.titleMedium),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: hours.take(24).length,
            itemBuilder: (_, i) {
              final h = hours[i];
              final isNow = i == 0;
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
                      width: 48,
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
                    Text(weatherEmoji(h.weatherCode),
                        style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    // Description
                    Expanded(
                      child: Text(
                        weatherDescription(h.weatherCode),
                        style: TextStyle(fontSize: 13, color: contentColor),
                      ),
                    ),
                    // Temperature
                    SizedBox(
                      width: 48,
                      child: Text(
                        '${h.temperature.round()}°C',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isNow
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Rain
                    Icon(Icons.water_drop, size: 13, color: contentColor),
                    const SizedBox(width: 2),
                    SizedBox(
                      width: 32,
                      child: Text(
                        '${h.precipitationProbability}%',
                        style: TextStyle(fontSize: 12, color: contentColor),
                      ),
                    ),
                    // Wind
                    Icon(Icons.air, size: 13, color: contentColor),
                    const SizedBox(width: 2),
                    SizedBox(
                      width: 52,
                      child: Text(
                        '${h.windSpeed.round()} km/h',
                        style: TextStyle(fontSize: 12, color: contentColor),
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
