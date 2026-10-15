import 'package:flutter/material.dart';

import '../services/calendar_service.dart';
import 'day_cell.dart';

class MonthView extends StatelessWidget {
  final int year;
  final int month;

  const MonthView({super.key, required this.year, required this.month});

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; // Sunday = 0

    return AnimatedBuilder(
      animation: CalendarService.instance,
      builder: (context, _) {
        final cells = <Widget>[
          for (int i = 0; i < startWeekday; i++) DayCell.empty(),
          for (int day = 1; day <= daysInMonth; day++)
            DayCell(
              day: day,
              date: DateTime(year, month, day),
              hasEvents: CalendarService.instance
                  .eventsOn(DateTime(year, month, day))
                  .isNotEmpty,
            ),
        ];

        return GridView.count(
          crossAxisCount: 7,
          childAspectRatio: 1.2,
          padding: const EdgeInsets.all(8),
          children: cells,
        );
      },
    );
  }
}