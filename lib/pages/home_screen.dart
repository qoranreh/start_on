import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart' as neu;
import 'package:intl/intl.dart';
import 'package:start_on/models/app_local_data.dart';
import 'package:start_on/pages/home/home_screen_sections.dart';

// 홈 탭 전체 상태와 상위 액션 콜백을 연결하는 메인 화면 위젯입니다.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.data,
    required this.userName,
    required this.onAddQuest,
    required this.onAddQuestForCategory,
    required this.onQuestTap,
    required this.onDeleteQuest,
    required this.onOpenSettings,
    required this.onOpenAutoQuestFromGallery,
    required this.onTabChange,
  });

  final AppLocalData data;
  final String userName;
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
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 118),
      children: [
        HomeHeaderSection(
          todayLabel: todayLabel,
          userName: widget.userName,
          credits: widget.data.credits,
          showCreditAmount: _showCreditAmount,
          onOpenSettings: widget.onOpenSettings,
        ),
        const SizedBox(height: 24),
        HomeCategoryGrid(
          completedCategoryCounts: completedCategoryCounts,
          pendingCategoryCounts: pendingCategoryCounts,
          onCategoryTap: _openCategoryQuestDialog,
          onAddCategoryQuest: widget.onAddQuestForCategory,
        ),
        const SizedBox(height: 26),
        HomeQuestSectionHeader(
          onOpenAutoAdd: widget.onOpenAutoQuestFromGallery,
          questCount: widget.data.quests.length,
        ),
        const SizedBox(height: 12),
        HomeQuestList(
          quests: widget.data.quests,
          onAddQuest: widget.onAddQuest,
          onQuestTap: widget.onQuestTap,
          onDeleteQuest: widget.onDeleteQuest,
        ),
        if (todayCompletedQuests.isNotEmpty) ...[
          const SizedBox(height: 8),
          if (completedQuestRevealProgress > 0)
            Align(
              alignment: Alignment.topCenter,
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
    final counts = <String, int>{'work': 0, 'life': 0, 'study': 0, 'home': 0};

    for (final quest in quests) {
      counts.update(quest.category, (value) => value + 1, ifAbsent: () => 1);
    }

    return counts;
  }

  Map<String, int> _completedCategoryCounts(
    List<CompletedQuestRecord> records,
  ) {
    final counts = <String, int>{'work': 0, 'life': 0, 'study': 0, 'home': 0};

    for (final record in records) {
      counts.update(record.category, (value) => value + 1, ifAbsent: () => 1);
    }

    return counts;
  }

  Future<void> _openCategoryQuestDialog(String category) async {
    final quests = widget.data.quests
        .where((item) => item.category == category)
        .toList();
    final completedRecords = widget.data.completedQuests
        .where((item) => item.category == category)
        .toList()
        .reversed
        .toList();
    final result = await showDialog<Object?>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.22),
      builder: (context) => _CategoryQuestDialog(
        category: category,
        quests: quests,
        completedRecords: completedRecords,
      ),
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
  const _CategoryQuestDialog({
    required this.category,
    required this.quests,
    required this.completedRecords,
  });

  final String category;
  final List<QuestItem> quests;
  final List<CompletedQuestRecord> completedRecords;

  @override
  Widget build(BuildContext context) {
    final style = questCategoryStyleFor(category);
    final dialogBackgroundColor = _categoryDialogBackgroundColor(category);
    final totalCount = quests.length + completedRecords.length;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: ColoredBox(
          color: dialogBackgroundColor,
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
                      neu.Neumorphic(
                        style: neu.NeumorphicStyle(
                          depth: 5,
                          intensity: 0.88,
                          surfaceIntensity: 0.24,
                          color: Color.alphaBlend(
                            style.accentColor.withValues(alpha: 0.08),
                            dialogBackgroundColor,
                          ),
                          shadowLightColor: dialogBackgroundColor.withValues(
                            alpha: 0.94,
                          ),
                          shadowDarkColor: style.accentColor.withValues(
                            alpha: 0.24,
                          ),
                          boxShape: neu.NeumorphicBoxShape.roundRect(
                            BorderRadius.circular(14),
                          ),
                        ),
                        padding: const EdgeInsets.all(10),
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
                              '${quests.length} 진행 중 · ${completedRecords.length} 완료',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6C7A90),
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: neu.Neumorphic(
                          style: neu.NeumorphicStyle(
                            depth: 4,
                            intensity: 0.84,
                            surfaceIntensity: 0.18,
                            color: dialogBackgroundColor,
                            shadowLightColor: dialogBackgroundColor.withValues(
                              alpha: 0.94,
                            ),
                            shadowDarkColor: style.accentColor.withValues(
                              alpha: 0.18,
                            ),
                            boxShape: const neu.NeumorphicBoxShape.circle(),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFF93A1B5),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (totalCount == 0)
                    neu.Neumorphic(
                      style: neu.NeumorphicStyle(
                        depth: 7,
                        intensity: 0.88,
                        surfaceIntensity: 0.24,
                        color: Color.alphaBlend(
                          style.accentColor.withValues(alpha: 0.05),
                          dialogBackgroundColor,
                        ),
                        shadowLightColor: dialogBackgroundColor.withValues(
                          alpha: 0.94,
                        ),
                        shadowDarkColor: style.accentColor.withValues(
                          alpha: 0.22,
                        ),
                        boxShape: neu.NeumorphicBoxShape.roundRect(
                          BorderRadius.circular(20),
                        ),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: SizedBox(
                        width: double.infinity,
                        child: Column(
                          children: [
                            neu.Neumorphic(
                              style: neu.NeumorphicStyle(
                                depth: -4,
                                intensity: 0.86,
                                surfaceIntensity: 0.18,
                                color: dialogBackgroundColor,
                                shadowLightColor: dialogBackgroundColor
                                    .withValues(alpha: 0.92),
                                shadowDarkColor: style.accentColor.withValues(
                                  alpha: 0.22,
                                ),
                                boxShape: const neu.NeumorphicBoxShape.circle(),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Icon(
                                style.icon,
                                color: style.accentColor.withValues(alpha: 0.8),
                                size: 28,
                              ),
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
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (quests.isNotEmpty) ...[
                          _CategoryDialogSectionLabel(
                            label: '진행 중',
                            accentColor: style.accentColor,
                          ),
                          const SizedBox(height: 10),
                          for (var i = 0; i < quests.length; i++) ...[
                            _CategoryQuestTile(
                              quest: quests[i],
                              accentColor: style.accentColor,
                              backgroundColor: dialogBackgroundColor,
                              onTap: () => Navigator.of(context).pop(quests[i]),
                            ),
                            if (i != quests.length - 1)
                              const SizedBox(height: 10),
                          ],
                        ],
                        if (quests.isNotEmpty && completedRecords.isNotEmpty)
                          const SizedBox(height: 18),
                        if (completedRecords.isNotEmpty) ...[
                          _CategoryDialogSectionLabel(
                            label: '완료',
                            accentColor: style.accentColor,
                          ),
                          const SizedBox(height: 10),
                          for (var i = 0; i < completedRecords.length; i++) ...[
                            _CompletedCategoryQuestTile(
                              record: completedRecords[i],
                              accentColor: style.accentColor,
                              backgroundColor: dialogBackgroundColor,
                            ),
                            if (i != completedRecords.length - 1)
                              const SizedBox(height: 10),
                          ],
                        ],
                      ],
                    ),
                  const SizedBox(height: 18),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop('add'),
                    child: neu.Neumorphic(
                      style: neu.NeumorphicStyle(
                        depth: 6,
                        intensity: 0.9,
                        surfaceIntensity: 0.22,
                        color: style.accentColor,
                        shadowLightColor: dialogBackgroundColor.withValues(
                          alpha: 0.94,
                        ),
                        shadowDarkColor: style.accentColor.withValues(
                          alpha: 0.34,
                        ),
                        boxShape: neu.NeumorphicBoxShape.roundRect(
                          BorderRadius.circular(18),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_rounded, color: dialogBackgroundColor),
                          const SizedBox(width: 8),
                          Text(
                            '${style.label} 퀘스트 추가',
                            style: TextStyle(
                              color: dialogBackgroundColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
    required this.backgroundColor,
    required this.onTap,
  });

  final QuestItem quest;
  final Color accentColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final difficultyLabel = switch (quest.difficulty) {
      '보통' => '중간',
      _ => quest.difficulty,
    };
    final baseColor = Color.alphaBlend(
      accentColor.withValues(alpha: 0.08),
      backgroundColor,
    );

    return GestureDetector(
      onTap: onTap,
      child: neu.Neumorphic(
        style: neu.NeumorphicStyle(
          depth: 7,
          intensity: 0.9,
          surfaceIntensity: 0.24,
          color: baseColor,
          shadowLightColor: backgroundColor.withValues(alpha: 0.94),
          shadowDarkColor: accentColor.withValues(alpha: 0.28),
          boxShape: neu.NeumorphicBoxShape.roundRect(BorderRadius.circular(18)),
        ),
        padding: const EdgeInsets.all(16),
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
                        backgroundColor: backgroundColor,
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
    );
  }
}

class _CategoryDialogSectionLabel extends StatelessWidget {
  const _CategoryDialogSectionLabel({
    required this.label,
    required this.accentColor,
  });

  final String label;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: accentColor.withValues(alpha: 0.86),
      ),
    );
  }
}

class _CompletedCategoryQuestTile extends StatelessWidget {
  const _CompletedCategoryQuestTile({
    required this.record,
    required this.accentColor,
    required this.backgroundColor,
  });

  final CompletedQuestRecord record;
  final Color accentColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final difficultyLabel = switch (record.difficulty) {
      '보통' => '중간',
      _ => record.difficulty,
    };
    final completedAt = DateTime.tryParse(record.completedAt)?.toLocal();
    final completedLabel = completedAt == null
        ? '완료'
        : '${completedAt.month}/${completedAt.day} 완료';

    return neu.Neumorphic(
      style: neu.NeumorphicStyle(
        depth: 7,
        intensity: 0.92,
        surfaceIntensity: 0.28,
        color: Color.alphaBlend(
          accentColor.withValues(alpha: 0.2),
          backgroundColor,
        ),
        shadowLightColor: backgroundColor.withValues(alpha: 0.94),
        shadowDarkColor: accentColor.withValues(alpha: 0.34),
        boxShape: neu.NeumorphicBoxShape.roundRect(BorderRadius.circular(18)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.title,
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
                      label: '$difficultyLabel:${record.elapsedSeconds ~/ 60}분',
                      accentColor: accentColor,
                      backgroundColor: backgroundColor,
                    ),
                    _CategoryDialogMetaChip(
                      label: completedLabel,
                      accentColor: accentColor,
                      backgroundColor: backgroundColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            Icons.check_circle_rounded,
            color: accentColor.withValues(alpha: 0.88),
          ),
        ],
      ),
    );
  }
}

class _CategoryDialogMetaChip extends StatelessWidget {
  const _CategoryDialogMetaChip({
    required this.label,
    required this.accentColor,
    required this.backgroundColor,
  });

  final String label;
  final Color accentColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return neu.Neumorphic(
      style: neu.NeumorphicStyle(
        depth: -3,
        intensity: 0.88,
        surfaceIntensity: 0.18,
        color: Color.alphaBlend(
          accentColor.withValues(alpha: 0.08),
          backgroundColor,
        ),
        shadowLightColor: backgroundColor.withValues(alpha: 0.9),
        shadowDarkColor: accentColor.withValues(alpha: 0.18),
        boxShape: neu.NeumorphicBoxShape.roundRect(BorderRadius.circular(999)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

Color _categoryDialogBackgroundColor(String category) {
  return switch (normalizeQuestCategory(category)) {
    'work' => const Color(0xFFEAF5F4),
    'life' => const Color(0xFFF0F7F1),
    'study' => const Color(0xFFFFF6D6),
    'home' => const Color(0xFFFFEFEA),
    _ => const Color(0xFFF1F3F8),
  };
}
