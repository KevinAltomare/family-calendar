import 'package:calendar_app/models/calendar_event.dart';
import 'package:calendar_app/screens/add_event_screen.dart';
import 'package:calendar_app/services/calendar_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rrule/rrule.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await CalendarService.instance.load();
  });

  test('weekly events expand in a range and skipped dates persist', () async {
    final event = CalendarEvent(
      id: 'weekly-event',
      title: 'Dance class',
      startTime: DateTime(2026, 10, 13, 9),
      endTime: DateTime(2026, 10, 13, 10),
      recurrenceRule: 'RRULE:FREQ=WEEKLY;BYDAY=TU,TH;UNTIL=20261101T235959Z',
    );
    await CalendarService.instance.addEvent(event);

    final firstWeek = CalendarService.instance.eventsInRange(
      DateTime(2026, 10, 13),
      DateTime(2026, 10, 21),
    );
    expect(firstWeek.map((occurrence) => occurrence.startTime), [
      DateTime(2026, 10, 13, 9),
      DateTime(2026, 10, 15, 9),
      DateTime(2026, 10, 20, 9),
    ]);

    await CalendarService.instance.skipOccurrence(
      'weekly-event',
      DateTime(2026, 10, 15),
    );
    expect(CalendarService.instance.eventsOn(DateTime(2026, 10, 15)), isEmpty);

    await CalendarService.instance.load();
    expect(CalendarService.instance.eventsOn(DateTime(2026, 10, 15)), isEmpty);
    expect(CalendarService.instance.events.single.skipDates, [
      DateTime(2026, 10, 15),
    ]);
  });

  test(
    'monthly events keep their start day and stop at the end date',
    () async {
      await CalendarService.instance.addEvent(
        CalendarEvent(
          id: 'monthly-event',
          title: 'Monthly appointment',
          startTime: DateTime(2026, 10, 12, 14),
          recurrenceRule: 'RRULE:FREQ=MONTHLY;UNTIL=20261231T235959Z',
        ),
      );

      final occurrences = CalendarService.instance.eventsInRange(
        DateTime(2026, 10, 1),
        DateTime(2027, 1, 1),
      );
      expect(occurrences.map((event) => event.startTime), [
        DateTime(2026, 10, 12, 14),
        DateTime(2026, 11, 12, 14),
        DateTime(2026, 12, 12, 14),
      ]);
    },
  );

  test(
    'editing one occurrence skips the series date and adds a one-off',
    () async {
      await CalendarService.instance.addEvent(
        CalendarEvent(
          id: 'practice',
          title: 'Practice',
          startTime: DateTime(2026, 10, 13, 9),
          recurrenceRule: 'RRULE:FREQ=WEEKLY;BYDAY=TU',
        ),
      );
      await CalendarService.instance.editOccurrence(
        'practice',
        DateTime(2026, 10, 20),
        CalendarEvent(
          id: 'practice',
          title: 'Moved practice',
          familyMember: 'Ethan',
          startTime: DateTime(2026, 10, 22, 11),
          endTime: DateTime(2026, 10, 22, 12),
        ),
      );

      expect(
        CalendarService.instance.eventsOn(DateTime(2026, 10, 20)),
        isEmpty,
      );
      final movedEvent = CalendarService.instance
          .eventsOn(DateTime(2026, 10, 22))
          .single;
      expect(movedEvent.title, 'Moved practice');
      expect(movedEvent.familyMember, 'Ethan');
      expect(movedEvent.isRecurring, isFalse);
      expect(CalendarService.instance.events.first.skipDates, [
        DateTime(2026, 10, 20),
      ]);
    },
  );

  testWidgets('add-event form saves a weekly recurrence rule', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    CalendarEvent? savedEvent;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                savedEvent = await Navigator.push<CalendarEvent>(
                  context,
                  MaterialPageRoute<CalendarEvent>(
                    builder: (_) =>
                        AddEventScreen(initialDate: DateTime(2026, 10, 13)),
                  ),
                );
              },
              child: const Text('Open form'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open form'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Weekly practice');
    await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ethan').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Never'));
    await tester.tap(find.text('Never'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weekly').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save event'));
    await tester.tap(find.text('Save event'));
    await tester.pumpAndSettle();

    expect(savedEvent, isNotNull);
    final rule = RecurrenceRule.fromString(savedEvent!.recurrenceRule!);
    expect(rule.frequency, Frequency.weekly);
    expect(rule.byWeekDays.map((entry) => entry.day), [DateTime.tuesday]);
  });
}
