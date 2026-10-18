import 'dart:async';
import 'dart:convert';
import 'dart:math' show min;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:rrule/rrule.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/calendar_event.dart';

class CalendarService extends ChangeNotifier {
  CalendarService._();

  static final CalendarService instance = CalendarService._();
  static const _eventsKey = 'calendar_events';

  List<CalendarEvent> _events = [];
  String? _familyId;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _eventsSubscription;
  Object? _syncError;
  List<CalendarEvent> get events => List.unmodifiable(_events);
  Object? get syncError => _syncError;

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

  Future<void> connectToFamily(
    String familyId, {
    bool uploadLocalData = false,
  }) async {
    final localEvents = List<CalendarEvent>.of(_events);
    await _eventsSubscription?.cancel();
    _familyId = familyId;
    _syncError = null;
    final collection = FirebaseFirestore.instance
        .collection('families')
        .doc(familyId)
        .collection('events');
    final firstSnapshot = Completer<QuerySnapshot<Map<String, dynamic>>>();
    _eventsSubscription = collection.snapshots().listen(
      (snapshot) {
        try {
          _events =
              snapshot.docs
                  .map((doc) => CalendarEvent.fromJson(doc.data()))
                  .toList()
                ..sort(
                  (first, second) =>
                      first.startTime.compareTo(second.startTime),
                );
          _syncError = null;
          notifyListeners();
          if (!firstSnapshot.isCompleted) {
            firstSnapshot.complete(snapshot);
          }
        } catch (error, stackTrace) {
          _syncError = error;
          notifyListeners();
          if (!firstSnapshot.isCompleted) {
            firstSnapshot.completeError(error, stackTrace);
          }
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        _syncError = error;
        notifyListeners();
        if (!firstSnapshot.isCompleted) {
          firstSnapshot.completeError(error, stackTrace);
        }
      },
    );
    final snapshot = await firstSnapshot.future;
    if (uploadLocalData && snapshot.docs.isEmpty && localEvents.isNotEmpty) {
      for (var start = 0; start < localEvents.length; start += 500) {
        final batch = FirebaseFirestore.instance.batch();
        for (final event in localEvents.sublist(
          start,
          min(start + 500, localEvents.length),
        )) {
          batch.set(
            collection.doc(event.id),
            Map<String, dynamic>.from(event.toJson()),
          );
        }
        await batch.commit();
      }
    }
  }

  Future<void> disconnectFromFamily() async {
    await _eventsSubscription?.cancel();
    _eventsSubscription = null;
    _familyId = null;
    _syncError = null;
    await load();
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
    if (_familyId == null) {
      final encodedEvents = updatedEvents
          .map((event) => jsonEncode(event.toJson()))
          .toList();
      final preferences = await SharedPreferences.getInstance();
      final saved = await preferences.setStringList(_eventsKey, encodedEvents);
      if (!saved) {
        throw StateError('The event could not be saved to local storage.');
      }
    } else {
      final collection = FirebaseFirestore.instance
          .collection('families')
          .doc(_familyId)
          .collection('events');
      final oldEventsById = {for (final event in _events) event.id: event};
      final newEventsById = {
        for (final event in updatedEvents) event.id: event,
      };
      final batch = FirebaseFirestore.instance.batch();
      var writeCount = 0;

      for (final event in updatedEvents) {
        final oldEvent = oldEventsById[event.id];
        if (oldEvent != null &&
            jsonEncode(oldEvent.toJson()) == jsonEncode(event.toJson())) {
          continue;
        }
        batch.set(
          collection.doc(event.id),
          Map<String, dynamic>.from(event.toJson()),
        );
        writeCount++;
      }
      for (final id in oldEventsById.keys) {
        if (!newEventsById.containsKey(id)) {
          batch.delete(collection.doc(id));
          writeCount++;
        }
      }
      if (writeCount > 500) {
        throw StateError('Too many event changes to save in one operation.');
      }
      if (writeCount > 0) {
        await batch.commit();
      }
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
