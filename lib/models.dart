// Data models for the Current Affairs exam-prep app.
// Mirror the JSON produced by tools/build_api.py in the
// niteshlhsnda-droid/current-affairs-exams repo.

const tagLabels = {
  'bank': '🏦 Bank',
  'upsc': '🎓 UPSC',
  'psu': '🏭 PSU',
  'high-yield': '⭐ High-yield',
};

class QuizOption {
  final String key;
  final String text;
  QuizOption({required this.key, required this.text});

  factory QuizOption.fromJson(Map<String, dynamic> j) =>
      QuizOption(key: j['key'] as String, text: j['text'] as String);

  Map<String, dynamic> toJson() => {'key': key, 'text': text};
}

class QuizQuestion {
  final String id;
  final String question;
  final List<QuizOption> options;
  final String answer;
  QuizQuestion(
      {required this.id,
      required this.question,
      required this.options,
      required this.answer});

  factory QuizQuestion.fromJson(Map<String, dynamic> j) => QuizQuestion(
        id: j['id'] as String,
        question: j['question'] as String,
        options: (j['options'] as List)
            .map((o) => QuizOption.fromJson(o as Map<String, dynamic>))
            .toList(),
        answer: j['answer'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'options': options.map((o) => o.toJson()).toList(),
        'answer': answer,
      };
}

class Story {
  final String id;
  final String title;
  final String body;
  final List<String> tags;
  Story(
      {required this.id,
      required this.title,
      required this.body,
      required this.tags});

  factory Story.fromJson(Map<String, dynamic> j) => Story(
        id: j['id'] as String,
        title: j['title'] as String,
        body: j['body'] as String,
        tags: (j['tags'] as List).map((t) => t as String).toList(),
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'title': title, 'body': body, 'tags': tags};

  bool matchesExam(String exam) {
    if (exam == 'all' || exam == 'high-yield') {
      return exam == 'all' ? true : tags.contains('high-yield');
    }
    return tags.contains(exam);
  }
}

class Category {
  final String name;
  final List<Story> stories;
  Category({required this.name, required this.stories});

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        name: j['name'] as String,
        stories: (j['stories'] as List)
            .map((s) => Story.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}

class DayDigest {
  final String slug;
  final String date;
  final List<Category> categories;
  final List<String> oneLiners;
  final List<QuizQuestion> quiz;

  DayDigest(
      {required this.slug,
      required this.date,
      required this.categories,
      required this.oneLiners,
      required this.quiz});

  factory DayDigest.fromJson(Map<String, dynamic> j) => DayDigest(
        slug: j['slug'] as String,
        date: j['date'] as String,
        categories: (j['categories'] as List)
            .map((c) => Category.fromJson(c as Map<String, dynamic>))
            .toList(),
        oneLiners:
            (j['one_liners'] as List).map((s) => s as String).toList(),
        quiz: (j['quiz'] as List)
            .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
            .toList(),
      );

  List<Story> get allStories =>
      categories.expand((c) => c.stories).toList();

  int get storyCount => allStories.length;
}

class DaySummary {
  final String slug;
  final String date;
  final int storyCount;
  final int quizCount;
  final int highYieldCount;
  final List<String> categories;

  DaySummary(
      {required this.slug,
      required this.date,
      required this.storyCount,
      required this.quizCount,
      required this.highYieldCount,
      required this.categories});

  factory DaySummary.fromJson(Map<String, dynamic> j) => DaySummary(
        slug: j['slug'] as String,
        date: j['date'] as String,
        storyCount: (j['story_count'] as num).toInt(),
        quizCount: (j['quiz_count'] as num).toInt(),
        highYieldCount: (j['high_yield_count'] as num).toInt(),
        categories:
            (j['categories'] as List).map((c) => c as String).toList(),
      );
}
