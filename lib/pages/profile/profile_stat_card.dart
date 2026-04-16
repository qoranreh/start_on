import 'package:flutter/material.dart';
import 'package:start_on/models/app_local_data.dart';
import 'package:start_on/pages/profile/profile_stat_bar.dart';
import 'package:start_on/widgets/common.dart';

class ProfileStatCard extends StatelessWidget {
  const ProfileStatCard({super.key, required this.data});

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
          ProfileStatBar(
            label: 'Work 스텟',
            value: data.diligenceStat / 100,
            score: '${data.diligenceStat} / 100',
            color: const Color(0xFFFF8B93),
          ),
          const SizedBox(height: 14),
          ProfileStatBar(
            label: 'Home 스텟',
            value: data.orderStat / 100,
            score: '${data.orderStat} / 100',
            color: const Color(0xFFFFD97D),
          ),
          const SizedBox(height: 14),
          ProfileStatBar(
            label: 'Study 스텟',
            value: data.intelligenceStat / 100,
            score: '${data.intelligenceStat} / 100',
            color: const Color(0xFFAED7FF),
          ),
          const SizedBox(height: 14),
          ProfileStatBar(
            label: 'Life 스텟',
            value: data.healthStat / 100,
            score: '${data.healthStat} / 100',
            color: const Color(0xFF78E49B),
          ),
        ],
      ),
    );
  }
}
