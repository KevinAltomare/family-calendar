import 'package:flutter/material.dart';

import '../models/calendar_event.dart';
import '../services/calendar_service.dart';
import '../widgets/day_view.dart';
import '../widgets/month_view.dart';
import '../widgets/week_view.dart';
import '../widgets/year_view.dart';
import 'add_event_screen.dart';
import 'lists_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month);
  }

  Future<void> _openAddEvent() async {
    final event = await Navigator.push<CalendarEvent>(
      context,
      MaterialPageRoute<CalendarEvent>(builder: (_) => const AddEventScreen()),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save event: $error')));
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
              month: _displayedMonth,
              onMonthChanged: (month) =>
                  setState(() => _displayedMonth = month),
              onOpenSettings: _openSettings,
            ),
            YearView(
              year: _displayedMonth.year,
              onYearChanged: (year) => setState(
                () => _displayedMonth = DateTime(year, _displayedMonth.month),
              ),
              onMonthSelected: (month) => setState(() {
                _displayedMonth = month;
                _selectedIndex = 0;
              }),
            ),
            WeekView(initialDate: now),
            DayView(date: DateTime(now.year, now.month, now.day)),
            const ListsScreen(),
          ],
        ),
      ),
      floatingActionButton: _selectedIndex == 4
          ? null
          : FloatingActionButton(
              tooltip: 'Add event',
              onPressed: _openAddEvent,
              child: const Icon(Icons.add_rounded),
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
              icon: Icons.calendar_view_month_rounded,
              label: 'Year',
              selected: _selectedIndex == 1,
              color: colors.primary,
              onTap: () => setState(() => _selectedIndex = 1),
            ),
            _NavigationItem(
              icon: Icons.view_week_rounded,
              label: 'Week',
              selected: _selectedIndex == 2,
              color: colors.primary,
              onTap: () => setState(() => _selectedIndex = 2),
            ),
            _NavigationItem(
              icon: Icons.today_rounded,
              label: 'Today',
              selected: _selectedIndex == 3,
              color: colors.primary,
              onTap: () => setState(() => _selectedIndex = 3),
            ),
            _NavigationItem(
              icon: Icons.checklist_rounded,
              label: 'Lists',
              selected: _selectedIndex == 4,
              color: colors.primary,
              onTap: () => setState(() => _selectedIndex = 4),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthScreen extends StatefulWidget {
  final DateTime month;
  final ValueChanged<DateTime> onMonthChanged;
  final VoidCallback onOpenSettings;

  const _MonthScreen({
    required this.month,
    required this.onMonthChanged,
    required this.onOpenSettings,
  });

  @override
  State<_MonthScreen> createState() => _MonthScreenState();
}

class _MonthScreenState extends State<_MonthScreen> {
  double _horizontalDragDistance = 0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final month = widget.month;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: isLandscape
              ? const EdgeInsets.fromLTRB(16, 6, 12, 4)
              : const EdgeInsets.fromLTRB(24, 22, 16, 18),
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
                    SizedBox(height: isLandscape ? 2 : 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_monthName(month.month)} ${month.year}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: const Color(0xFF202A38),
                              fontSize: isLandscape ? 24 : 28,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.8,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Previous month',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => widget.onMonthChanged(
                            DateTime(month.year, month.month - 1),
                          ),
                          icon: const Icon(Icons.chevron_left_rounded),
                        ),
                        IconButton(
                          tooltip: 'Next month',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => widget.onMonthChanged(
                            DateTime(month.year, month.month + 1),
                          ),
                          icon: const Icon(Icons.chevron_right_rounded),
                        ),
                      ],
                    ),
                    if (!isLandscape) ...[
                      const SizedBox(height: 4),
                      const Text(
                        'I can\'t believe the month already halfway over!',
                        style: TextStyle(
                          color: Color(0xFF7B8491),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Settings',
                onPressed: widget.onOpenSettings,
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
                    padding: EdgeInsets.symmetric(
                      vertical: isLandscape ? 4 : 10,
                    ),
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
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (_) => _horizontalDragDistance = 0,
            onHorizontalDragUpdate: (details) {
              _horizontalDragDistance += details.delta.dx;
            },
            onHorizontalDragEnd: (_) {
              if (_horizontalDragDistance.abs() >= 50) {
                final direction = _horizontalDragDistance < 0 ? 1 : -1;
                widget.onMonthChanged(
                  DateTime(month.year, month.month + direction),
                );
              }
              _horizontalDragDistance = 0;
            },
            child: MonthView(year: month.year, month: month.month),
          ),
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
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
