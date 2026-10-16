import 'package:flutter/material.dart';

import '../models/calendar_event.dart';
import '../widgets/day_view.dart';

class DayCell extends StatelessWidget {
  final int? day;
  final DateTime? date;
  final List<CalendarEvent> events;
  final bool showEventPreviews;

  const DayCell({
    super.key,
    required this.day,
    required this.date,
    this.events = const [],
    this.showEventPreviews = false,
  });

  const DayCell.empty({super.key})
    : day = null,
      date = null,
      events = const [],
      showEventPreviews = false;

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
    final visibleEvents = events.take(2).toList();
    final overflowCount = events.length - visibleEvents.length;

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
        child: showEventPreviews
            ? Padding(
                padding: const EdgeInsets.fromLTRB(4, 5, 4, 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '$day',
                        style: TextStyle(
                          color: isToday ? primary : const Color(0xFF303A48),
                          fontSize: 14,
                          fontWeight: isToday
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (events.isNotEmpty) const SizedBox(height: 2),
                    for (final event in visibleEvents)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: _EventPreview(event: event),
                      ),
                    if (overflowCount > 0)
                      Text(
                        '+$overflowCount',
                        style: const TextStyle(
                          color: Color(0xFF7B8491),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          height: 1,
                        ),
                      ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$day',
                    style: TextStyle(
                      color: isToday ? primary : const Color(0xFF303A48),
                      fontSize: 16,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  if (events.isNotEmpty)
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

class _EventPreview extends StatelessWidget {
  final CalendarEvent event;

  const _EventPreview({required this.event});

  @override
  Widget build(BuildContext context) {
    final color = _memberColor(event.familyMember);

    return Container(
      height: 13,
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        event.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
    );
  }

  Color _memberColor(String? familyMember) {
    return switch (familyMember?.toLowerCase()) {
      'ethan' => const Color(0xFF2E7D32),
      'micah' => const Color.fromARGB(255, 241, 71, 142),
      'mom' => const Color(0xFF7B1FA2),
      'dad' => const Color.fromARGB(255, 240, 220, 46),
      'eli' => const Color(0xFF1565C0),
      _ => const Color(0xFF6B7280),
    };
  }
}
