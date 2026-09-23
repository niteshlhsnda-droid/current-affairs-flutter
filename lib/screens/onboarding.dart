// First-launch onboarding: one screen, one question —
// which exam are you preparing for? Sets the home-feed filter
// immediately so day one feels personal. No login, no phone number.

import 'package:flutter/material.dart';

import '../store.dart';
import '../widgets/widgets.dart';

class OnboardingScreen extends StatefulWidget {
  final UserStore store;
  const OnboardingScreen({super.key, required this.store});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String _exam = 'all';

  static const _options = [
    ('all', '🎯', 'All exams', 'Bank + UPSC + PSU, everything daily'),
    ('bank', '🏦', 'Bank exams', 'IBPS, SBI, RBI — finance-first news'),
    ('upsc', '🎓', 'UPSC', 'CSE/State PSC — polity, economy, IR depth'),
    ('psu', '🏭', 'PSU & SSC', 'SSC, railways, PSU recruitments'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: kAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('📰',
                    style: TextStyle(fontSize: 36)),
              ),
              const SizedBox(height: 20),
              const Text(
                'Current Affairs\nfor Exams',
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    height: 1.15),
              ),
              const SizedBox(height: 10),
              Text(
                'Fresh every morning and evening, synced from GitHub. '
                'Quiz yourself daily. No account, no ads.',
                style: TextStyle(
                    fontSize: 14.5,
                    height: 1.55,
                    color: Colors.grey.shade500),
              ),
              const SizedBox(height: 28),
              const Text('Which exam are you preparing for?',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ..._options.map((o) {
                final selected = _exam == o.$1;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => setState(() => _exam = o.$1),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? kAccent
                              : Colors.grey.withValues(alpha: 0.3),
                          width: selected ? 2 : 1,
                        ),
                        color: selected
                            ? kAccent.withValues(alpha: 0.08)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Text(o.$2,
                              style:
                                  const TextStyle(fontSize: 26)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(o.$3,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15.5)),
                                Text(o.$4,
                                    style: TextStyle(
                                        fontSize: 12.5,
                                        color:
                                            Colors.grey.shade500)),
                              ],
                            ),
                          ),
                          if (selected)
                            const Icon(Icons.check_circle,
                                color: kAccent),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: kAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    await widget.store.setExamFilter(_exam);
                    await widget.store.setOnboarded(true);
                  },
                  child: const Text('Start preparing →',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
