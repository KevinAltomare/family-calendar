import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/calendar_event.dart';

class CalendarService extends ChangeNotifier {
  CalendarService._();

  static final CalendarService instance = CalendarService._();
  static const _eventsKey = 'calendar_events';

  List<CalendarEvent> _events = [];
  List<CalendarEvent> get events => List.unmodifiable(_events);

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final savedEvents = preferences.getStringList(_eventsKey) ?? [];
    _events = savedEvents
        .map(
          (event) =>
              CalendarEvent.fromJson(jsonDecode(event) as Map<String, dynamic>),
        )
        .toList()
      ..sort((first, second) => first.startTime.compareTo(second.startTime));
    notifyListeners();
  }

  List<CalendarEvent> eventsOn(DateTime date) {
    return _events
        .where(
          (event) =>
              event.startTime.year == date.year &&
              event.startTime.month == date.month &&
              event.startTime.day == date.day,
        )
        .toList();
  }

  Future<void> addEvent(CalendarEvent event) async {
    final updatedEvents = [..._events, event]
      ..sort((first, second) => first.startTime.compareTo(second.startTime));
    final encodedEvents = updatedEvents
        .map((savedEvent) => jsonEncode(savedEvent.toJson()))
        .toList();

    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setStringList(_eventsKey, encodedEvents);
    if (!saved) {
      throw StateError('The event could not be saved to local storage.');
    }

    _events = updatedEvents;
    notifyListeners();
  }
}