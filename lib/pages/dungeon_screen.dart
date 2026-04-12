import 'package:flutter/material.dart';
import 'package:start_on/models/app_local_data.dart';
import 'package:start_on/widgets/common.dart';

class DungeonScreen extends StatelessWidget {
  const DungeonScreen({
    super.key,
    required this.data,
    required this.onClearDungeon,
  });

  final AppLocalData data;
  final ValueChanged<String> onClearDungeon;

  static const _dungeons = [
    DungeonChallenge(
      id: 'dungeon_meditation',
      title: '어제의 명상 10분',
      difficulty: '쉬움',
      creditReward: 8,
    ),
    DungeonChallenge(
      id: 'dungeon_evening_workout',
      title: '어제의 저녁 운동',
      difficulty: '보통',
      creditReward: 12,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final clearedCount = _dungeons.where((item) => data.clearedDungeonIds.contains(item.id)).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 120),
      children: [
        const Text(
          '던전',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1C2940),
          ),
        ),
        const SizedBox(height: 24),
        const SectionHeading(icon: Icons.workspace_premium_outlined, title: '어제의 도전'),
        const SizedBox(height: 14),
        for (final dungeon in _dungeons) ...[
          DungeonCard(
            challenge: dungeon,
            cleared: data.clearedDungeonIds.contains(dungeon.id),
            onClear: () => onClearDungeon(dungeon.id),
          ),
          const SizedBox(height: 14),
        ],
        DungeonRewardCard(
          clearedCount: clearedCount,
          totalCount: _dungeons.length,
          totalCreditReward: _dungeons.fold(0, (sum, item) => sum + item.creditReward),
        ),
      ],
    );
  }
}

class DungeonCard extends StatelessWidget {
  const DungeonCard({
    super.key,
    required this.challenge,
    required this.cleared,
    required this.onClear,
  });

  final DungeonChallenge challenge;
  final bool cleared;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE6A7),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD987).withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  challenge.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF463317),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '+${challenge.creditReward}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF33415C),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.monetization_on_outlined,
                      size: 16,
                      color: Color(0xFF745C00),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '난이도: ${challenge.difficulty}',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF68553A),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: cleared ? null : onClear,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF8B93),
                disabledBackgroundColor: const Color(0xFFF3C1C6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(cleared ? '보상 수령 완료' : '클리어하고 보상 받기'),
            ),
          ),
        ],
      ),
    );
  }
}

class DungeonRewardCard extends StatelessWidget {
  const DungeonRewardCard({
    super.key,
    required this.clearedCount,
    required this.totalCount,
    required this.totalCreditReward,
  });

  final int clearedCount;
  final int totalCount;
  final int totalCreditReward;

  @override
  Widget build(BuildContext context) {
    final progress = totalCount == 0 ? 0.0 : clearedCount / totalCount;

    return RoundedCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: SectionHeading(
                  icon: Icons.workspace_premium_outlined,
                  title: '던전 보상',
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE48A),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.monetization_on_outlined,
                      size: 18,
                      color: Color(0xFF745C00),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '+$totalCreditReward',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF473200),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(999)),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress,
              backgroundColor: const Color(0xFFE8ECF3),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF8B93)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$clearedCount / $totalCount 던전 완료',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF98A2B3),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class DungeonChallenge {
  const DungeonChallenge({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.creditReward,
  });

  final String id;
  final String title;
  final String difficulty;
  final int creditReward;
}
