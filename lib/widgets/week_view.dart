import 'package:flutter/material.dart';

import '../screens/settings_screen.dart';
import '../services/calendar_service.dart';
import 'event_actions.dart';
import 'event_tile.dart';

class WeekView extends StatefulWidget {
  final DateTime initialDate;

  const WeekView({super.key, required this.initialDate});

  @override
  State<WeekView> createState() => _WeekViewState();
}

class _WeekViewState extends State<WeekView> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = _dateOnly(widget.initialDate);
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DateTime get _weekStart {
    final daysSinceSunday = _selectedDate.weekday % 7;
    return _selectedDate.subtract(Duration(days: daysSinceSunday));
  }

  void _moveWeek(int amount) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: amount * 7));
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final weekEnd = _weekStart.add(const Duration(days: 6));
    final dateFormat = MaterialLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Week'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
            icon: const Icon(Icons.settings_outlined),
          ),
          IconButton(
            tooltip: 'Previous week',
            onPressed: () => _moveWeek(-1),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          IconButton(
            tooltip: 'Next week',
            onPressed: () => _moveWeek(1),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Text(
              _weekLabel(dateFormat, _weekStart, weekEnd),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF7B8491),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            height: 84,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: 7,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final day = _weekStart.add(Duration(days: index));
                final isSelected = _isSameDay(day, _selectedDate);
                final isToday = _isSameDay(day, DateTime.now());
                return _WeekDayButton(
                  date: day,
                  selected: isSelected,
                  isToday: isToday,
                  onPressed: () => setState(() => _selectedDate = day),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              dateFormat.formatMediumDate(_selectedDate),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFF202A38),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: AnimatedBuilder(
              animation: CalendarService.instance,
              builder: (context, _) {
                final events = CalendarService.instance.eventsOn(_selectedDate);
                if (events.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.09),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.event_available_rounded,
                              color: colors.primary,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Nothing planned',
                            style: TextStyle(
                              color: Color(0xFF202A38),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Your events for this day will show up here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF7B8491),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: events.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return EventTile(
                      title: event.title,
                      startTime: event.startTime,
                      endTime: event.endTime,
                      isAllDay: event.isAllDay,
                      familyMember: event.familyMember,
                      onTap: () => handleEventTap(context, event),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _weekLabel(
    MaterialLocalizations dateFormat,
    DateTime start,
    DateTime end,
  ) {
    final startLabel = dateFormat.formatShortMonthDay(start);
    final endLabel = dateFormat.formatShortMonthDay(end);
    if (start.year != end.year) {
      return '$startLabel – ${dateFormat.formatMediumDate(end)}';
    }
    if (start.month != end.month) {
      return '$startLabel – ${dateFormat.formatShortMonthDay(end)}, ${end.year}';
    }
    return '$startLabel – $endLabel, ${end.year}';
  }

  bool _isSameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

class _WeekDayButton extends StatelessWidget {
  final DateTime date;
  final bool selected;
  final bool isToday;
  final VoidCallback onPressed;

  const _WeekDayButton({
    required this.date,
    required this.selected,
    required this.isToday,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foregroundColor = selected
        ? colors.onPrimary
        : const Color(0xFF303A48);

    return Semantics(
      button: true,
      selected: selected,
      label: MaterialLocalizations.of(context).formatFullDate(date),
      child: Material(
        color: selected ? colors.primary : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: 48,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _weekdayLabel(date.weekday),
                  style: TextStyle(
                    color: selected ? foregroundColor : const Color(0xFF8992A0),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '${date.day}',
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 16,
                    fontWeight: selected || isToday
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
                if (isToday && !selected)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _weekdayLabel(int weekday) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[weekday - 1];
  }
}
