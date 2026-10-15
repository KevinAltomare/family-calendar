import 'package:calendar_app/models/calendar_event.dart';
import 'package:calendar_app/screens/home_screen.dart';
import 'package:calendar_app/services/calendar_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await CalendarService.instance.load();
  });

  testWidgets('bottom navigation switches between week and today', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    await tester.tap(find.text('Week').first);
    await tester.pumpAndSettle();
    expect(find.text('Nothing planned'), findsOneWidget);

    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    expect(find.text('No events for this day'), findsOneWidget);
  });

  testWidgets('add event button saves an event to local storage', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    await tester.tap(find.byTooltip('Add event'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'Test event');
    await tester.tap(find.text('Select a family member'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Micah').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save event'));
    await tester.pumpAndSettle();

    expect(CalendarService.instance.events.single.title, 'Test event');
    expect(CalendarService.instance.events.single.familyMember, 'Micah');

    await CalendarService.instance.load();
    expect(CalendarService.instance.events.single.title, 'Test event');
    expect(CalendarService.instance.events.single.familyMember, 'Micah');
  });

  test('event on a future date remains available after reload', () async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final event = CalendarEvent(
      id: 'future-event',
      title: 'Tomorrow event',
      startTime: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9),
      endTime: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 10),
    );

    await CalendarService.instance.addEvent(event);
    await CalendarService.instance.load();

    expect(CalendarService.instance.eventsOn(tomorrow), hasLength(1));
    expect(
      CalendarService.instance.eventsOn(tomorrow).single.title,
      'Tomorrow event',
    );
  });
}
