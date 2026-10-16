import 'package:flutter/material.dart';

import '../services/calendar_service.dart';

class YearView extends StatelessWidget {
  final int year;
  final ValueChanged<int> onYearChanged;
  final ValueChanged<DateTime> onMonthSelected;

  const YearView({
    super.key,
    required this.year,
    required this.onYearChanged,
    required this.onMonthSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: isLandscape
              ? const EdgeInsets.fromLTRB(16, 6, 12, 4)
              : const EdgeInsets.fromLTRB(24, 22, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YEAR OVERVIEW',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$year',
                      style: TextStyle(
                        color: const Color(0xFF202A38),
                        fontSize: isLandscape ? 24 : 32,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Previous year',
                onPressed: () => onYearChanged(year - 1),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              IconButton(
                tooltip: 'Next year',
                onPressed: () => onYearChanged(year + 1),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ),
        Expanded(
          child: AnimatedBuilder(
            animation: CalendarService.instance,
            builder: (context, _) {
              final events = CalendarService.instance.eventsInRange(
                DateTime(year),
                DateTime(year + 1),
              );
              final eventDays = events
                  .map((event) => _dateKey(event.startTime))
                  .toSet();

              return LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth > 600 ? 4 : 3;
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: columns == 4 ? 1.2 : 0.74,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      final month = index + 1;
                      return _MonthCard(
                        year: year,
                        month: month,
                        name: monthNames[index],
                        eventDays: eventDays,
                        onTap: () => onMonthSelected(DateTime(year, month)),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MonthCard extends StatelessWidget {
  final int year;
  final int month;
  final String name;
  final Set<int> eventDays;
  final VoidCallback onTap;

  const _MonthCard({
    required this.year,
    required this.month,
    required this.name,
    required this.eventDays,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final offset = firstDay.weekday % 7;
    final today = DateTime.now();
    final isCurrentMonth = today.year == year && today.month == month;
    final primary = Theme.of(context).colorScheme.primary;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Semantics(
          button: true,
          label:
              'Open ${MaterialLocalizations.of(context).formatMonthYear(DateTime(year, month))}',
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: isCurrentMonth ? primary : const Color(0xFF303A48),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    for (final day in const ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
                      Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: TextStyle(
                              color: Color(0xFF8992A0),
                              fontSize: 7,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          childAspectRatio: 1,
                        ),
                    itemCount: 42,
                    itemBuilder: (context, index) {
                      final day = index - offset + 1;
                      if (day < 1 || day > daysInMonth) {
                        return const SizedBox.shrink();
                      }
                      final date = DateTime(year, month, day);
                      final isToday =
                          today.year == year &&
                          today.month == month &&
                          today.day == day;
                      final hasEvent = eventDays.contains(_dateKey(date));

                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isToday
                                  ? primary.withValues(alpha: 0.14)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$day',
                              style: TextStyle(
                                color: isToday
                                    ? primary
                                    : const Color(0xFF4C5664),
                                fontSize: 8,
                                fontWeight: isToday
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                          if (hasEvent)
                            Positioned(
                              bottom: 0,
                              child: Container(
                                width: 2,
                                height: 2,
                                decoration: BoxDecoration(
                                  color: primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

int _dateKey(DateTime date) => date.year * 10000 + date.month * 100 + date.day;
