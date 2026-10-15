import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _eventRemindersEnabled = true;
  int _weekStartsOn = DateTime.sunday;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _SettingsSection(
            title: 'CALENDAR',
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: const _SettingsIcon(icon: Icons.view_week_outlined),
                title: const Text('Week starts on'),
                subtitle: const Text('Choose the first day of your week'),
                trailing: DropdownButton<int>(
                  value: _weekStartsOn,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: DateTime.sunday, child: Text('Sunday')),
                    DropdownMenuItem(value: DateTime.monday, child: Text('Monday')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _weekStartsOn = value);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: 'NOTIFICATIONS',
            children: [
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                secondary: const _SettingsIcon(
                  icon: Icons.notifications_none_rounded,
                ),
                title: const Text('Event reminders'),
                subtitle: const Text('Get a reminder before an event'),
                value: _eventRemindersEnabled,
                onChanged: (enabled) {
                  setState(() => _eventRemindersEnabled = enabled);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _SettingsSection(
            title: 'ABOUT',
            children: [
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
                leading: _SettingsIcon(icon: Icons.info_outline_rounded),
                title: Text('Calendar App'),
                subtitle: Text('Version 0.1.0'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          color: Colors.white,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  final IconData icon;

  const _SettingsIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
        size: 20,
      ),
    );
  }
}