// Day detail: full digest for any published date —
// categories, rapid-fire one-liners and the quiz entry point.

import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../store.dart';
import '../widgets/widgets.dart';
import 'quiz.dart';

class DayScreen extends StatefulWidget {
  final String slug;
  final String dateLabel;
  final UserStore store;
  const DayScreen(
      {super.key,
      required this.slug,
      required this.dateLabel,
      required this.store});

  @override
  State<DayScreen> createState() => _DayScreenState();
}

class _DayScreenState extends State<DayScreen> {
  DayDigest? _day;
  String? _error;
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
      final day = await AffairsApi.instance.fetchDay(widget.slug);
      await widget.store.markDaySeen(day.slug);
      if (mounted) {
        setState(() {
        _day = day;
        _loading = false;
      });
      }
    } on FeedException catch (e) {
      if (mounted) {
        setState(() {
        _error = e.message;
        _loading = false;
      });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.dateLabel)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                            onPressed: () {
                              setState(() {
                                _loading = true;
                                _error = null;
                              });
                              _load();
                            },
                            child: const Text('Try again')),
                      ],
                    ),
                  ),
                )
              : _body(_day!),
    );
  }

  Widget _body(DayDigest day) {
    final filter = widget.store.examFilter;
    final children = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Text(
          '${day.storyCount} stories · ${day.oneLiners.length} one-liners · ${day.quiz.length} quiz questions',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        ),
      ),
      const SizedBox(height: 8),
      ExamFilterChips(
          value: filter,
          onChanged: (v) => widget.store.setExamFilter(v)),
    ];
    for (final cat in day.categories) {
      final stories = filter == 'all'
          ? cat.stories
          : cat.stories.where((s) => s.matchesExam(filter)).toList();
      if (stories.isEmpty) continue;
      children.add(SectionHeader(title: cat.name));
      for (final s in stories) {
        children.add(StoryCard(
            story: s,
            dateLabel: day.date,
            daySlug: day.slug,
            store: widget.store));
      }
    }
    if (day.oneLiners.isNotEmpty) {
      children.add(const SectionHeader(title: '⚡ Rapid-fire one-liners'));
      for (final l in day.oneLiners) {
        children.add(Card(
          margin:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
              dense: true,
              leading: const Text('⚡'),
              title: Text(l,
                  style:
                      const TextStyle(fontSize: 13.5, height: 1.45))),
        ));
      }
    }
    if (day.quiz.isNotEmpty) {
      children.add(Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: kAccent,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) =>
                  QuizScreen(day: day, store: widget.store))),
          icon: const Icon(Icons.quiz),
          label: Text('Take the quiz · ${day.quiz.length} questions',
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 15)),
        ),
      ));
    }
    children.add(const SizedBox(height: 28));
    return ListView(children: children);
  }
}
