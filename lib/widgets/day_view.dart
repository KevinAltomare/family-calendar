import 'package:flutter/material.dart';

import '../models/calendar_event.dart';
import '../screens/add_event_screen.dart';
import '../screens/settings_screen.dart';
import '../services/calendar_service.dart';
import 'event_tile.dart';

class DayView extends StatelessWidget {
  final DateTime date;

  const DayView({super.key, required this.date});

  Future<void> _addEvent(BuildContext context) async {
    final event = await Navigator.push<CalendarEvent>(
      context,
      MaterialPageRoute<CalendarEvent>(
        builder: (_) => AddEventScreen(initialDate: date),
      ),
    );
    if (event == null || !context.mounted) {
      return;
    }

    try {
      await CalendarService.instance.addEvent(event);
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save event: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = MaterialLocalizations.of(context).formatFullDate(date);

    return Scaffold(
      appBar: AppBar(
        title: Text(dateLabel),
        actions: [
          IconButton(
            tooltip: 'Add event',
            onPressed: () => _addEvent(context),
            icon: const Icon(Icons.add_rounded),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: CalendarService.instance,
        builder: (context, _) {
          final events = CalendarService.instance.eventsOn(date);
          if (events.isEmpty) {
            return const Center(
              child: Text(
                'No events for this day',
                style: TextStyle(color: Color(0xFF7B8491), fontSize: 16),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final event = events[index];
              return EventTile(
                title: event.title,
                startTime: event.startTime,
                endTime: event.endTime,
                familyMember: event.familyMember,
              );
            },
          );
        },
      ),
    );
  }
}
