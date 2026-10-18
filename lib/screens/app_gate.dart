import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/calendar_service.dart';
import '../services/family_service.dart';
import '../services/planner_service.dart';
import 'home_screen.dart';

class AppGate extends StatelessWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not check your sign-in status: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        final user = snapshot.data;
        if (user == null) {
          return const _SignInScreen();
        }
        return _FamilyGate(key: ValueKey(user.uid), user: user);
      },
    );
  }
}

class _SignInScreen extends StatefulWidget {
  const _SignInScreen();

  @override
  State<_SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<_SignInScreen> {
  bool _isSigningIn = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() {
      _isSigningIn = true;
      _error = null;
    });
    try {
      await FamilyService.instance.signInWithGoogle();
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Could not sign in: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _isSigningIn = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  'Family Calendar',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign in to access your family calendar and lists on all '
                  'your devices.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                ],
                FilledButton.icon(
                  onPressed: _isSigningIn ? null : _signIn,
                  icon: _isSigningIn
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login_rounded),
                  label: Text(
                    _isSigningIn ? 'Signing in...' : 'Sign in with Google',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FamilyGate extends StatefulWidget {
  final User user;

  const _FamilyGate({super.key, required this.user});

  @override
  State<_FamilyGate> createState() => _FamilyGateState();
}

class _FamilyGateState extends State<_FamilyGate> {
  bool _loading = true;
  bool _busy = false;
  bool _needsSetup = false;
  String? _error;
  final _familyNameController = TextEditingController(text: 'Our Family');
  final _inviteCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    unawaited(_restoreFamily());
  }

  @override
  void dispose() {
    _familyNameController.dispose();
    _inviteCodeController.dispose();
    unawaited(
      Future.wait([
        CalendarService.instance.disconnectFromFamily(),
        PlannerService.instance.disconnectFromFamily(),
      ]),
    );
    super.dispose();
  }

  Future<void> _restoreFamily() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final familyId = await FamilyService.instance.savedFamilyId(
        widget.user.uid,
      );
      if (familyId == null) {
        if (mounted) {
          setState(() {
            _needsSetup = true;
            _loading = false;
          });
        }
        return;
      }
      await FamilyService.instance.connectToFamily(familyId);
      if (mounted) {
        setState(() {
          _needsSetup = false;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = 'Could not connect to your family: $error';
          _loading = false;
          _needsSetup = false;
        });
      }
    }
  }

  Future<void> _createFamily() async {
    final uploadLocalData = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share this device’s existing data?'),
        content: const Text(
          'You can upload the events and list items already saved on this '
          'device to the new family calendar. Everyone who joins will be able '
          'to see them.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Start empty'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Upload data'),
          ),
        ],
      ),
    );
    if (uploadLocalData == null) {
      return;
    }
    await _runFamilyAction(() async {
      final id = await FamilyService.instance.createFamily(
        _familyNameController.text,
        widget.user.uid,
      );
      await FamilyService.instance.connectToFamily(
        id,
        uploadLocalData: uploadLocalData,
      );
      if (mounted) {
        setState(() => _needsSetup = false);
      }
    });
  }

  Future<void> _joinFamily() async {
    await _runFamilyAction(() async {
      final id = await FamilyService.instance.joinFamily(
        _inviteCodeController.text,
        widget.user.uid,
      );
      await FamilyService.instance.connectToFamily(id);
      if (mounted) {
        setState(() => _needsSetup = false);
      }
    });
  }

  Future<void> _runFamilyAction(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Could not set up family sync: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _chooseAnotherFamily() async {
    try {
      await FamilyService.instance.clearFamily(widget.user.uid);
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Could not clear the saved family: $error');
      }
      return;
    }
    if (mounted) {
      setState(() {
        _needsSetup = true;
        _error = null;
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await FamilyService.instance.signOut();
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Could not sign out: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const _LoadingScreen();
    }
    if (_needsSetup) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Set up family sync'),
          actions: [
            IconButton(
              tooltip: 'Sign out',
              onPressed: _signOut,
              icon: const Icon(Icons.logout_rounded),
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(24),
              children: [
                TextField(
                  controller: _familyNameController,
                  decoration: const InputDecoration(
                    labelText: 'Family name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _busy ? null : _createFamily,
                  child: const Text('Create a family calendar'),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('OR JOIN ONE'),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                ),
                TextField(
                  controller: _inviteCodeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Family invite code',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _busy ? null : _joinFamily,
                  child: const Text('Join a family calendar'),
                ),
                if (_busy) ...[
                  const SizedBox(height: 20),
                  const Center(child: CircularProgressIndicator()),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Family sync unavailable'),
          actions: [
            IconButton(
              tooltip: 'Sign out',
              onPressed: _signOut,
              icon: const Icon(Icons.logout_rounded),
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _chooseAnotherFamily,
                  child: const Text('Use a different family code'),
                ),
                TextButton(
                  onPressed: _restoreFamily,
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return const HomeScreen();
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
