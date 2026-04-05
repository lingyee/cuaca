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
          child: Text('Next 48 Hours',
              style: Theme.of(context).textTheme.titleMedium),
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: hours.length,
            itemBuilder: (_, i) {
              final h = hours[i];
              final isNow = i == 0;
              return Container(
                width: 72,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isNow
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isNow ? 'Now' : DateFormat('HH:mm').format(h.time),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isNow ? FontWeight.bold : FontWeight.normal,
                        color: isNow
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(weatherEmoji(h.weatherCode),
                        style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 6),
                    Text(
                      '${h.temperature.round()}°',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isNow
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.water_drop,
                            size: 12,
                            color: isNow
                                ? colorScheme.onPrimaryContainer
                                : Colors.blue),
                        Text(
                          '${h.precipitationProbability}%',
                          style: TextStyle(
                            fontSize: 11,
                            color: isNow
                                ? colorScheme.onPrimaryContainer
                                : Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: hours.length,
            itemBuilder: (_, i) {
              final h = hours[i];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 52,
                      child: Text(
                        i == 0 ? 'Now' : DateFormat('HH:mm').format(h.time),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(weatherEmoji(h.weatherCode),
                        style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(weatherDescription(h.weatherCode),
                          style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 13)),
                    ),
                    Text('${h.temperature.round()}°C',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    Icon(Icons.water_drop, size: 14, color: Colors.blue),
                    Text('${h.precipitationProbability}%',
                        style:
                            const TextStyle(fontSize: 13, color: Colors.blue)),
                    const SizedBox(width: 8),
                    Icon(Icons.air, size: 14, color: Colors.teal),
                    Text('${h.windSpeed.round()}',
                        style:
                            const TextStyle(fontSize: 13, color: Colors.teal)),
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
