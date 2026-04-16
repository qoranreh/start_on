import 'package:flutter/material.dart';
import 'package:start_on/pages/profile/profile_achievement_item.dart';
import 'package:start_on/widgets/common.dart';

class ProfileAchievementCard extends StatelessWidget {
  const ProfileAchievementCard({super.key});

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
          ProfileAchievementItem(
            icon: Icons.gps_fixed_rounded,
            title: '첫 퀘스트',
            subtitle: '첫 퀘스트 완료',
          ),
          SizedBox(height: 12),
          ProfileAchievementItem(
            icon: Icons.local_fire_department_rounded,
            title: '연속 달성',
            subtitle: '3일 연속 퀘스트 완료',
          ),
        ],
      ),
    );
  }
}
