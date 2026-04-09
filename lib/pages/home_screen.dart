import 'dart:io';

import 'package:start_on/models/app_local_data.dart';
import 'package:start_on/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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
  late final ScrollController _scrollController;
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);
  }

  void _handleScroll() {
    final offset = _scrollController.hasClients ? _scrollController.offset : 0.0;
    if ((offset - _scrollOffset).abs() < 0.5) {
      return;
    }
    setState(() {
      _scrollOffset = offset;
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayCompletedQuests = widget.data.completedQuests.where((item) {
      final completedAt = DateTime.tryParse(item.completedAt)?.toLocal();
      return completedAt != null &&
          completedAt.year == now.year &&
          completedAt.month == now.month &&
          completedAt.day == now.day;
    }).toList();

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 120),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                '오늘의 퀘스트',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1C2940),
                ),
              ),
            ),
            TopIconButton(icon: Icons.emoji_events_outlined, onTap: () {}),
            const SizedBox(width: 10),
            TopIconButton(icon: Icons.settings_outlined, onTap: () {}),
          ],
        ),
        const SizedBox(height: 18),
        MotivationCard(scrollOffset: _scrollOffset),
        const SizedBox(height: 20),
        const CategoryGrid(),
        const SizedBox(height: 18),
        Row(
          children: [
            const Expanded(
              child: Text(
                '오늘의 퀘스트',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1C2940),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (widget.data.quests.isEmpty)
          EmptyQuestCard(onTap: widget.onAddQuest)
        else
          for (final quest in widget.data.quests) ...[
            QuestCard(
              quest: quest,
              onTap: () => widget.onQuestTap(quest),
              onDelete: () => widget.onDeleteQuest(quest),
            ),
            const SizedBox(height: 14),
          ],
        if (todayCompletedQuests.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text(
            '완료한 퀘스트',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1C2940),
            ),
          ),
          const SizedBox(height: 12),
          for (final item in todayCompletedQuests) ...[
            CompletedQuestCard(record: item),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }
}

class QuestCard extends StatelessWidget {
  const QuestCard({
    super.key,
    required this.quest,
    required this.onTap,
    required this.onDelete,
  });

  final QuestItem quest;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: RoundedCard(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD6DCE8), width: 2),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quest.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF33415C),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '+${quest.exp} EXP',
                          style: const TextStyle(
                            color: Color(0xFFFF8B93),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: '  ·  ${quest.difficulty}  ·  ${quest.category}',
                          style: const TextStyle(
                            color: Color(0xFF98A2B3),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFC0C7D4)),
            ),
          ],
        ),
      ),
    );
  }
}

class CompletedQuestCard extends StatelessWidget {
  const CompletedQuestCard({super.key, required this.record});

  final CompletedQuestRecord record;

  @override
  Widget build(BuildContext context) {
    final completedAt = DateTime.tryParse(record.completedAt)?.toLocal();
    final completedTime = completedAt == null
        ? '완료'
        : '${completedAt.hour.toString().padLeft(2, '0')}:${completedAt.minute.toString().padLeft(2, '0')} 완료';

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8EE),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFBEE3C5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7BC78D).withValues(alpha: 0.14),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Color(0xFF2E9B57),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF33415C),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$completedTime  ·  ${record.category}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8E9AAE),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (record.proofImagePath != null && record.proofImagePath!.isNotEmpty) ...[
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                File(record.proofImagePath!),
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) {
                  return Container(
                    width: 52,
                    height: 52,
                    color: const Color(0xFFE8F5E9),
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: Color(0xFF7FA58A),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${record.earnedExp}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFFF8B93),
                ),
              ),
              const Text(
                'EXP',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF98A2B3),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class EmptyQuestCard extends StatelessWidget {
  const EmptyQuestCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: const RoundedCard(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 34, color: Color(0xFFC0C7D4)),
            SizedBox(height: 12),
            Text(
              '등록된 퀘스트가 없습니다',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF33415C),
              ),
            ),
            SizedBox(height: 6),
            Text(
              '이 카드를 눌러 첫 퀘스트를 추가하세요',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF8E9AAE),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TopIconButton extends StatelessWidget {
  const TopIconButton({required this.icon, required this.onTap, super.key});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.76),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: const Color(0xFF6D788A), size: 20),
      ),
    );
  }
}

class MotivationCard extends StatefulWidget {
  const MotivationCard({super.key, required this.scrollOffset});

  final double scrollOffset;

  @override
  State<MotivationCard> createState() => _MotivationCardState();
}

class _MotivationCardState extends State<MotivationCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;
  double? _cardHeight;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.42, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
      ),
    );
    _scale = Tween<double>(begin: 0.98, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rawProgress = _cardHeight == null || _cardHeight == 0
        ? 0.0
        : (widget.scrollOffset / _cardHeight!).clamp(0.0, 1.0).toDouble();
    final collapseProgress = Curves.easeOutCubic.transform(rawProgress);
    final visibleFactor = 1 - collapseProgress;

    return ClipRect(
      child: Align(
        alignment: Alignment.topCenter,
        heightFactor: visibleFactor,
        child: Opacity(
          opacity: visibleFactor,
          child: SlideTransition(
            position: _slide,
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: MeasureSize(
                  onChange: (size) {
                    if (_cardHeight == null || (size.height - _cardHeight!).abs() > 0.5) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) {
                          return;
                        }
                        setState(() {
                          _cardHeight = size.height;
                        });
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.86),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFB8C7DE).withValues(alpha: 0.2),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFE1A7)),
                        SizedBox(width: 10),
                        Text(
                          '오늘도 파이팅!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MeasureSize extends SingleChildRenderObjectWidget {
  const MeasureSize({required this.onChange, required super.child, super.key});

  final ValueChanged<Size> onChange;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderMeasureSize(onChange);
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderMeasureSize).onChange = onChange;
  }
}

class _RenderMeasureSize extends RenderProxyBox {
  _RenderMeasureSize(this.onChange);

  ValueChanged<Size> onChange;
  Size? _oldSize;

  @override
  void performLayout() {
    super.performLayout();
    final newSize = child?.size;
    if (newSize == null || newSize == _oldSize) {
      return;
    }
    _oldSize = newSize;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onChange(newSize);
    });
  }
}

class CategoryGrid extends StatelessWidget {
  const CategoryGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CategoryCard(
                title: 'work',
                icon: Icons.work_outline_rounded,
                accentColor: Color(0xFF5C7CFA),
                backgroundColor: Color(0xFFF2F5FF),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: CategoryCard(
                title: 'exercise',
                icon: Icons.fitness_center_rounded,
                accentColor: Color(0xFFFF8A65),
                backgroundColor: Color(0xFFFFF1EB),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CategoryCard(
                title: 'A&I',
                icon: Icons.psychology_alt_outlined,
                accentColor: Color(0xFF26A69A),
                backgroundColor: Color(0xFFECFAF8),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: CategoryCard(
                title: 'todo',
                icon: Icons.checklist_rounded,
                accentColor: Color(0xFFFFC857),
                backgroundColor: Color(0xFFFFF8E7),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.backgroundColor,
  });

  final String title;
  final IconData icon;
  final Color accentColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(height: 26),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF24324A),
            ),
          ),
        ],
      ),
    );
  }
}
