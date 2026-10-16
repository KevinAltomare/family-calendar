import 'package:flutter/material.dart';

import '../models/calendar_event.dart';

class AddEventScreen extends StatefulWidget {
  final DateTime? initialDate;

  const AddEventScreen({super.key, this.initialDate});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  static const _familyMembers = ['Ethan', 'Micah', 'Eli', 'Mom', 'Dad'];

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  String? _selectedFamilyMember;
  DateTime _date = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  String? _timeError;

  @override
  void initState() {
    super.initState();
    final initialDate = widget.initialDate;
    if (initialDate != null) {
      _date = DateTime(initialDate.year, initialDate.month, initialDate.day);
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

    Navigator.pop(
      context,
      CalendarEvent(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        familyMember: _selectedFamilyMember,
        startTime: start,
        endTime: end,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = MaterialLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Add event')),
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
                hintText: 'e.g. Soccer practice',
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
              hint: const Text('Select a family member'),
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
              label: const Text('Save event'),
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
