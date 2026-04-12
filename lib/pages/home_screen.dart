import 'dart:async';

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
    required this.onAddQuestForCategory,
    required this.onQuestTap,
    required this.onDeleteQuest,
    required this.onOpenSettings,
    required this.onOpenAutoQuestFromGallery,
    required this.onTabChange,
  });

  final AppLocalData data;
  final VoidCallback onAddQuest;
  final ValueChanged<String> onAddQuestForCategory;
  final ValueChanged<QuestItem> onQuestTap;
  final ValueChanged<QuestItem> onDeleteQuest;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenAutoQuestFromGallery;
  final ValueChanged<int> onTabChange;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  Timer? _creditVisibilityTimer;
  double _scrollOffset = 0;
  bool _isAtTop = true;
  bool _showCreditAmount = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _startCreditVisibilityTimer();
  }

  @override
  void dispose() {
    _creditVisibilityTimer?.cancel();
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

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
    final completedQuestRevealProgress = _completedQuestRevealProgress;

    // 상단 헤더, 카테고리, 퀘스트 목록, 완료 기록을 세로로 배치합니다.
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 120),
      children: [
        HomeHeaderSection(
          todayLabel: todayLabel,
          credits: widget.data.credits,
          showCreditAmount: _showCreditAmount,
          onOpenSettings: widget.onOpenSettings,
        ),
        const SizedBox(height: 18),
        HomeCategoryGrid(
          categoryCounts: categoryCounts,
          onAddCategoryQuest: widget.onAddQuestForCategory,
        ),
        const SizedBox(height: 18),
        HomeQuestSectionHeader(
          onOpenAutoAdd: widget.onOpenAutoQuestFromGallery,
        ),
        const SizedBox(height: 14),
        HomeQuestList(
          quests: widget.data.quests,
          onAddQuest: widget.onAddQuest,
          onQuestTap: widget.onQuestTap,
          onDeleteQuest: widget.onDeleteQuest,
        ),
        if (todayCompletedQuests.isNotEmpty) ...[
          const SizedBox(height: 8),
          ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: completedQuestRevealProgress,
              child: Opacity(
                opacity: completedQuestRevealProgress,
                child: Transform.translate(
                  offset: Offset(0, (1 - completedQuestRevealProgress) * 18),
                  child: HomeCompletedQuestSection(
                    records: todayCompletedQuests,
                  ),
                ),
              ),
            ),
          ),
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

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final nextOffset = _scrollController.offset < 0
        ? 0.0
        : _scrollController.offset;
    final isAtTop = nextOffset <= 0.5;

    if (isAtTop) {
      if (!_isAtTop) {
        _isAtTop = true;
        _creditVisibilityTimer?.cancel();
        setState(() {
          _scrollOffset = nextOffset;
          _showCreditAmount = true;
        });
        _startCreditVisibilityTimer();
        return;
      }

      if (_scrollOffset != nextOffset) {
        setState(() => _scrollOffset = nextOffset);
      }
      return;
    }

    _isAtTop = false;
    _creditVisibilityTimer?.cancel();
    if (_showCreditAmount || _scrollOffset != nextOffset) {
      setState(() {
        _scrollOffset = nextOffset;
        _showCreditAmount = false;
      });
    }
  }

  void _startCreditVisibilityTimer() {
    _creditVisibilityTimer?.cancel();
    _creditVisibilityTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }

      if (_scrollController.offset <= 0.5 && _showCreditAmount) {
        setState(() => _showCreditAmount = false);
      }
    });
  }

  double get _completedQuestRevealProgress {
    const startOffset = 36.0;
    const endOffset = 160.0;

    final rawProgress =
        ((_scrollOffset - startOffset) / (endOffset - startOffset)).clamp(
          0.0,
          1.0,
        );
    return Curves.easeOutCubic.transform(rawProgress);
  }
}
