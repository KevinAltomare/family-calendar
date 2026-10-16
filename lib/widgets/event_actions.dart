import 'package:flutter/material.dart';

import '../models/calendar_event.dart';
import '../screens/add_event_screen.dart';
import '../services/calendar_service.dart';

enum _EventAction {
  editEvent,
  editOccurrence,
  editSeries,
  deleteEvent,
  deleteOccurrence,
  deleteSeries,
}

Future<void> handleEventTap(BuildContext context, CalendarEvent event) async {
  final action = await showDialog<_EventAction>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(event.title),
      children: [
        if (event.isRecurring) ...[
          SimpleDialogOption(
            onPressed: () =>
                Navigator.pop(context, _EventAction.editOccurrence),
            child: const Text('Edit just this one'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, _EventAction.editSeries),
            child: const Text('Edit all events'),
          ),
          SimpleDialogOption(
            onPressed: () =>
                Navigator.pop(context, _EventAction.deleteOccurrence),
            child: const Text('Delete just this one'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, _EventAction.deleteSeries),
            child: const Text('Delete all events'),
          ),
        ] else ...[
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, _EventAction.editEvent),
            child: const Text('Edit event'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, _EventAction.deleteEvent),
            child: const Text('Delete event'),
          ),
        ],
        SimpleDialogOption(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
  if (action == null || !context.mounted) {
    return;
  }

  final service = CalendarService.instance;
  try {
    switch (action) {
      case _EventAction.editEvent:
      case _EventAction.editOccurrence:
      case _EventAction.editSeries:
        final isSingleOccurrence = action == _EventAction.editOccurrence;
        final initialEvent = action == _EventAction.editSeries
            ? service.events.firstWhere((saved) => saved.id == event.id)
            : event;
        final editedEvent = await Navigator.push<CalendarEvent>(
          context,
          MaterialPageRoute<CalendarEvent>(
            builder: (_) => AddEventScreen(
              initialEvent: initialEvent,
              disableRecurrence: isSingleOccurrence,
            ),
          ),
        );
        if (editedEvent == null || !context.mounted) {
          return;
        }
        if (isSingleOccurrence) {
          final occurrenceDate = event.recurrenceInstanceDate!;
          await service.editOccurrence(event.id, occurrenceDate, editedEvent);
        } else {
          await service.updateEvent(editedEvent);
        }
      case _EventAction.deleteEvent:
      case _EventAction.deleteSeries:
        await service.deleteEvent(event.id);
      case _EventAction.deleteOccurrence:
        await service.skipOccurrence(event.id, event.recurrenceInstanceDate!);
    }
  } catch (error) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Could not update event: $error')));
  }
}
