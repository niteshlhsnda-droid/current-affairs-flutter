// Quiz runner: one question at a time, instant right/wrong feedback,
// progress bar, final score with a verdict, attempt saved to history.

import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../widgets/widgets.dart';

class QuizScreen extends StatefulWidget {
  final DayDigest day;
  final UserStore store;
  const QuizScreen({super.key, required this.day, required this.store});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _index = 0;
  String? _picked;
  int _score = 0;
  bool _finished = false;

  QuizQuestion get _q => widget.day.quiz[_index];

  void _answer(String key) {
    if (_picked != null) return;
    setState(() {
      _picked = key;
      if (key == _q.answer) _score++;
    });
  }

  void _next() {
    if (_index + 1 >= widget.day.quiz.length) {
      setState(() => _finished = true);
      widget.store.recordQuizAttempt(
          widget.day.slug, _score, widget.day.quiz.length);
    } else {
      setState(() {
        _index++;
        _picked = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz · ${widget.day.date}'),
      ),
      body: _finished ? _result(context) : _question(context),
    );
  }

  Widget _question(BuildContext context) {
    final total = widget.day.quiz.length;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Text('Question ${_index + 1} of $total',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13)),
                const Spacer(),
                Text('Score: $_score',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: kAccent)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: LinearProgressIndicator(
              value: (_index + 1) / total,
              minHeight: 7,
              borderRadius: BorderRadius.circular(99),
              backgroundColor:
                  Colors.grey.withValues(alpha: 0.25),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(kAccent),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(_q.question,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.45)),
                  const SizedBox(height: 18),
                  ..._q.options.map((o) => _optionTile(o)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: _picked == null ? null : _next,
              style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 14)),
              child: Text(_index + 1 >= total
                  ? 'See result'
                  : 'Next question'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionTile(QuizOption o) {
    final picked = _picked != null;
    final isAnswer = o.key == _q.answer;
    final isPicked = o.key == _picked;
    Color? bg;
    Color? border;
    if (picked && isAnswer) {
      bg = Colors.green.withValues(alpha: 0.16);
      border = Colors.green;
    } else if (picked && isPicked) {
      bg = Colors.red.withValues(alpha: 0.14);
      border = Colors.red;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: picked ? null : () => _answer(o.key),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bg ??
                Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: border ??
                    Theme.of(context)
                        .dividerColor
                        .withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (border ?? Colors.grey)
                      .withValues(alpha: 0.15),
                ),
                child: Text(o.key.toUpperCase(),
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: border ?? Colors.grey)),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(o.text,
                      style: const TextStyle(
                          fontSize: 14.5, height: 1.4))),
              if (picked && isAnswer)
                const Icon(Icons.check_circle,
                    color: Colors.green),
              if (picked && isPicked && !isAnswer)
                const Icon(Icons.cancel, color: Colors.red),
            ],
          ),
        ),
      ),
    );
  }

  Widget _result(BuildContext context) {
    final total = widget.day.quiz.length;
    final pct = total == 0 ? 0 : (_score / total * 100).round();
    final String verdict;
    final String emoji;
    if (pct >= 80) {
      verdict = 'Outstanding! Exam-ready.';
      emoji = '🏆';
    } else if (pct >= 60) {
      verdict = 'Good — revise the ones you missed.';
      emoji = '💪';
    } else if (pct >= 40) {
      verdict = 'Getting there. Hit rapid-fire revision.';
      emoji = '📚';
    } else {
      verdict = 'Read today\'s stories once more, then retry.';
      emoji = '🔁';
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            Text('$_score / $total',
                style: const TextStyle(
                    fontSize: 44, fontWeight: FontWeight.w900)),
            Text('$pct%',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: kAccent)),
            const SizedBox(height: 10),
            Text(verdict,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, height: 1.5)),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back to today\'s digest'),
            ),
          ],
        ),
      ),
    );
  }
}
