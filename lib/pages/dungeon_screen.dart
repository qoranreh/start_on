import 'package:start_on/widgets/common.dart';
import 'package:flutter/material.dart';

class DungeonScreen extends StatelessWidget {
  const DungeonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 120),
      children: const [
        Text(
          '던전',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1C2940),
          ),
        ),
        SizedBox(height: 6),
        Text(
          '어제의 미완료 퀘스트를 도전하세요',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF7E899D),
          ),
        ),
        SizedBox(height: 24),
        SectionHeading(icon: Icons.workspace_premium_outlined, title: '어제의 도전'),
        SizedBox(height: 14),
        DungeonCard(title: '어제의 명상 10분', difficulty: '쉬움', exp: 32),
        SizedBox(height: 14),
        DungeonCard(title: '어제의 저녁 운동', difficulty: '보통', exp: 48),
        SizedBox(height: 24),
        DungeonRewardCard(),
      ],
    );
  }
}

class DungeonCard extends StatelessWidget {
  const DungeonCard({
    super.key,
    required this.title,
    required this.difficulty,
    required this.exp,
  });

  final String title;
  final String difficulty;
  final int exp;

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
                  title,
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
                child: Text(
                  '+$exp EXP',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF33415C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '난이도: $difficulty',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF68553A),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF8B93),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('클리어하러가기'),
            ),
          ),
        ],
      ),
    );
  }
}

class DungeonRewardCard extends StatelessWidget {
  const DungeonRewardCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoundedCard(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(icon: Icons.workspace_premium_outlined, title: '던전 보상'),
          SizedBox(height: 10),
          Text(
            '던전을 클리어하고 보상을 받으세요!',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF7E899D),
            ),
          ),
          SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(999)),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: 0,
              backgroundColor: Color(0xFFE8ECF3),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF8B93)),
            ),
          ),
          SizedBox(height: 10),
          Text(
            '0 / 3 던전 완료',
            style: TextStyle(
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
