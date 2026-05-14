import 'package:flutter/material.dart';

class QuestTimerContentCard extends StatelessWidget {
  const QuestTimerContentCard({
    super.key,
    this.useLandscapeLayout = false,
    required this.questSummary,
    required this.countdown,
    required this.actionButtons,
    required this.proofSection,
    required this.categoryTimes,
  });

  final bool useLandscapeLayout;
  final Widget questSummary;
  final Widget countdown;
  final Widget actionButtons;
  final Widget proofSection;
  final Widget categoryTimes;

  @override
  Widget build(BuildContext context) {
    if (useLandscapeLayout) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 6,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Column(
                  children: [
                    questSummary,
                    const SizedBox(height: 22),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: proofSection),
                        const SizedBox(width: 12),
                        Expanded(child: categoryTimes),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 26),
          Expanded(
            flex: 4,
            child: Column(
              children: [
                countdown,
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(fit: BoxFit.scaleDown, child: actionButtons),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        questSummary,
        const SizedBox(height: 28),
        countdown,
        const SizedBox(height: 20),
        actionButtons,
        const SizedBox(height: 26),
        proofSection,
        const SizedBox(height: 24),
        categoryTimes,
      ],
    );
  }
}
