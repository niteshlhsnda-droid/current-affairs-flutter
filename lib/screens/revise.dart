// Revise: rapid-fire one-liners as flashcards.
// Tap to reveal the full line, then mark "Knew it" or "Repeat" —
// repeats loop back so weak points get drilled first.

import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../store.dart';
import '../widgets/widgets.dart';

class ReviseScreen extends StatefulWidget {
  final UserStore store;
  const ReviseScreen({super.key, required this.store});

  @override
  State<ReviseScreen> createState() => _ReviseScreenState();
}

class _ReviseScreenState extends State<ReviseScreen> {
  DayDigest? _day;
  String? _error;
  bool _loading = true;

  List<String> _queue = [];
  int _index = 0;
  bool _revealed = false;
  int _knew = 0;
  final List<String> _repeat = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final day = await AffairsApi.instance.fetchLatest();
      if (mounted) {
        setState(() {
          _day = day;
          _queue = List.of(day.oneLiners)..shuffle();
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

  void _mark(bool knew) {
    if (_revealed == false) {
      setState(() => _revealed = true);
      return;
    }
    if (knew) {
      _knew++;
    } else {
      _repeat.add(_queue[_index]);
    }
    if (_index + 1 >= _queue.length) {
      if (_repeat.isNotEmpty) {
        final again = List.of(_repeat)..shuffle();
        setState(() {
          _queue = again;
          _repeat.clear();
          _index = 0;
          _revealed = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Repeating the ${again.length} you missed — drill them! 💪'),
              duration: const Duration(seconds: 2)),
        );
      } else {
        widget.store.markActiveDay();
        setState(() => _index++);
      }
    } else {
      setState(() {
        _index++;
        _revealed = false;
      });
    }
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
    if (_index >= _queue.length) return _done(context);
    final total = _day!.oneLiners.length;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Text('Card ${_index + 1} of ${_queue.length}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13)),
                const Spacer(),
                Text('Knew: $_knew',
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
              value: _queue.isEmpty ? 0 : (_index + 1) / _queue.length,
              minHeight: 7,
              borderRadius: BorderRadius.circular(99),
              backgroundColor: Colors.grey.withValues(alpha: 0.25),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(kAccent),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () => setState(() => _revealed = true),
                child: Card(
                  elevation: 3,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('⚡',
                            style: TextStyle(fontSize: 34)),
                        const SizedBox(height: 16),
                        AnimatedSwitcher(
                          duration:
                              const Duration(milliseconds: 200),
                          child: _revealed
                              ? Text(
                                  _queue[_index],
                                  key: const ValueKey('full'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 17,
                                      height: 1.6,
                                      fontWeight: FontWeight.w600),
                                )
                              : Text(
                                  _firstHalf(_queue[_index]),
                                  key: const ValueKey('half'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 17, height: 1.6),
                                ),
                        ),
                        const SizedBox(height: 18),
                        if (!_revealed)
                          Text('Tap to reveal the answer',
                              style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12.5)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _mark(false),
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14)),
                    icon: const Icon(Icons.repeat),
                    label: const Text('Repeat'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _mark(true),
                    style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14)),
                    icon: const Icon(Icons.check),
                    label: const Text('Knew it'),
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('$total one-liners · ${_day!.date}',
                  style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  /// Hide the bolded fact at the end so the card works as a prompt.
  String _firstHalf(String line) {
    final idx = line.indexOf(':');
    if (idx > 8 && idx < line.length - 4) {
      return '${line.substring(0, idx + 1)} …?';
    }
    final words = line.split(' ');
    if (words.length > 6) {
      return '${words.take(words.length ~/ 2).join(' ')} …?';
    }
    return line;
  }

  Widget _done(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎯', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            const Text('Deck complete!',
                style:
                    TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('You knew $_knew of ${_day!.oneLiners.length} one-liners.',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 15, height: 1.5)),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                setState(() {
                  _queue = List.of(_day!.oneLiners)..shuffle();
                  _index = 0;
                  _revealed = false;
                  _knew = 0;
                  _repeat.clear();
                });
              },
              child: const Text('Revise again'),
            ),
          ],
        ),
      ),
    );
  }
}
