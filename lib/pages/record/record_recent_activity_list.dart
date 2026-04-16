import 'package:flutter/material.dart';
import 'package:start_on/models/app_local_data.dart';
import 'package:start_on/pages/record/record_empty_card.dart';
import 'package:start_on/pages/record/record_recent_record_card.dart';

class RecordRecentActivityList extends StatelessWidget {
  const RecordRecentActivityList({super.key, required this.recent});

  final List<RecentActivity> recent;

  @override
  Widget build(BuildContext context) {
    if (recent.isEmpty) {
      return const RecordEmptyCard();
    }

    return Column(
      children: [
        for (var index = 0; index < recent.length; index++) ...[
          RecordRecentRecordCard(
            date: recent[index].date,
            subtitle: recent[index].subtitle,
            exp: '+${recent[index].exp}',
          ),
          if (index != recent.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}
