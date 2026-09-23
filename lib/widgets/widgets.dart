// Shared UI: story cards, tag chips, section headers.

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models.dart';
import '../store.dart';

const kAccent = Color(0xFFF5A524);
const kBank = Color(0xFF0EA5E9);
const kUpsc = Color(0xFF8B5CF6);
const kPsu = Color(0xFF10B981);
const kHot = Color(0xFFF05252);

Color tagColor(String tag) {
  switch (tag) {
    case 'bank':
      return kBank;
    case 'upsc':
      return kUpsc;
    case 'psu':
      return kPsu;
    case 'high-yield':
      return kHot;
    default:
      return Colors.grey;
  }
}

class TagChip extends StatelessWidget {
  final String tag;
  const TagChip({super.key, required this.tag});

  @override
  Widget build(BuildContext context) {
    final c = tagColor(tag);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withValues(alpha: 0.4)),
      ),
      child: Text(
        tagLabels[tag] ?? tag,
        style: TextStyle(
            color: c, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class StoryCard extends StatelessWidget {
  final Story story;
  final String dateLabel;
  final String daySlug;
  final UserStore store;
  final bool showBody;

  const StoryCard({
    super.key,
    required this.story,
    required this.dateLabel,
    required this.daySlug,
    required this.store,
    this.showBody = true,
  });

  void _openDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StorySheet(
          story: story,
          dateLabel: dateLabel,
          daySlug: daySlug,
          store: store),
    );
  }

  @override
  Widget build(BuildContext context) {
    final saved = store.isBookmarked(story.id);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      story.title,
                      style: const TextStyle(
                          fontSize: 15.5, fontWeight: FontWeight.w700, height: 1.35),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    saved ? Icons.bookmark : Icons.bookmark_border,
                    size: 20,
                    color: saved ? kAccent : Colors.grey,
                  ),
                ],
              ),
              if (showBody) ...[
                const SizedBox(height: 6),
                Text(
                  story.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 13.5,
                      height: 1.5,
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withValues(alpha: 0.78)),
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: story.tags.map((t) => TagChip(tag: t)).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StorySheet extends StatefulWidget {
  final Story story;
  final String dateLabel;
  final String daySlug;
  final UserStore store;
  const StorySheet(
      {super.key,
      required this.story,
      required this.dateLabel,
      required this.daySlug,
      required this.store});

  @override
  State<StorySheet> createState() => _StorySheetState();
}

class _StorySheetState extends State<StorySheet> {
  @override
  Widget build(BuildContext context) {
    final saved = widget.store.isBookmarked(widget.story.id);
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.94,
      builder: (context, controller) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(99)),
              ),
            ),
            const SizedBox(height: 14),
            Text(widget.dateLabel,
                style: TextStyle(
                    color: kAccent,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5)),
            const SizedBox(height: 6),
            Text(widget.story.title,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, height: 1.35)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children:
                  widget.story.tags.map((t) => TagChip(tag: t)).toList(),
            ),
            const SizedBox(height: 14),
            Text(widget.story.body,
                style:
                    const TextStyle(fontSize: 15.5, height: 1.7)),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await widget.store.toggleBookmark(widget.story,
                          widget.dateLabel, widget.daySlug);
                      setState(() {});
                    },
                    icon: Icon(saved
                        ? Icons.bookmark
                        : Icons.bookmark_border),
                    label: Text(saved ? 'Saved' : 'Save for revision'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      SharePlus.instance.share(ShareParams(
                          text:
                              '${widget.story.title}\n\n${widget.story.body}\n\n— via Current Affairs for Exams (${widget.dateLabel})'));
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const SectionHeader(
      {super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w800)),
          ),
          if (actionLabel != null)
            TextButton(
                onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class ExamFilterChips extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const ExamFilterChips(
      {super.key, required this.value, required this.onChanged});

  static const options = [
    ('all', 'All'),
    ('bank', '🏦 Bank'),
    ('upsc', '🎓 UPSC'),
    ('psu', '🏭 PSU'),
    ('high-yield', '⭐ High-yield'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: options.length,
        separatorBuilder: (_, i) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (key, label) = options[i];
          final selected = value == key;
          return ChoiceChip(
            label: Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.black : null)),
            selected: selected,
            selectedColor: kAccent,
            onSelected: (_) => onChanged(key),
          );
        },
      ),
    );
  }
}
