import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/forecast.dart';

class DailyForecastView extends StatelessWidget {
  final List<DailyForecast> days;
  final List<HourlyForecast> hours;

  const DailyForecastView({
    super.key,
    required this.days,
    required this.hours,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: days.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (_, i) =>
          _DayCard(day: days[i], hours: hours, colorScheme: colorScheme),
    );
  }
}

class _DayCard extends StatefulWidget {
  final DailyForecast day;
  final List<HourlyForecast> hours;
  final ColorScheme colorScheme;

  const _DayCard({
    required this.day,
    required this.hours,
    required this.colorScheme,
  });

  @override
  State<_DayCard> createState() => _DayCardState();
}

class _DayCardState extends State<_DayCard> {
  bool _expanded = false;

  // Morning 6–11, representative 9:00; Afternoon 12–17, representative 15:00
  HourlyForecast? _periodEntry(int targetHour) {
    final candidates = widget.hours
        .where((h) => DateUtils.isSameDay(h.time, widget.day.date))
        .where((h) =>
            h.time.hour >= targetHour - 3 && h.time.hour <= targetHour + 3)
        .toList();
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => (a.time.hour - targetHour)
        .abs()
        .compareTo((b.time.hour - targetHour).abs()));
    return candidates.first;
  }

  // Night 18–5 next day, representative 21:00
  HourlyForecast? _nightEntry() {
    final nextDay = widget.day.date.add(const Duration(days: 1));
    final candidates = widget.hours
        .where((h) =>
            (DateUtils.isSameDay(h.time, widget.day.date) &&
                h.time.hour >= 18) ||
            (DateUtils.isSameDay(h.time, nextDay) && h.time.hour <= 5))
        .toList();
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) {
      final normA = a.time.hour >= 18 ? a.time.hour : a.time.hour + 24;
      final normB = b.time.hour >= 18 ? b.time.hour : b.time.hour + 24;
      return (normA - 21).abs().compareTo((normB - 21).abs());
    });
    return candidates.first;
  }

  @override
  Widget build(BuildContext context) {
    final day = widget.day;
    final isToday = DateUtils.isSameDay(day.date, DateTime.now());
    final dayLabel =
        isToday ? 'Today' : DateFormat('EEE, d MMM').format(day.date);

    return Card(
      elevation: 0,
      color: widget.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _expanded = !_expanded),
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
                              fontWeight: isToday
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 15,
                            )),
                        Text(weatherDescription(day.weatherCode),
                            style: TextStyle(
                              fontSize: 13,
                              color: widget.colorScheme.onSurfaceVariant,
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
                              color: widget.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: widget.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              // Summary row
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    _Chip(Icons.water_drop,
                        '${day.precipitationProbabilityMax}%', Colors.blue),
                    const SizedBox(width: 8),
                    _Chip(
                        Icons.umbrella,
                        '${day.precipitationSum.toStringAsFixed(1)} mm',
                        Colors.blueGrey),
                    const SizedBox(width: 8),
                    _Chip(Icons.air, '${day.windSpeedMax.round()} km/h',
                        Colors.teal),
                  ],
                ),
              ),
              if (_expanded) ...[
                const Divider(height: 16),
                for (final period in [
                  ('Morning', '🌅', _periodEntry(9)),
                  ('Afternoon', '☀️', _periodEntry(15)),
                  ('Night', '🌙', _nightEntry()),
                ])
                  if (period.$3 != null)
                    _PeriodRow(period.$1, period.$2, period.$3!, widget.colorScheme),
              ],
            ],
          ),
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

class _PeriodRow extends StatelessWidget {
  final String label;
  final String periodEmoji;
  final HourlyForecast entry;
  final ColorScheme colorScheme;

  const _PeriodRow(this.label, this.periodEmoji, this.entry, this.colorScheme);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
              width: 24,
              child: Text(periodEmoji,
                  style: const TextStyle(fontSize: 16))),
          SizedBox(
              width: 76,
              child: Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 13))),
          SizedBox(
              width: 28,
              child: Text(weatherEmoji(entry.weatherCode),
                  style: const TextStyle(fontSize: 16))),
          Expanded(
              child: Text(weatherDescription(entry.weatherCode),
                  style: TextStyle(
                      color: colorScheme.onSurfaceVariant, fontSize: 13))),
          Text('${entry.temperature.round()}°C',
              style:
                  TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
