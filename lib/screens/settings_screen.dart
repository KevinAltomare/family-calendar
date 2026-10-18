import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../firebase_configuration.dart';
import '../services/calendar_service.dart';
import '../services/family_service.dart';
import '../services/planner_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _eventRemindersEnabled = true;
  int _weekStartsOn = DateTime.sunday;

  Future<void> _signOut() async {
    try {
      await FamilyService.instance.signOut();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not sign out: $error')));
      }
    }
  }

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
                    DropdownMenuItem(
                      value: DateTime.sunday,
                      child: Text('Sunday'),
                    ),
                    DropdownMenuItem(
                      value: DateTime.monday,
                      child: Text('Monday'),
                    ),
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
          if (FirebaseConfiguration.isConfigured) ...[
            const SizedBox(height: 16),
            _SettingsSection(
              title: 'FAMILY SYNC',
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  leading: const _SettingsIcon(
                    icon: Icons.family_restroom_rounded,
                  ),
                  title: Text(
                    FamilyService.instance.familyName ?? 'Family calendar',
                  ),
                  subtitle: const Text('Shared events and lists'),
                ),
                if (FamilyService.instance.inviteCode case final code?) ...[
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    leading: const _SettingsIcon(
                      icon: Icons.group_add_outlined,
                    ),
                    title: const Text('Invite code'),
                    subtitle: SelectableText(code),
                    trailing: IconButton(
                      tooltip: 'Copy invite code',
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: code));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Invite code copied')),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy_rounded),
                    ),
                  ),
                ],
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  leading: const _SettingsIcon(icon: Icons.sync_rounded),
                  title: const Text('Sync status'),
                  subtitle: Text(
                    _syncErrorText ??
                        'Changes sync automatically when connected.',
                  ),
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  leading: const _SettingsIcon(icon: Icons.logout_rounded),
                  title: const Text('Sign out'),
                  onTap: _signOut,
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          const _SettingsSection(
            title: 'ABOUT',
            children: [
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
                leading: _SettingsIcon(icon: Icons.info_outline_rounded),
                title: Text('Altomare Hub'),
                subtitle: Text('Version 0.1.0'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String? get _syncErrorText {
    final error =
        CalendarService.instance.syncError ?? PlannerService.instance.syncError;
    return error == null ? null : 'Sync error: $error';
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

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
          child: Column(children: children),
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
      child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
    );
  }
}
