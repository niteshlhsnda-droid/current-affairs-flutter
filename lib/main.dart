// Current Affairs for Exams — Flutter app.
// Syncs daily digests from the GitHub Pages JSON feed, works offline,
// quizzes, rapid-fire revision flashcards, bookmarks, streaks.

import 'package:flutter/material.dart';

import 'notify.dart';
import 'screens/archive.dart';
import 'screens/home.dart';
import 'screens/onboarding.dart';
import 'screens/quiz_hub.dart';
import 'screens/revise.dart';
import 'screens/saved.dart';
import 'screens/settings.dart';
import 'store.dart';
import 'widgets/widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = UserStore();
  await store.load();
  if (store.reminder) {
    try {
      await ReminderService.instance.scheduleDaily(store.reminderMinutes);
    } catch (_) {}
  }
  runApp(AffairsApp(store: store));
}

class AffairsApp extends StatefulWidget {
  final UserStore store;
  const AffairsApp({super.key, required this.store});

  @override
  State<AffairsApp> createState() => _AffairsAppState();
}

class _AffairsAppState extends State<AffairsApp> {
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

  ThemeMode get _themeMode {
    switch (widget.store.themeMode) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
          seedColor: kAccent, brightness: Brightness.dark),
      scaffoldBackgroundColor: const Color(0xFF0D1424),
      cardColor: const Color(0xFF182238),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0D1424),
        foregroundColor: Colors.white,
      ),
    );
    final light = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme:
          ColorScheme.fromSeed(seedColor: const Color(0xFFB97A0A)),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF5A524),
        foregroundColor: Colors.black,
      ),
    );
    return MaterialApp(
      title: 'Current Affairs for Exams',
      debugShowCheckedModeBanner: false,
      theme: light,
      darkTheme: dark,
      themeMode: _themeMode,
      home: widget.store.onboarded
          ? HomeShell(store: widget.store)
          : OnboardingScreen(store: widget.store),
    );
  }
}

class HomeShell extends StatefulWidget {
  final UserStore store;
  const HomeShell({super.key, required this.store});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  void _goQuiz() => setState(() => _tab = 1);
  void _goRevise() => setState(() => _tab = 2);

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
          store: widget.store,
          onOpenQuiz: _goQuiz,
          onOpenRevise: _goRevise),
      QuizHubScreen(store: widget.store),
      ReviseScreen(store: widget.store),
      ArchiveScreen(store: widget.store),
      SavedScreen(store: widget.store),
    ];
    const titles = [
      'Today\'s Current Affairs',
      'Quiz',
      'Rapid-fire Revision',
      'Archive',
      'Saved'
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_tab]),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('Settings')),
                    body: SettingsScreen(store: widget.store)))),
          ),
        ],
      ),
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.today), label: 'Today'),
          NavigationDestination(
              icon: Icon(Icons.quiz), label: 'Quiz'),
          NavigationDestination(
              icon: Icon(Icons.bolt), label: 'Revise'),
          NavigationDestination(
              icon: Icon(Icons.archive), label: 'Archive'),
          NavigationDestination(
              icon: Icon(Icons.bookmark), label: 'Saved'),
        ],
      ),
    );
  }
}
