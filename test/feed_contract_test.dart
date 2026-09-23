// Feed contract test: guarantees the app's models parse the exact
// JSON shapes published by tools/build_api.py in the
// current-affairs-exams GitHub repo. If the generator changes its
// output, this test fails before a broken build ships.

import 'dart:convert';

import 'package:current_affairs_exams/models.dart';
import 'package:flutter_test/flutter_test.dart';

const _sampleDaily = '''
{
  "slug": "2026-09-23",
  "date": "23 September 2026",
  "categories": [
    {
      "name": "Banking & Finance",
      "stories": [
        {
          "id": "2026-09-23-1",
          "title": "RBI's bond sales halve liquidity surplus",
          "body": "Surplus fell to Rs 4.92 trillion.",
          "tags": ["bank", "upsc", "high-yield"]
        },
        {
          "id": "2026-09-23-2",
          "title": "SEBI pushes banks into commodity derivatives",
          "body": "SEBI asked banks to participate.",
          "tags": ["bank"]
        }
      ]
    },
    {
      "name": "Defence",
      "stories": [
        {
          "id": "2026-09-23-3",
          "title": "Tarang Shakti exercise concludes",
          "body": "India's largest air combat exercise.",
          "tags": ["upsc", "defence"]
        }
      ]
    }
  ],
  "one_liners": [
    "RBI liquidity surplus: Rs 4.92 trillion.",
    "Tarang Shakti exercise concludes."
  ],
  "quiz": [
    {
      "id": "2026-09-23-q1",
      "question": "Liquidity surplus fell to what?",
      "options": [
        {"key": "a", "text": "Rs 8.5 trn"},
        {"key": "b", "text": "Rs 4.92 trn"},
        {"key": "c", "text": "Rs 11.16 trn"},
        {"key": "d", "text": "Rs 12.4 trn"}
      ],
      "answer": "b"
    }
  ]
}
''';

const _sampleIndexDay = '''
{
  "slug": "2026-09-23",
  "date": "23 September 2026",
  "story_count": 13,
  "one_liner_count": 15,
  "quiz_count": 10,
  "high_yield_count": 7,
  "categories": ["Banking & Finance", "Defence"],
  "top_stories": ["RBI's bond sales halve liquidity surplus"]
}
''';

void main() {
  test('DayDigest parses the GitHub daily-feed shape', () {
    final day = DayDigest.fromJson(
        json.decode(_sampleDaily) as Map<String, dynamic>);
    expect(day.slug, '2026-09-23');
    expect(day.date, '23 September 2026');
    expect(day.storyCount, 3);
    expect(day.categories.length, 2);
    expect(day.oneLiners.length, 2);
    expect(day.quiz.length, 1);

    final q = day.quiz.first;
    expect(q.question, 'Liquidity surplus fell to what?');
    expect(q.options.length, 4);
    expect(q.options[1].key, 'b');
    expect(q.options[1].text, 'Rs 4.92 trn');
    expect(q.answer, 'b');

    final s = day.categories.first.stories.first;
    expect(s.title, "RBI's bond sales halve liquidity surplus");
    expect(s.tags, containsAll(['bank', 'upsc', 'high-yield']));
  });

  test('DaySummary parses the GitHub index shape', () {
    final s = DaySummary.fromJson(
        json.decode(_sampleIndexDay) as Map<String, dynamic>);
    expect(s.slug, '2026-09-23');
    expect(s.storyCount, 13);
    expect(s.quizCount, 10);
    expect(s.highYieldCount, 7);
    expect(s.categories, contains('Defence'));
  });

  test('Story.matchesExam respects exam filters', () {
    final day = DayDigest.fromJson(
        json.decode(_sampleDaily) as Map<String, dynamic>);
    final bankOnly = day.allStories
        .where((s) => s.matchesExam('bank'))
        .toList();
    expect(bankOnly.length, 2);
    final hy = day.allStories
        .where((s) => s.matchesExam('high-yield'))
        .toList();
    expect(hy.length, 1);
    final upsc = day.allStories
        .where((s) => s.matchesExam('upsc'))
        .toList();
    expect(upsc.length, 2);
  });
}
