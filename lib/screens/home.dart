// Home: today's digest — date header, streak, exam filter,
// category sections with story cards, rapid-fire preview, quiz CTA.

import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../store.dart';
import '../widgets/widgets.dart';
import 'quiz.dart';

class HomeScreen extends StatefulWidget {
  final UserStore store;
  final VoidCallback onOpenQuiz;
  final VoidCallback onOpenRevise;
  const HomeScreen(
      {super.key,
      required this.store,
      required this.onOpenQuiz,
      required this.onOpenRevise});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final day = await AffairsApi.instance.fetchLatest();
      await widget.store.markDaySeen(day.slug);
      await widget.store.markActiveDay();
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

  List<Story> _filtered(List<Story> stories) {
    final f = widget.store.examFilter;
    if (f == 'all') return stories;
    return stories.where((s) => s.matchesExam(f)).toList();
  }

  @override
  Widget build(BuildContext context) {
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
              const Icon(Icons.cloud_off, size: 52, color: Colors.grey),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                  onPressed: _load, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }
    final day = _day!;
    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _header(context, day)),
          SliverToBoxAdapter(
            child: ExamFilterChips(
              value: widget.store.examFilter,
              onChanged: (v) => widget.store.setExamFilter(v),
            ),
          ),
          ..._categorySlivers(day),
          SliverToBoxAdapter(child: _rapidFirePreview(context, day)),
          SliverToBoxAdapter(child: _quizCta(context, day)),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, DayDigest day) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2B1B4D), Color(0xFF4A154B), Color(0xFF7C2D12)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📰', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  day.date,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800),
                ),
              ),
              _streakPill(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${day.storyCount} stories · ${day.oneLiners.length} rapid-fire one-liners · ${day.quiz.length}-question quiz',
            style: const TextStyle(color: Color(0xFFF3E3C3), fontSize: 13),
          ),
          const SizedBox(height: 4),
          const Text(
            'Compiled from GKToday · Insights IAS · Drishti IAS · Testbook · AffairsCloud',
            style: TextStyle(color: Colors.white70, fontSize: 11.5),
          ),
        ],
      ),
    );
  }

  Widget _streakPill() {
    final s = widget.store.streak;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text('$s day${s == 1 ? '' : 's'}',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5)),
        ],
      ),
    );
  }

  List<Widget> _categorySlivers(DayDigest day) {
    final out = <Widget>[];
    for (final cat in day.categories) {
      final stories = _filtered(cat.stories);
      if (stories.isEmpty) continue;
      out.add(SliverToBoxAdapter(
          child: SectionHeader(title: _catIcon(cat.name, cat.stories))));
      out.add(SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) => StoryCard(
            story: stories[i],
            dateLabel: day.date,
            daySlug: day.slug,
            store: widget.store,
          ),
          childCount: stories.length,
        ),
      ));
    }
    return out;
  }

  String _catIcon(String name, List<Story> stories) {
    // Category names from the feed already read well; keep them as-is.
    return name;
  }

  Widget _rapidFirePreview(BuildContext context, DayDigest day) {
    if (day.oneLiners.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: '⚡ Rapid-fire revision',
          actionLabel: 'Revise all',
          onAction: widget.onOpenRevise,
        ),
        ...day.oneLiners.take(3).map(
              (l) => Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  dense: true,
                  leading: const Text('⚡'),
                  title: Text(l,
                      style: const TextStyle(
                          fontSize: 13.5, height: 1.45)),
                  onTap: widget.onOpenRevise,
                ),
              ),
            ),
      ],
    );
  }

  Widget _quizCta(BuildContext context, DayDigest day) {
    if (day.quiz.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 16, 12, 0),
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: kAccent,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) =>
                  QuizScreen(day: day, store: widget.store)));
        },
        icon: const Icon(Icons.quiz),
        label: Text('Take today\'s quiz · ${day.quiz.length} questions',
            style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 15)),
      ),
    );
  }
}
