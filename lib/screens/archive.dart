// Archive: every published digest, newest first, with story-count
// metadata — plus full-text search across all cached days.

import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../store.dart';
import 'day.dart';

class ArchiveScreen extends StatefulWidget {
  final UserStore store;
  const ArchiveScreen({super.key, required this.store});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  List<DaySummary>? _days;
  String? _error;
  bool _loading = true;
  List<_Hit> _hits = [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final days = await AffairsApi.instance.fetchIndex();
      if (mounted) {
        setState(() {
        _days = days;
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

  Future<void> _search(String q) async {
    setState(() {
      _searching = q.trim().length >= 2;
      _hits = [];
    });
    if (!_searching) return;
    final needle = q.trim().toLowerCase();
    final hits = <_Hit>[];
    // Search the most recent 30 cached-or-fetchable days.
    for (final d in (_days ?? []).take(30)) {
      DayDigest day;
      try {
        day = await AffairsApi.instance.fetchDay(d.slug);
      } catch (_) {
        continue;
      }
      for (final s in day.allStories) {
        if (s.title.toLowerCase().contains(needle) ||
            s.body.toLowerCase().contains(needle)) {
          hits.add(_Hit(day: d, story: s));
          if (hits.length >= 40) break;
        }
      }
      if (hits.length >= 40) break;
      if (mounted) setState(() => _hits = List.of(hits));
    }
    if (mounted) setState(() => _hits = hits);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search stories, e.g. RBI, Tarang Shakti…',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14)),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: _search,
          ),
        ),
        Expanded(child: _body()),
      ],
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
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
      );
    }
    if (_searching) {
      if (_hits.isEmpty) {
        return const Center(
            child: Text('No matches in recent digests.'));
      }
      return ListView.builder(
        itemCount: _hits.length,
        itemBuilder: (context, i) {
          final h = _hits[i];
          return Card(
            margin:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            child: ListTile(
              title: Text(h.story.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Text(h.day.date,
                  style: const TextStyle(fontSize: 12)),
              trailing:
                  const Icon(Icons.arrow_forward_ios, size: 15),
              onTap: () => _openDay(h.day),
            ),
          );
        },
      );
    }
    final days = _days!;
    return ListView.builder(
      itemCount: days.length,
      itemBuilder: (context, i) {
        final d = days[i];
        final seen = widget.store.seenDays.contains(d.slug);
        return Card(
          margin:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          child: ListTile(
            leading: Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: seen
                    ? Colors.grey.withValues(alpha: 0.15)
                    : const Color(0xFFF5A524)
                        .withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('📰',
                  style: TextStyle(
                      fontSize: 20,
                      color: seen ? Colors.grey : null)),
            ),
            title: Text(d.date,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: seen ? Colors.grey : null)),
            subtitle: Text(
                '${d.storyCount} stories · ${d.quizCount} quiz · ⭐ ${d.highYieldCount} high-yield',
                style: const TextStyle(fontSize: 12.5)),
            trailing: seen
                ? null
                : Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5A524),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Text('NEW',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.black)),
                  ),
            onTap: () => _openDay(d),
          ),
        );
      },
    );
  }

  void _openDay(DaySummary d) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => DayScreen(
            slug: d.slug,
            dateLabel: d.date,
            store: widget.store)));
  }
}

class _Hit {
  final DaySummary day;
  final Story story;
  _Hit({required this.day, required this.story});
}
