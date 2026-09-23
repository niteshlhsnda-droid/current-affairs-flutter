// Settings: exam target, theme, daily reminder, stats and about.

import 'package:flutter/material.dart';

import '../notify.dart';
import '../store.dart';

class SettingsScreen extends StatefulWidget {
  final UserStore store;
  const SettingsScreen({super.key, required this.store});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onStore);
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStore);
    super.dispose();
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
          hour: widget.store.reminderMinutes ~/ 60,
          minute: widget.store.reminderMinutes % 60),
    );
    if (t != null) {
      await widget.store.setReminderTime(t.hour * 60 + t.minute);
      if (widget.store.reminder) {
        await ReminderService.instance
            .scheduleDaily(widget.store.reminderMinutes);
      }
    }
  }

  String _fmtTime(int minutes) {
    final h = minutes ~/ 60, m = minutes % 60;
    final hh = h % 12 == 0 ? 12 : h % 12;
    return '$hh:${m.toString().padLeft(2, '0')} ${h < 12 ? 'AM' : 'PM'}';
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final attempts = store.attempts.length;
    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        const SizedBox(height: 8),
        _group('Study', [
          ListTile(
            leading: const Icon(Icons.school),
            title: const Text('Exam target'),
            subtitle: Text(_examLabel(store.examFilter)),
            trailing: DropdownButton<String>(
              value: store.examFilter,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(
                    value: 'all', child: Text('All exams')),
                DropdownMenuItem(
                    value: 'bank', child: Text('🏦 Bank')),
                DropdownMenuItem(
                    value: 'upsc', child: Text('🎓 UPSC')),
                DropdownMenuItem(
                    value: 'psu', child: Text('🏭 PSU')),
              ],
              onChanged: (v) {
                if (v != null) store.setExamFilter(v);
              },
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text('Daily reminder'),
            subtitle: Text(
                'New digest alert at ${_fmtTime(store.reminderMinutes)}'),
            value: store.reminder,
            onChanged: (v) async {
              await store.setReminder(v);
              if (v) {
                await ReminderService.instance
                    .scheduleDaily(store.reminderMinutes);
              } else {
                await ReminderService.instance.cancel();
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('Reminder time'),
            trailing: Text(_fmtTime(store.reminderMinutes),
                style: const TextStyle(fontWeight: FontWeight.w700)),
            onTap: _pickTime,
          ),
        ]),
        _group('Appearance', [
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('Theme'),
            trailing: DropdownButton<String>(
              value: store.themeMode,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(
                    value: 'system', child: Text('System')),
                DropdownMenuItem(
                    value: 'dark', child: Text('Dark')),
                DropdownMenuItem(
                    value: 'light', child: Text('Light')),
              ],
              onChanged: (v) {
                if (v != null) store.setThemeMode(v);
              },
            ),
          ),
        ]),
        _group('Your progress', [
          ListTile(
            leading: const Icon(Icons.local_fire_department),
            title: const Text('Study streak'),
            trailing: Text('${store.streak} day${store.streak == 1 ? '' : 's'}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          ListTile(
            leading: const Icon(Icons.quiz),
            title: const Text('Quizzes taken'),
            trailing: Text('$attempts',
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          ListTile(
            leading: const Icon(Icons.show_chart),
            title: const Text('Average quiz score'),
            trailing: Text(
                attempts == 0
                    ? '—'
                    : '${(store.averageScore * 100).round()}%',
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          ListTile(
            leading: const Icon(Icons.bookmark),
            title: const Text('Saved stories'),
            trailing: Text('${store.bookmarks.length}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ]),
        _group('About', [
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Current Affairs for Exams'),
            subtitle: Text(
              'Daily exam-ready digests for Bank • UPSC • PSU aspirants.\n'
              'Content syncs automatically from the GitHub repository — '
              'fresh every morning and evening.\n\n'
              'Compiled from GKToday, Insights IAS, Drishti IAS, '
              'Testbook and AffairsCloud. No account needed; '
              'your data never leaves this phone.',
              style: TextStyle(height: 1.55),
            ),
            isThreeLine: false,
          ),
          const ListTile(
            leading: Icon(Icons.cloud),
            title: Text('Data source'),
            subtitle: Text(
                'niteshlhsnda-droid.github.io/current-affairs-exams'),
          ),
        ]),
      ],
    );
  }

  String _examLabel(String v) {
    switch (v) {
      case 'bank':
        return '🏦 Bank exams';
      case 'upsc':
        return '🎓 UPSC';
      case 'psu':
        return '🏭 PSU';
      case 'high-yield':
        return '⭐ High-yield only';
      default:
        return 'All exams';
    }
  }

  Widget _group(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 2),
          child: Text(title,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: Colors.grey.shade500)),
        ),
        Card(
          margin:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(children: children),
        ),
      ],
    );
  }
}
