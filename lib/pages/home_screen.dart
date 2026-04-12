import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:start_on/models/app_local_data.dart';
import 'package:start_on/pages/home/home_screen_sections.dart';

// 홈 탭 전체 상태와 상위 액션 콜백을 연결하는 메인 화면 위젯입니다.
class HomeScreen extends StatefulWidget {
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
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    // 오늘 날짜 기준으로 헤더 문구와 완료 퀘스트 목록을 계산합니다.
    final now = DateTime.now();
    final todayLabel = 'Today ${DateFormat('d MMMM').format(now)}';
    final categoryCounts = _categoryCounts(widget.data.quests);
    final todayCompletedQuests = _todayCompletedQuests(
      records: widget.data.completedQuests,
      now: now,
    );

    // 상단 헤더, 카테고리, 퀘스트 목록, 완료 기록을 세로로 배치합니다.
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 120),
      children: [
        HomeHeaderSection(todayLabel: todayLabel),
        const SizedBox(height: 18),
        HomeCategoryGrid(categoryCounts: categoryCounts),
        const SizedBox(height: 18),
        const HomeQuestSectionHeader(),
        const SizedBox(height: 14),
        HomeQuestList(
          quests: widget.data.quests,
          onAddQuest: widget.onAddQuest,
          onQuestTap: widget.onQuestTap,
          onDeleteQuest: widget.onDeleteQuest,
        ),
        if (todayCompletedQuests.isNotEmpty) ...[
          const SizedBox(height: 8),
          HomeCompletedQuestSection(records: todayCompletedQuests),
        ],
      ],
    );
  }

  List<CompletedQuestRecord> _todayCompletedQuests({
    required List<CompletedQuestRecord> records,
    required DateTime now,
  }) {
    return records.where((item) {
      final completedAt = DateTime.tryParse(item.completedAt)?.toLocal();
      return completedAt != null &&
          completedAt.year == now.year &&
          completedAt.month == now.month &&
          completedAt.day == now.day;
    }).toList();
  }

  Map<String, int> _categoryCounts(List<QuestItem> quests) {
    final counts = <String, int>{'work': 0, 'exercise': 0, 'A&I': 0, 'todo': 0};

    for (final quest in quests) {
      counts.update(quest.category, (value) => value + 1, ifAbsent: () => 1);
    }

    return counts;
  }
}
