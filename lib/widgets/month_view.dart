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
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final cellWidth = (MediaQuery.sizeOf(context).width - 16) / 7;
    final landscapeAspectRatio = (cellWidth / 72).clamp(0.8, 1.45).toDouble();

    return AnimatedBuilder(
      animation: CalendarService.instance,
      builder: (context, _) {
        final cells = <Widget>[
          for (int i = 0; i < startWeekday; i++) DayCell.empty(),
          for (int day = 1; day <= daysInMonth; day++)
            DayCell(
              day: day,
              date: DateTime(year, month, day),
              events: CalendarService.instance.eventsOn(
                DateTime(year, month, day),
              ),
              showEventPreviews: isLandscape,
            ),
        ];

        return GridView.count(
          crossAxisCount: 7,
          childAspectRatio: isLandscape ? landscapeAspectRatio : 1.2,
          padding: const EdgeInsets.all(8),
          children: cells,
        );
      },
    );
  }
}
