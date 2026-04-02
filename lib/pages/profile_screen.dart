import 'package:ad_focus/models/app_local_data.dart';
import 'package:ad_focus/widgets/common.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.data,
    required this.onOpenRecord,
  });

  final AppLocalData data;
  final VoidCallback onOpenRecord;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 120),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                '캐릭터',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1C2940),
                ),
              ),
            ),
            TextButton(
              onPressed: onOpenRecord,
              child: const Text('기록 보기'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        ProfileSummaryCard(data: data),
        const SizedBox(height: 22),
        StatCard(data: data),
        const SizedBox(height: 22),
        const AchievementCard(),
      ],
    );
  }
}

class ProfileSummaryCard extends StatelessWidget {
  const ProfileSummaryCard({super.key, required this.data});

  final AppLocalData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFF7F88),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF7F88).withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.sports_martial_arts_rounded, color: Colors.white, size: 38),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.userName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '레벨 ${data.level} · ${data.userRole}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFF29A)),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ProfileMetricCard(
                  label: '완료한 퀘스트',
                  value: '${data.completedQuestCount}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ProfileMetricCard(
                  label: '획득한 경험치',
                  value: '${data.earnedExp}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProfileMetricCard extends StatelessWidget {
  const ProfileMetricCard({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.data});

  final AppLocalData data;

  @override
  Widget build(BuildContext context) {
    return RoundedCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeading(icon: Icons.star_border_rounded, title: '능력치'),
          const SizedBox(height: 16),
          StatBar(label: '성실 스텟', value: data.diligenceStat / 100, score: '${data.diligenceStat} / 100', color: const Color(0xFFFF8B93)),
          const SizedBox(height: 14),
          StatBar(label: '정돈 스텟', value: data.orderStat / 100, score: '${data.orderStat} / 100', color: const Color(0xFFFFD97D)),
          const SizedBox(height: 14),
          StatBar(label: '지능 스텟', value: data.intelligenceStat / 100, score: '${data.intelligenceStat} / 100', color: const Color(0xFFAED7FF)),
          const SizedBox(height: 14),
          StatBar(label: '체력 스텟', value: data.healthStat / 100, score: '${data.healthStat} / 100', color: const Color(0xFF78E49B)),
        ],
      ),
    );
  }
}

class StatBar extends StatelessWidget {
  const StatBar({
    super.key,
    required this.label,
    required this.value,
    required this.score,
    required this.color,
  });

  final String label;
  final double value;
  final String score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF667085),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              score,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF33415C),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: value,
            backgroundColor: const Color(0xFFE9EDF5),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class AchievementCard extends StatelessWidget {
  const AchievementCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoundedCard(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '업적',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1C2940),
            ),
          ),
          SizedBox(height: 18),
          AchievementItem(
            icon: Icons.gps_fixed_rounded,
            title: '첫 퀘스트',
            subtitle: '첫 퀘스트 완료',
          ),
          SizedBox(height: 12),
          AchievementItem(
            icon: Icons.local_fire_department_rounded,
            title: '연속 달성',
            subtitle: '3일 연속 퀘스트 완료',
          ),
        ],
      ),
    );
  }
}

class AchievementItem extends StatelessWidget {
  const AchievementItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F8FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4D9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFFFF8B93)),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF33415C),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF7E899D),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
