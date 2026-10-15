import 'package:flutter/material.dart';

import '../models/calendar_event.dart';
import '../services/calendar_service.dart';
import '../widgets/day_view.dart';
import '../widgets/month_view.dart';
import '../widgets/week_view.dart';
import 'add_event_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  Future<void> _openAddEvent() async {
    final event = await Navigator.push<CalendarEvent>(
      context,
      MaterialPageRoute<CalendarEvent>(
        builder: (_) => const AddEventScreen(),
      ),
    );
    if (event == null || !mounted) {
      return;
    }

    try {
      await CalendarService.instance.addEvent(event);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save event: $error')),
      );
    }
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final now = DateTime.now();

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _MonthScreen(
              now: now,
              onOpenSettings: _openSettings,
            ),
            WeekView(initialDate: now),
            DayView(date: DateTime(now.year, now.month, now.day)),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE9ECF0))),
        ),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavigationItem(
              icon: Icons.calendar_month_rounded,
              label: 'Month',
              selected: _selectedIndex == 0,
              color: colors.primary,
              onTap: () => setState(() => _selectedIndex = 0),
            ),
            _NavigationItem(
              icon: Icons.view_week_rounded,
              label: 'Week',
              selected: _selectedIndex == 1,
              color: colors.primary,
              onTap: () => setState(() => _selectedIndex = 1),
            ),
            _NavigationItem(
              icon: Icons.today_rounded,
              label: 'Today',
              selected: _selectedIndex == 2,
              color: colors.primary,
              onTap: () => setState(() => _selectedIndex = 2),
            ),
            IconButton.filled(
              tooltip: 'Add event',
              onPressed: _openAddEvent,
              icon: const Icon(Icons.add_rounded),
              style: IconButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(48, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthScreen extends StatelessWidget {
  final DateTime now;
  final VoidCallback onOpenSettings;

  const _MonthScreen({
    required this.now,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 16, 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FAMILY CALENDAR',
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_monthName(now.month)} ${now.year}',
                      style: const TextStyle(
                        color: Color(0xFF202A38),
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'I can\'t believe the month already halfway over!',
                      style: TextStyle(
                        color: Color(0xFF7B8491),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Settings',
                onPressed: onOpenSettings,
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: const ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
              return Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      day,
                      style: const TextStyle(
                        color: Color(0xFF8992A0),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: MonthView(year: now.year, month: now.month),
        ),
      ],
    );
  }

  String _monthName(int month) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[month - 1];
  }
}

class _NavigationItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _NavigationItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final itemColor = selected ? color : const Color(0xFF929AA6);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: itemColor, size: 23),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: itemColor,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
