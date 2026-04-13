import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/forecast.dart';

class DailyForecastView extends StatelessWidget {
  final List<DailyForecast> days;

  const DailyForecastView({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: days.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _DayCard(day: days[i], colorScheme: colorScheme),
    );
  }
}

class _DayCard extends StatelessWidget {
  final DailyForecast day;
  final ColorScheme colorScheme;

  const _DayCard({required this.day, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final isToday = DateUtils.isSameDay(day.date, DateTime.now());
    final dayLabel = isToday ? 'Today' : DateFormat('EEE, d MMM').format(day.date);

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Row(
              children: [
                Text(weatherEmoji(day.weatherCode),
                    style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dayLabel,
                          style: TextStyle(
                            fontWeight:
                                isToday ? FontWeight.bold : FontWeight.normal,
                            fontSize: 15,
                          )),
                      Text(weatherDescription(day.weatherCode),
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          )),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${day.maxTemp.round()}°C',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('${day.minTemp.round()}°C',
                        style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
            // Summary row
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  _Chip(Icons.water_drop,
                      '${day.precipitationProbabilityMax}%',
                      Colors.blue),
                  const SizedBox(width: 8),
                  _Chip(Icons.umbrella,
                      '${day.precipitationSum.toStringAsFixed(1)} mm',
                      Colors.blueGrey),
                  const SizedBox(width: 8),
                  _Chip(Icons.air, '${day.windSpeedMax.round()} km/h',
                      Colors.teal),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Chip(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}
