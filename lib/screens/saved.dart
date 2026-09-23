// Saved: bookmarked stories for revision, grouped by date.

import 'package:flutter/material.dart';

import '../store.dart';
import '../widgets/widgets.dart';

class SavedScreen extends StatefulWidget {
  final UserStore store;
  const SavedScreen({super.key, required this.store});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
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

  @override
  Widget build(BuildContext context) {
    final items = widget.store.bookmarks.values.toList()
      ..sort((a, b) => b.daySlug.compareTo(a.daySlug));
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bookmark_border,
                  size: 56, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'Nothing saved yet.\nTap the bookmark icon on any story to build your revision list.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.5, height: 1.6),
              ),
            ],
          ),
        ),
      );
    }
    String? lastDate;
    final children = <Widget>[];
    for (final s in items) {
      if (s.dateLabel != lastDate) {
        lastDate = s.dateLabel;
        children.add(SectionHeader(title: s.dateLabel));
      }
      children.add(StoryCard(
        story: s.story,
        dateLabel: s.dateLabel,
        daySlug: s.daySlug,
        store: widget.store,
      ));
    }
    children.add(const SizedBox(height: 24));
    return ListView(children: children);
  }
}
