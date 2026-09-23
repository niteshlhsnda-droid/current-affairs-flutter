// Local user data: bookmarks, quiz history, study streak and settings.
// Backed by SharedPreferences; no account, no server, fully private.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Minimal observable to avoid pulling in the provider package.
class ChangeNotifierLite {
  final List<void Function()> _ls = [];
  void addListener(void Function() fn) => _ls.add(fn);
  void removeListener(void Function() fn) => _ls.remove(fn);
  void notify() {
    for (final fn in List.of(_ls)) {
      fn();
    }
  }
}

class SavedStory {
  final Story story;
  final String dateLabel;
  final String daySlug;
  SavedStory(
      {required this.story, required this.dateLabel, required this.daySlug});

  Map<String, dynamic> toJson() => {
        'story': story.toJson(),
        'dateLabel': dateLabel,
        'daySlug': daySlug,
      };

  factory SavedStory.fromJson(Map<String, dynamic> j) => SavedStory(
        story: Story.fromJson(j['story'] as Map<String, dynamic>),
        dateLabel: j['dateLabel'] as String,
        daySlug: j['daySlug'] as String,
      );
}

class QuizAttempt {
  final String daySlug;
  final int score;
  final int total;
  final int timestamp;
  QuizAttempt(
      {required this.daySlug,
      required this.score,
      required this.total,
      required this.timestamp});

  Map<String, dynamic> toJson() => {
        'daySlug': daySlug,
        'score': score,
        'total': total,
        'timestamp': timestamp,
      };

  factory QuizAttempt.fromJson(Map<String, dynamic> j) => QuizAttempt(
        daySlug: j['daySlug'] as String,
        score: (j['score'] as num).toInt(),
        total: (j['total'] as num).toInt(),
        timestamp: (j['timestamp'] as num).toInt(),
      );
}

class UserStore extends ChangeNotifierLite {
  static const _kBookmarks = 'bookmarks_v1';
  static const _kAttempts = 'quiz_attempts_v1';
  static const _kStreak = 'streak_v1';
  static const _kStreakDate = 'streak_date_v1';
  static const _kExam = 'exam_filter_v1';
  static const _kTheme = 'theme_mode_v1'; // system|dark|light
  static const _kReminder = 'reminder_v1';
  static const _kReminderTime = 'reminder_time_v1';
  static const _kSeenDays = 'seen_days_v1';
  static const _kOnboarded = 'onboarded_v1';

  final Map<String, SavedStory> bookmarks = {};
  final List<QuizAttempt> attempts = [];
  int streak = 0;
  bool onboarded = false;
  String examFilter = 'all'; // all|bank|upsc|psu|high-yield
  String themeMode = 'system';
  bool reminder = true;
  int reminderMinutes = 7 * 60 + 41; // 07:41
  final Set<String> seenDays = {};

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    for (final raw in p.getStringList(_kBookmarks) ?? <String>[]) {
      try {
        final s =
            SavedStory.fromJson(json.decode(raw) as Map<String, dynamic>);
        bookmarks[s.story.id] = s;
      } catch (_) {}
    }
    for (final raw in p.getStringList(_kAttempts) ?? <String>[]) {
      try {
        attempts
            .add(QuizAttempt.fromJson(json.decode(raw) as Map<String, dynamic>));
      } catch (_) {}
    }
    streak = p.getInt(_kStreak) ?? 0;
    onboarded = p.getBool(_kOnboarded) ?? false;
    examFilter = p.getString(_kExam) ?? 'all';
    themeMode = p.getString(_kTheme) ?? 'system';
    reminder = p.getBool(_kReminder) ?? true;
    reminderMinutes = p.getInt(_kReminderTime) ?? (7 * 60 + 41);
    seenDays.addAll(p.getStringList(_kSeenDays) ?? <String>[]);
    _rollStreakIfNeeded(p);
    notify();
  }

  Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  void _rollStreakIfNeeded(SharedPreferences p) {
    final last = p.getString(_kStreakDate);
    final today = _dayKey(DateTime.now());
    if (last == null || last == today) return;
    final yesterday = _dayKey(DateTime.now().subtract(const Duration(days: 1)));
    if (last != yesterday) {
      streak = 0;
      p.setInt(_kStreak, 0);
    }
  }

  static String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  /// Call when the user does something study-like (opening the app counts).
  Future<void> markActiveDay() async {
    final p = await _prefs();
    final today = _dayKey(DateTime.now());
    final last = p.getString(_kStreakDate);
    if (last == today) return;
    final yesterday = _dayKey(DateTime.now().subtract(const Duration(days: 1)));
    streak = (last == yesterday) ? streak + 1 : 1;
    await p.setString(_kStreakDate, today);
    await p.setInt(_kStreak, streak);
    notify();
  }

  Future<void> markDaySeen(String slug) async {
    if (seenDays.contains(slug)) return;
    seenDays.add(slug);
    final p = await _prefs();
    await p.setStringList(_kSeenDays, seenDays.toList());
  }

  bool isBookmarked(String storyId) => bookmarks.containsKey(storyId);

  Future<void> toggleBookmark(
      Story story, String dateLabel, String daySlug) async {
    if (bookmarks.containsKey(story.id)) {
      bookmarks.remove(story.id);
    } else {
      bookmarks[story.id] =
          SavedStory(story: story, dateLabel: dateLabel, daySlug: daySlug);
    }
    final p = await _prefs();
    await p.setStringList(_kBookmarks,
        bookmarks.values.map((s) => json.encode(s.toJson())).toList());
    notify();
  }

  Future<void> recordQuizAttempt(String daySlug, int score, int total) async {
    attempts.add(QuizAttempt(
        daySlug: daySlug,
        score: score,
        total: total,
        timestamp: DateTime.now().millisecondsSinceEpoch));
    final p = await _prefs();
    await p.setStringList(
        _kAttempts, attempts.map((a) => json.encode(a.toJson())).toList());
    await markActiveDay();
  }

  double get averageScore {
    if (attempts.isEmpty) return 0;
    var s = 0, t = 0;
    for (final a in attempts) {
      s += a.score;
      t += a.total;
    }
    return t == 0 ? 0 : s / t;
  }

  Future<void> setOnboarded(bool v) async {
    onboarded = v;
    (await _prefs()).setBool(_kOnboarded, v);
    notify();
  }

  Future<void> setExamFilter(String v) async {
    examFilter = v;
    (await _prefs()).setString(_kExam, v);
    notify();
  }

  Future<void> setThemeMode(String v) async {
    themeMode = v;
    (await _prefs()).setString(_kTheme, v);
    notify();
  }

  Future<void> setReminder(bool v) async {
    reminder = v;
    (await _prefs()).setBool(_kReminder, v);
    notify();
  }

  Future<void> setReminderTime(int minutes) async {
    reminderMinutes = minutes;
    (await _prefs()).setInt(_kReminderTime, minutes);
    notify();
  }
}
