import 'package:calendar_app/models/calendar_event.dart';
import 'package:calendar_app/screens/add_event_screen.dart';
import 'package:calendar_app/screens/home_screen.dart';
import 'package:calendar_app/services/calendar_service.dart';
import 'package:calendar_app/services/planner_service.dart';
import 'package:calendar_app/widgets/day_view.dart';
import 'package:calendar_app/widgets/month_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await CalendarService.instance.load();
    await PlannerService.instance.load();
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

  testWidgets(
    'shopping and to-do items can be added, completed, and restored',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.tap(find.text('Lists'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Add to Groceries'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Milk');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Add to To-do'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Book dentist');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Book dentist'), findsOneWidget);

      await tester.tap(find.byType(Checkbox).last);
      await tester.pumpAndSettle();
      expect(
        PlannerService.instance.items.where((item) => item.isCompleted),
        hasLength(1),
      );

      await PlannerService.instance.load();
      expect(PlannerService.instance.items, hasLength(2));
      expect(
        PlannerService.instance.items.where((item) => item.isCompleted),
        hasLength(1),
      );
    },
  );

  testWidgets('year view browses years and opens navigable months', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    await tester.tap(find.text('Year'));
    await tester.pumpAndSettle();

    final currentYear = DateTime.now().year;
    expect(find.text('YEAR OVERVIEW'), findsOneWidget);
    expect(find.text('$currentYear'), findsOneWidget);

    await tester.tap(find.byTooltip('Next year'));
    await tester.pumpAndSettle();
    expect(find.text('${currentYear + 1}'), findsOneWidget);

    await tester.tap(find.text('Jan'));
    await tester.pumpAndSettle();
    expect(find.text('January ${currentYear + 1}'), findsOneWidget);

    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
    expect(find.text('December $currentYear'), findsOneWidget);

    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    expect(find.text('January ${currentYear + 1}'), findsOneWidget);

    await tester.tap(find.text('Year'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Previous year'));
    await tester.pumpAndSettle();
    expect(find.text('$currentYear'), findsOneWidget);
  });

  testWidgets('landscape month cells preview colored events and overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    await CalendarService.instance.addEvent(
      CalendarEvent(
        id: 'soccer',
        title: 'Soccer practice',
        familyMember: 'Ethan',
        startTime: DateTime(firstDay.year, firstDay.month, firstDay.day, 9),
      ),
    );
    await CalendarService.instance.addEvent(
      CalendarEvent(
        id: 'piano',
        title: 'Piano lesson',
        familyMember: 'Micah',
        startTime: DateTime(firstDay.year, firstDay.month, firstDay.day, 10),
      ),
    );
    await CalendarService.instance.addEvent(
      CalendarEvent(
        id: 'dentist',
        title: 'Dentist',
        familyMember: 'Mom',
        startTime: DateTime(firstDay.year, firstDay.month, firstDay.day, 11),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MonthView(year: now.year, month: now.month),
        ),
      ),
    );

    final soccerPreview = tester.widget<Text>(find.text('Soccer practice'));
    expect(soccerPreview.style?.color, const Color(0xFF2E7D32));
    expect(find.text('Piano lesson'), findsOneWidget);
    expect(find.text('+1'), findsOneWidget);
    expect(find.text('Dentist'), findsNothing);
  });

  testWidgets('day view adds an event to the selected date', (tester) async {
    final selectedDate = DateTime(2026, 10, 20);
    await tester.pumpWidget(MaterialApp(home: DayView(date: selectedDate)));

    await tester.tap(find.byTooltip('Add event'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        MaterialLocalizations.of(tester.element(find.byType(AddEventScreen)))
            .formatMediumDate(selectedDate),
      ),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextFormField), 'Library visit');
    await tester.tap(find.text('Select a family member'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eli').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save event'));
    await tester.pumpAndSettle();

    expect(CalendarService.instance.eventsOn(selectedDate), hasLength(1));
    expect(find.text('Library visit'), findsOneWidget);
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
