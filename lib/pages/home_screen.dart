import 'dart:io';

import 'package:start_on/models/app_local_data.dart';
import 'package:start_on/widgets/common.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.data,
    required this.onAddQuest,
    required this.onQuestTap,
    required this.onDeleteQuest,
    required this.onTabChange,
  });

  final AppLocalData data;
  final VoidCallback onAddQuest;
  final ValueChanged<QuestItem> onQuestTap;
  final ValueChanged<QuestItem> onDeleteQuest;
  final ValueChanged<int> onTabChange;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayCompletedQuests = data.completedQuests.where((item) {
      final completedAt = DateTime.tryParse(item.completedAt)?.toLocal();
      return completedAt != null &&
          completedAt.year == now.year &&
          completedAt.month == now.month &&
          completedAt.day == now.day;
    }).toList();

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 120),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '오늘의 퀘스트',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1C2940),
                    ),
                  ),
                ),
                TopIconButton(icon: Icons.emoji_events_outlined, onTap: () {}),
                const SizedBox(width: 10),
                TopIconButton(icon: Icons.settings_outlined, onTap: () {}),
              ],
            ),
            const SizedBox(height: 18),
            const MotivationCard(),
            const SizedBox(height: 20),
            PlayerLevelCard(data: data),
            const SizedBox(height: 22),
            RewardRow(data: data),
            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '오늘의 퀘스트',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1C2940),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => onTabChange(1),
                  child: const Text(
                    '던전 보기',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8E9AAE),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (data.quests.isEmpty)
              const EmptyQuestCard()
            else
              for (final quest in data.quests) ...[
                QuestCard(
                  quest: quest,
                  onTap: () => onQuestTap(quest),
                  onDelete: () => onDeleteQuest(quest),
                ),
                const SizedBox(height: 14),
              ],
            if (todayCompletedQuests.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                '완료한 퀘스트',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1C2940),
                ),
              ),
              const SizedBox(height: 12),
              for (final item in todayCompletedQuests) ...[
                CompletedQuestCard(record: item),
                const SizedBox(height: 12),
              ],
            ],
          ],
        ),
        Positioned(
          right: 22,
          bottom: 108,
          child: GestureDetector(
            onTap: onAddQuest,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF8B93),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF8B93).withValues(alpha: 0.34),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
            ),
          ),
        ),
      ],
    );
  }
}

class QuestCard extends StatelessWidget {
  const QuestCard({
    super.key,
    required this.quest,
    required this.onTap,
    required this.onDelete,
  });

  final QuestItem quest;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: RoundedCard(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD6DCE8), width: 2),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quest.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF33415C),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '+${quest.exp} EXP',
                          style: const TextStyle(
                            color: Color(0xFFFF8B93),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: '  ·  ${quest.difficulty}  ·  ${quest.category}',
                          style: const TextStyle(
                            color: Color(0xFF98A2B3),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFC0C7D4)),
            ),
          ],
        ),
      ),
    );
  }
}

class CompletedQuestCard extends StatelessWidget {
  const CompletedQuestCard({super.key, required this.record});

  final CompletedQuestRecord record;

  @override
  Widget build(BuildContext context) {
    final completedAt = DateTime.tryParse(record.completedAt)?.toLocal();
    final completedTime = completedAt == null
        ? '완료'
        : '${completedAt.hour.toString().padLeft(2, '0')}:${completedAt.minute.toString().padLeft(2, '0')} 완료';

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8EE),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFBEE3C5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7BC78D).withValues(alpha: 0.14),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Color(0xFF2E9B57),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF33415C),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$completedTime  ·  ${record.category}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8E9AAE),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (record.proofImagePath != null && record.proofImagePath!.isNotEmpty) ...[
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                File(record.proofImagePath!),
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) {
                  return Container(
                    width: 52,
                    height: 52,
                    color: const Color(0xFFE8F5E9),
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: Color(0xFF7FA58A),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${record.earnedExp}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFFF8B93),
                ),
              ),
              const Text(
                'EXP',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF98A2B3),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class EmptyQuestCard extends StatelessWidget {
  const EmptyQuestCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoundedCard(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 34, color: Color(0xFFC0C7D4)),
          SizedBox(height: 12),
          Text(
            '등록된 퀘스트가 없습니다',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF33415C),
            ),
          ),
          SizedBox(height: 6),
          Text(
            '오른쪽 아래 + 버튼으로 첫 퀘스트를 추가하세요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF8E9AAE),
            ),
          ),
        ],
      ),
    );
  }
}

class TopIconButton extends StatelessWidget {
  const TopIconButton({required this.icon, required this.onTap, super.key});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.76),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: const Color(0xFF6D788A), size: 20),
      ),
    );
  }
}

class MotivationCard extends StatelessWidget {
  const MotivationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoundedCard(
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFE1A7)),
          SizedBox(width: 10),
          Text(
            '오늘도 파이팅!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class PlayerLevelCard extends StatelessWidget {
  const PlayerLevelCard({required this.data, super.key});

  final AppLocalData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF7F88),
            Color(0xFFFF7C7F),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF8B93).withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  '플레이어',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '레벨',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  data.userName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                '${data.level}',
                style: const TextStyle(
                  fontSize: 38,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Expanded(
                child: Text(
                  '경험치',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${data.currentExp} / ${data.maxExp} EXP',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: data.maxExp == 0 ? 0 : data.currentExp / data.maxExp,
              backgroundColor: const Color(0xFFFFA0A6),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class RewardRow extends StatelessWidget {
  const RewardRow({required this.data, super.key});

  final AppLocalData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: RewardCard(
            title: '일일 보상',
            value: '${data.dailyRewardCount} / ${data.dailyRewardTarget}',
            progress: data.dailyRewardTarget == 0 ? 0 : data.dailyRewardCount / data.dailyRewardTarget,
            progressColor: const Color(0xFFD9DEE9),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RewardCard(
            title: '주간 보상',
            value: '${data.weeklyRewardCount} / ${data.weeklyRewardTarget}',
            progress: data.weeklyRewardTarget == 0 ? 0 : data.weeklyRewardCount / data.weeklyRewardTarget,
            progressColor: const Color(0xFFFFDF7F),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RewardCard(
            title: '월간 보상',
            value: '${data.monthlyRewardCount} / ${data.monthlyRewardTarget}',
            progress: data.monthlyRewardTarget == 0 ? 0 : data.monthlyRewardCount / data.monthlyRewardTarget,
            progressColor: const Color(0xFFAED7FF),
          ),
        ),
      ],
    );
  }
}

class RewardCard extends StatelessWidget {
  const RewardCard({
    super.key,
    required this.title,
    required this.value,
    required this.progress,
    required this.progressColor,
  });

  final String title;
  final String value;
  final double progress;
  final Color progressColor;

  @override
  Widget build(BuildContext context) {
    return RoundedCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF98A2B3),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF33415C),
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress,
              backgroundColor: const Color(0xFFE9EDF5),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
        ],
      ),
    );
  }
}
