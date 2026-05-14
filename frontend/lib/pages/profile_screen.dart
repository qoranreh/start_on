import 'package:flutter/material.dart';
import 'package:start_on/models/app_local_data.dart';
import 'package:start_on/pages/profile/profile_sections.dart';

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
        ProfileHeader(onOpenRecord: onOpenRecord),
        const SizedBox(height: 18),
        ProfileSummaryCard(data: data),
        const SizedBox(height: 22),
        ProfileStatCard(data: data),
        const SizedBox(height: 22),
        const ProfileAchievementCard(),
      ],
    );
  }
}
