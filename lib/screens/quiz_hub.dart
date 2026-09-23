// Quiz hub tab: today's quiz card plus your attempt history.

import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../store.dart';
import '../widgets/widgets.dart';
import 'quiz.dart';

class QuizHubScreen extends StatefulWidget {
  final UserStore store;
  const QuizHubScreen({super.key, required this.store});

  @override
  State<QuizHubScreen> createState() => _QuizHubScreenState();
}

class _QuizHubScreenState extends State<QuizHubScreen> {
  DayDigest? _day;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
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

  Future<void> _load() async {
    try {
      final day = await AffairsApi.instance.fetchLatest();
      if (mounted) {
        setState(() {
        _day = day;
        _loading = false;
      });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final attempts = widget.store.attempts.reversed.toList();
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const SectionHeader(title: '🧠 Daily quiz'),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_day != null && _day!.quiz.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_day!.date,
                        style: const TextStyle(
                            color: kAccent,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                    const SizedBox(height: 6),
                    Text(
                        '${_day!.quiz.length} questions from today\'s stories',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    const Text(
                        'Instant feedback on every answer. Your score builds your average.',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () =>
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => QuizScreen(
                                    day: _day!,
                                    store: widget.store))),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start quiz'),
                        style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 13)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SectionHeader(title: '📊 Your history'),
        if (attempts.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
                'No attempts yet — your scores will appear here.',
                style: TextStyle(color: Colors.grey)),
          )
        else
          ...attempts.take(20).map((a) {
            final pct = a.total == 0
                ? 0
                : (a.score / a.total * 100).round();
            return Card(
              margin: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: pct >= 60
                      ? Colors.green.withValues(alpha: 0.15)
                      : Colors.orange.withValues(alpha: 0.15),
                  child: Text('$pct%',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: pct >= 60
                              ? Colors.green
                              : Colors.orange)),
                ),
                title: Text('${a.score}/${a.total} correct',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600)),
                subtitle: Text(a.daySlug,
                    style: const TextStyle(fontSize: 12)),
                trailing: Text(
                  _ago(a.timestamp),
                  style: const TextStyle(
                      fontSize: 12, color: Colors.grey),
                ),
              ),
            );
          }),
      ],
    );
  }

  String _ago(int ts) {
    final d =
        DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts));
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}
