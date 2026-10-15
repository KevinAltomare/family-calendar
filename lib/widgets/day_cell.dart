import 'package:flutter/material.dart';

import '../widgets/day_view.dart';

class DayCell extends StatelessWidget {
  final int? day;
  final bool hasEvents;
  final DateTime? date;

  DayCell({required this.day, required this.date, this.hasEvents = false});

  DayCell.empty() : day = null, date = null, hasEvents = false;

  @override
  Widget build(BuildContext context) {
    if (day == null) {
      return Container();
    }

    final isToday =
        date != null &&
        date!.year == DateTime.now().year &&
        date!.month == DateTime.now().month &&
        date!.day == DateTime.now().day;
    final primary = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: () {
        if (date != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DayView(date: date!)),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isToday ? primary.withValues(alpha: 0.1) : Colors.transparent,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "$day",
              style: TextStyle(
                color: isToday ? primary : const Color(0xFF303A48),
                fontSize: 16,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (hasEvents)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
