import 'package:flutter/material.dart';
import 'package:rrule/rrule.dart';

import '../models/calendar_event.dart';

class AddEventScreen extends StatefulWidget {
  final DateTime? initialDate;
  final CalendarEvent? initialEvent;
  final bool disableRecurrence;

  const AddEventScreen({
    super.key,
    this.initialDate,
    this.initialEvent,
    this.disableRecurrence = false,
  });

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  static const _familyMembers = ['Ethan', 'Micah', 'Eli', 'Mom', 'Dad'];
  static const _weekdays = [
    (label: 'S', day: DateTime.sunday),
    (label: 'M', day: DateTime.monday),
    (label: 'T', day: DateTime.tuesday),
    (label: 'W', day: DateTime.wednesday),
    (label: 'T', day: DateTime.thursday),
    (label: 'F', day: DateTime.friday),
    (label: 'S', day: DateTime.saturday),
  ];

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  String? _selectedFamilyMember;
  DateTime _date = DateTime.now();
  DateTime? _repeatUntil;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  _RepeatFrequency _repeatFrequency = _RepeatFrequency.never;
  final Set<int> _selectedWeekdays = {};
  String? _timeError;
  String? _recurrenceError;

  @override
  void initState() {
    super.initState();
    final initialEvent = widget.initialEvent;
    final initialDate = initialEvent?.startTime ?? widget.initialDate;
    if (initialDate != null) {
      _date = DateTime(initialDate.year, initialDate.month, initialDate.day);
    }
    if (initialEvent != null) {
      _titleController.text = initialEvent.title;
      _selectedFamilyMember = initialEvent.familyMember;
      _startTime = TimeOfDay.fromDateTime(initialEvent.startTime);
      final endTime = initialEvent.endTime;
      if (endTime != null) {
        _endTime = TimeOfDay.fromDateTime(endTime);
      }

      final ruleString = initialEvent.recurrenceRule;
      if (ruleString != null && !widget.disableRecurrence) {
        final rule = RecurrenceRule.fromString(ruleString);
        _repeatFrequency = switch (rule.frequency) {
          Frequency.daily => _RepeatFrequency.daily,
          Frequency.weekly => _RepeatFrequency.weekly,
          Frequency.monthly => _RepeatFrequency.monthly,
          _ => _RepeatFrequency.never,
        };
        _selectedWeekdays.addAll(rule.byWeekDays.map((entry) => entry.day));
        final until = rule.until;
        if (until != null) {
          _repeatUntil = DateTime(until.year, until.month, until.day);
        }
      }
      if (_repeatFrequency == _RepeatFrequency.weekly &&
          _selectedWeekdays.isEmpty) {
        _selectedWeekdays.add(_date.weekday);
      }
    } else {
      _selectedWeekdays.add(_date.weekday);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() => _date = date);
    }
  }

  Future<void> _selectRepeatUntil() async {
    final initialDate = _repeatUntil ?? _date.add(const Duration(days: 30));
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(_date) ? _date : initialDate,
      firstDate: _date,
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() => _repeatUntil = date);
    }
  }

  Future<void> _selectTime({required bool isStart}) async {
    final time = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (time != null) {
      setState(() {
        if (isStart) {
          _startTime = time;
        } else {
          _endTime = time;
        }
        _timeError = null;
      });
    }
  }

  void _saveEvent() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_repeatUntil != null && _repeatUntil!.isBefore(_date)) {
      setState(
        () => _recurrenceError = 'End date must be on or after the event date.',
      );
      return;
    }
    if (_repeatFrequency == _RepeatFrequency.weekly &&
        _selectedWeekdays.isEmpty) {
      setState(() => _recurrenceError = 'Select at least one day.');
      return;
    }

    final start = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _startTime.hour,
      _startTime.minute,
    );
    final end = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _endTime.hour,
      _endTime.minute,
    );
    if (!end.isAfter(start)) {
      setState(() => _timeError = 'End time must be after the start time.');
      return;
    }

    final recurrenceRule = switch (_repeatFrequency) {
      _RepeatFrequency.never => null,
      _RepeatFrequency.daily => _buildRecurrenceRule(Frequency.daily),
      _RepeatFrequency.weekly => _buildRecurrenceRule(
        Frequency.weekly,
        byWeekDays: _selectedWeekdays,
      ),
      _RepeatFrequency.monthly => _buildRecurrenceRule(Frequency.monthly),
    };
    final initialEvent = widget.initialEvent;
    Navigator.pop(
      context,
      CalendarEvent(
        id:
            initialEvent?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        familyMember: _selectedFamilyMember,
        startTime: start,
        endTime: end,
        recurrenceRule: recurrenceRule,
        skipDates: recurrenceRule == null
            ? const []
            : initialEvent?.skipDates ?? const [],
      ),
    );
  }

  String _buildRecurrenceRule(
    Frequency frequency, {
    Set<int> byWeekDays = const {},
  }) {
    final until = _repeatUntil;
    return RecurrenceRule(
      frequency: frequency,
      byWeekDays: byWeekDays.map(ByWeekDayEntry.new).toList(),
      until: until == null
          ? null
          : DateTime.utc(until.year, until.month, until.day, 23, 59, 59),
    ).toString();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = MaterialLocalizations.of(context);
    final isEditing = widget.initialEvent != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit event' : 'Add event')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _titleController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Event name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter an event name.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedFamilyMember,
              decoration: const InputDecoration(
                labelText: 'Family member',
                prefixIcon: Icon(Icons.person_outline_rounded),
                border: OutlineInputBorder(),
              ),
              items: _familyMembers
                  .map(
                    (member) =>
                        DropdownMenuItem(value: member, child: Text(member)),
                  )
                  .toList(),
              onChanged: (member) {
                setState(() => _selectedFamilyMember = member);
              },
              validator: (member) =>
                  member == null ? 'Select a family member.' : null,
            ),
            const SizedBox(height: 16),
            _EventDateTimeTile(
              icon: Icons.calendar_today_outlined,
              title: 'Date',
              value: dateFormat.formatMediumDate(_date),
              onTap: _selectDate,
            ),
            const SizedBox(height: 8),
            _EventDateTimeTile(
              icon: Icons.access_time_rounded,
              title: 'Starts',
              value: dateFormat.formatTimeOfDay(_startTime),
              onTap: () => _selectTime(isStart: true),
            ),
            const SizedBox(height: 8),
            _EventDateTimeTile(
              icon: Icons.schedule_rounded,
              title: 'Ends',
              value: dateFormat.formatTimeOfDay(_endTime),
              onTap: () => _selectTime(isStart: false),
            ),
            if (!widget.disableRecurrence) ...[
              const SizedBox(height: 20),
              DropdownButtonFormField<_RepeatFrequency>(
                initialValue: _repeatFrequency,
                decoration: const InputDecoration(
                  labelText: 'Repeat',
                  prefixIcon: Icon(Icons.repeat_rounded),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: _RepeatFrequency.never,
                    child: Text('Never'),
                  ),
                  DropdownMenuItem(
                    value: _RepeatFrequency.daily,
                    child: Text('Daily'),
                  ),
                  DropdownMenuItem(
                    value: _RepeatFrequency.weekly,
                    child: Text('Weekly'),
                  ),
                  DropdownMenuItem(
                    value: _RepeatFrequency.monthly,
                    child: Text('Monthly'),
                  ),
                ],
                onChanged: (frequency) {
                  if (frequency == null) {
                    return;
                  }
                  setState(() {
                    _repeatFrequency = frequency;
                    if (frequency == _RepeatFrequency.weekly &&
                        _selectedWeekdays.isEmpty) {
                      _selectedWeekdays.add(_date.weekday);
                    }
                    _recurrenceError = null;
                  });
                },
              ),
              if (_repeatFrequency == _RepeatFrequency.weekly) ...[
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 4,
                  children: _weekdays.map((weekday) {
                    final selected = _selectedWeekdays.contains(weekday.day);
                    return FilterChip(
                      label: Text(weekday.label),
                      selected: selected,
                      onSelected: (isSelected) {
                        setState(() {
                          if (isSelected) {
                            _selectedWeekdays.add(weekday.day);
                          } else {
                            _selectedWeekdays.remove(weekday.day);
                          }
                          _recurrenceError = null;
                        });
                      },
                    );
                  }).toList(),
                ),
                if (_recurrenceError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _recurrenceError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 8),
              if (_repeatUntil == null)
                TextButton.icon(
                  onPressed: _selectRepeatUntil,
                  icon: const Icon(Icons.event_outlined),
                  label: const Text('Add end date'),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _EventDateTimeTile(
                        icon: Icons.event_outlined,
                        title: 'Repeat until',
                        value: dateFormat.formatMediumDate(_repeatUntil!),
                        onTap: _selectRepeatUntil,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove repeat end date',
                      onPressed: () => setState(() => _repeatUntil = null),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
            ],
            if (_timeError != null) ...[
              const SizedBox(height: 8),
              Text(
                _timeError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _saveEvent,
              icon: const Icon(Icons.check_rounded),
              label: Text(isEditing ? 'Save changes' : 'Save event'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

enum _RepeatFrequency { never, daily, weekly, monthly }

class _EventDateTimeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _EventDateTimeTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color),
        title: Text(title),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF7B8491),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, size: 20),
          ],
        ),
      ),
    );
  }
}
