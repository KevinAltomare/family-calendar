import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:rrule/rrule.dart';
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
    _events =
        savedEvents
            .map(
              (event) => CalendarEvent.fromJson(
                jsonDecode(event) as Map<String, dynamic>,
              ),
            )
            .toList()
          ..sort(
            (first, second) => first.startTime.compareTo(second.startTime),
          );
    notifyListeners();
  }

  List<CalendarEvent> eventsOn(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    return eventsInRange(start, start.add(const Duration(days: 1)));
  }

  List<CalendarEvent> eventsInRange(DateTime start, DateTime end) {
    final results = <CalendarEvent>[];
    for (final event in _events) {
      if (!event.isRecurring) {
        if (!event.startTime.isBefore(start) && event.startTime.isBefore(end)) {
          results.add(event);
        }
        continue;
      }
      if (!event.startTime.isBefore(end)) {
        continue;
      }

      final rule = RecurrenceRule.fromString(event.recurrenceRule!);
      final eventStart = _asUtcWallTime(event.startTime);
      final rangeStart = _asUtcWallTime(start);
      final occurrences = rule.getInstances(
        start: eventStart,
        after: rangeStart.isBefore(eventStart) ? eventStart : rangeStart,
        includeAfter: true,
        before: _asUtcWallTime(end),
      );
      for (final occurrence in occurrences) {
        final occurrenceStart = DateTime(
          occurrence.year,
          occurrence.month,
          occurrence.day,
          occurrence.hour,
          occurrence.minute,
          occurrence.second,
          occurrence.millisecond,
          occurrence.microsecond,
        );
        if (event.skipDates.any(
          (skipDate) => _sameDate(skipDate, occurrenceStart),
        )) {
          continue;
        }
        results.add(event.occurrenceAt(occurrenceStart));
      }
    }
    results.sort(
      (first, second) => first.startTime.compareTo(second.startTime),
    );
    return results;
  }

  Future<void> addEvent(CalendarEvent event) async {
    await _saveEvents([..._events, event]);
  }

  Future<void> updateEvent(CalendarEvent event) async {
    final index = _events.indexWhere((savedEvent) => savedEvent.id == event.id);
    if (index == -1) {
      throw StateError('The event could not be found.');
    }
    final updatedEvents = [..._events]..[index] = event;
    await _saveEvents(updatedEvents);
  }

  Future<void> deleteEvent(String id) async {
    final updatedEvents = _events.where((event) => event.id != id).toList();
    if (updatedEvents.length == _events.length) {
      throw StateError('The event could not be found.');
    }
    await _saveEvents(updatedEvents);
  }

  Future<void> skipOccurrence(String id, DateTime date) async {
    final index = _events.indexWhere((event) => event.id == id);
    if (index == -1 || !_events[index].isRecurring) {
      throw StateError('The recurring event could not be found.');
    }
    final event = _events[index];
    if (event.skipDates.any((skipDate) => _sameDate(skipDate, date))) {
      return;
    }
    final updatedEvents = [..._events]
      ..[index] = CalendarEvent(
        id: event.id,
        title: event.title,
        familyMember: event.familyMember,
        responsiblePerson: event.responsiblePerson,
        startTime: event.startTime,
        endTime: event.endTime,
        isAllDay: event.isAllDay,
        recurrenceRule: event.recurrenceRule,
        skipDates: [
          ...event.skipDates,
          DateTime(date.year, date.month, date.day),
        ],
      );
    await _saveEvents(updatedEvents);
  }

  Future<void> editOccurrence(
    String seriesId,
    DateTime occurrenceDate,
    CalendarEvent editedEvent,
  ) async {
    final index = _events.indexWhere((event) => event.id == seriesId);
    if (index == -1 || !_events[index].isRecurring) {
      throw StateError('The recurring event could not be found.');
    }
    final series = _events[index];
    final updatedEvents = [..._events]
      ..[index] = CalendarEvent(
        id: series.id,
        title: series.title,
        familyMember: series.familyMember,
        responsiblePerson: series.responsiblePerson,
        startTime: series.startTime,
        endTime: series.endTime,
        isAllDay: series.isAllDay,
        recurrenceRule: series.recurrenceRule,
        skipDates: [
          ...series.skipDates,
          if (!series.skipDates.any((date) => _sameDate(date, occurrenceDate)))
            DateTime(
              occurrenceDate.year,
              occurrenceDate.month,
              occurrenceDate.day,
            ),
        ],
      )
      ..add(
        CalendarEvent(
          id: '${series.id}-${DateTime.now().microsecondsSinceEpoch}',
          title: editedEvent.title,
          familyMember: editedEvent.familyMember,
          responsiblePerson: editedEvent.responsiblePerson,
          startTime: editedEvent.startTime,
          endTime: editedEvent.endTime,
          isAllDay: editedEvent.isAllDay,
        ),
      );
    await _saveEvents(updatedEvents);
  }

  Future<void> _saveEvents(List<CalendarEvent> events) async {
    final updatedEvents = [...events]
      ..sort((first, second) => first.startTime.compareTo(second.startTime));
    final encodedEvents = updatedEvents
        .map((event) => jsonEncode(event.toJson()))
        .toList();
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setStringList(_eventsKey, encodedEvents);
    if (!saved) {
      throw StateError('The event could not be saved to local storage.');
    }

    _events = updatedEvents;
    notifyListeners();
  }

  DateTime _asUtcWallTime(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day, date.hour, date.minute);

  bool _sameDate(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}
