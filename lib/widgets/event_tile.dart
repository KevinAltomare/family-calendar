import 'package:flutter/material.dart';

class EventTile extends StatelessWidget {
  final String title;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isAllDay;
  final String? subtitle;
  final String? familyMember;
  final Color? color;
  final VoidCallback? onTap;

  const EventTile({
    super.key,
    required this.title,
    required this.startTime,
    this.endTime,
    this.isAllDay = false,
    this.subtitle,
    this.familyMember,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final eventColor = color ?? Theme.of(context).colorScheme.primary;
    final timeLabel = isAllDay
        ? 'All day'
        : _formatTime(context, startTime, endTime);

    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: eventColor),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                child: Text(
                  timeLabel,
                  style: TextStyle(
                    color: eventColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 11, 14, 11),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF202A38),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if ((subtitle != null && subtitle!.isNotEmpty) ||
                          (familyMember != null &&
                              familyMember!.isNotEmpty)) ...[
                        const SizedBox(height: 4),
                        Text(
                          [
                            if (subtitle != null && subtitle!.isNotEmpty)
                              subtitle!,
                            if (familyMember != null &&
                                familyMember!.isNotEmpty)
                              familyMember!,
                          ].join(' · '),
                          style: const TextStyle(
                            color: Color(0xFF7B8491),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(BuildContext context, DateTime start, DateTime? end) {
    final localizations = MaterialLocalizations.of(context);
    final startLabel = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(start),
    );
    if (end == null) {
      return startLabel;
    }
    final endLabel = localizations.formatTimeOfDay(TimeOfDay.fromDateTime(end));
    return '$startLabel – $endLabel';
  }
}
