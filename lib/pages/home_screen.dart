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
    final pendingCategoryCounts = _categoryCounts(widget.data.quests);
    final completedCategoryCounts = _completedCategoryCounts(
      widget.data.completedQuests,
    );
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
          completedCategoryCounts: completedCategoryCounts,
          pendingCategoryCounts: pendingCategoryCounts,
          onCategoryTap: _openCategoryQuestDialog,
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

  Map<String, int> _completedCategoryCounts(
    List<CompletedQuestRecord> records,
  ) {
    final counts = <String, int>{'work': 0, 'exercise': 0, 'A&I': 0, 'todo': 0};

    for (final record in records) {
      counts.update(record.category, (value) => value + 1, ifAbsent: () => 1);
    }

    return counts;
  }

  Future<void> _openCategoryQuestDialog(String category) async {
    final quests = widget.data.quests
        .where((item) => item.category == category)
        .toList();
    final result = await showDialog<Object?>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.22),
      builder: (context) =>
          _CategoryQuestDialog(category: category, quests: quests),
    );

    if (!mounted || result == null) {
      return;
    }

    if (result case QuestItem selectedQuest) {
      widget.onQuestTap(selectedQuest);
      return;
    }

    if (result == 'add') {
      widget.onAddQuestForCategory(category);
    }
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

class _CategoryQuestDialog extends StatelessWidget {
  const _CategoryQuestDialog({required this.category, required this.quests});

  final String category;
  final List<QuestItem> quests;

  @override
  Widget build(BuildContext context) {
    final style = questCategoryStyleFor(category);

    return Dialog(
      backgroundColor: style.backgroundColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: style.accentColor.withValues(alpha: 0.24)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.76,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: style.accentColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(style.icon, color: style.accentColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          style.label,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: style.accentColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${quests.length}개의 퀘스트',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6C7A90),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: const Color(0xFF93A1B5),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (quests.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        style.icon,
                        color: style.accentColor.withValues(alpha: 0.8),
                        size: 28,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '아직 ${style.label} 퀘스트가 없습니다',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF304056),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '아래 버튼으로 바로 새 퀘스트를 추가할 수 있어요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: Color(0xFF708096),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: [
                    for (var i = 0; i < quests.length; i++) ...[
                      _CategoryQuestTile(
                        quest: quests[i],
                        accentColor: style.accentColor,
                        onTap: () => Navigator.of(context).pop(quests[i]),
                      ),
                      if (i != quests.length - 1) const SizedBox(height: 10),
                    ],
                  ],
                ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop('add'),
                  icon: const Icon(Icons.add_rounded),
                  label: Text('${style.label} 퀘스트 추가'),
                  style: FilledButton.styleFrom(
                    backgroundColor: style.accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryQuestTile extends StatelessWidget {
  const _CategoryQuestTile({
    required this.quest,
    required this.accentColor,
    required this.onTap,
  });

  final QuestItem quest;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final difficultyLabel = switch (quest.difficulty) {
      '보통' => '중간',
      _ => quest.difficulty,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quest.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF243248),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _CategoryDialogMetaChip(
                          label:
                              '$difficultyLabel:${quest.defaultDurationSeconds ~/ 60}분',
                          accentColor: accentColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.chevron_right_rounded,
                color: accentColor.withValues(alpha: 0.76),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryDialogMetaChip extends StatelessWidget {
  const _CategoryDialogMetaChip({
    required this.label,
    required this.accentColor,
  });

  final String label;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: accentColor,
        ),
      ),
    );
  }
}
