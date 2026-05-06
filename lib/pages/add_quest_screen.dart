import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart' as neu;
import 'package:start_on/models/app_local_data.dart';

class AddQuestScreen extends StatefulWidget {
  const AddQuestScreen({
    super.key,
    this.initialCategory,
    this.initialQuest,
    this.title = 'Create New Task',
    this.submitLabel = 'Create task',
  });

  final String? initialCategory;
  final QuestItem? initialQuest;
  final String title;
  final String submitLabel;

  @override
  State<AddQuestScreen> createState() => _AddQuestScreenState();
}

class _AddQuestScreenState extends State<AddQuestScreen> {
  static const List<String> _difficultyOptions = ['쉬움', '보통', '어려움'];
  static const List<String> _categoryOptions = [
    'home',
    'study',
    'work',
    'life',
  ];
  static const Color _dialogColor = Color(0xFFF1F2F6);
  static const Color _labelColor = Color(0xFF8A8E98);
  static const Color _titleColor = Color(0xFF111111);

  final TextEditingController _controller = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _difficulty = '보통';
  String _category = 'work';
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    final initialQuest = widget.initialQuest;
    if (initialQuest != null) {
      _controller.text = initialQuest.title;
      _difficulty = initialQuest.difficulty;
      _category = normalizeQuestCategory(initialQuest.category);
      _dueDate = normalizeQuestDueDate(initialQuest.dueDate);
      return;
    }

    final initialCategory = widget.initialCategory;
    if (initialCategory != null && questCategories.contains(initialCategory)) {
      _category = initialCategory;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Scaffold(
      backgroundColor: _dialogColor,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(28, 24, 28, 40 + viewInsets.bottom),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Color(0xFF2C2F36),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(height: 18),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: _titleColor,
                  ),
                ),
                const SizedBox(height: 14),
                const _DialogSectionLabel('Title'),
                const SizedBox(height: 8),
                FractionallySizedBox(
                  widthFactor: 0.86,
                  child: _InsetFieldShell(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: '',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isCollapsed: true,
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _titleColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const _DialogSectionLabel('Due Date'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickDueDate,
                        behavior: HitTestBehavior.opaque,
                        child: _InsetFieldShell(
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _dueDate == null
                                      ? ''
                                      : formatQuestDueDate(_dueDate!),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _dueDate == null
                                        ? const Color(0xFFB7BCC7)
                                        : _titleColor,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Color(0xFF1F1F1F),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _pickDueDate,
                      onLongPress: _dueDate == null
                          ? null
                          : () => setState(() => _dueDate = null),
                      child: neu.Neumorphic(
                        style: const neu.NeumorphicStyle(
                          depth: 6,
                          intensity: 0.95,
                          surfaceIntensity: 0.24,
                          color: Color(0xFFDAD3FF),
                          shadowDarkColor: Color(0x26000000),
                          shadowLightColor: Color(0xFFFFFFFF),
                          boxShape: neu.NeumorphicBoxShape.circle(),
                        ),
                        padding: const EdgeInsets.all(14),
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          size: 22,
                          color: Color(0xFF171717),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const _DialogSectionLabel('Description'),
                const SizedBox(height: 8),
                _InsetFieldShell(
                  height: 96,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: TextField(
                    controller: _descriptionController,
                    minLines: 4,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: '',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isCollapsed: true,
                    ),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _titleColor,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const _DialogSectionLabel('Level'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (var i = 0; i < _difficultyOptions.length; i++) ...[
                      Expanded(
                        child: _LevelChip(
                          label: _difficultyOptions[i],
                          selected: _difficultyOptions[i] == _difficulty,
                          onTap: () => setState(
                            () => _difficulty = _difficultyOptions[i],
                          ),
                        ),
                      ),
                      if (i != _difficultyOptions.length - 1)
                        const SizedBox(width: 14),
                    ],
                  ],
                ),
                const SizedBox(height: 14),
                const _DialogSectionLabel('Category'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (var i = 0; i < _categoryOptions.length; i++) ...[
                      Expanded(
                        child: _CategoryChip(
                          label: questCategoryLabel(
                            _categoryOptions[i],
                          ).toUpperCase(),
                          selected: _categoryOptions[i] == _category,
                          style: _categoryChipStyleFor(_categoryOptions[i]),
                          onTap: () =>
                              setState(() => _category = _categoryOptions[i]),
                        ),
                      ),
                      if (i != _categoryOptions.length - 1)
                        const SizedBox(width: 10),
                    ],
                  ],
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: GestureDetector(
                    onTap: _submit,
                    child: neu.Neumorphic(
                      style: neu.NeumorphicStyle(
                        depth: 6,
                        intensity: 0.95,
                        surfaceIntensity: 0.2,
                        color: const Color(0xFF6B9AF5),
                        shadowDarkColor: const Color(0x66000000),
                        shadowLightColor: Colors.white,
                        boxShape: neu.NeumorphicBoxShape.roundRect(
                          BorderRadius.circular(29),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          widget.submitLabel,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      return;
    }

    final initialQuest = widget.initialQuest;
    final exp = expForDifficulty(_difficulty);

    Navigator.of(context).pop(
      (initialQuest ??
              QuestItem(
                id: DateTime.now().microsecondsSinceEpoch.toString(),
                title: '',
                exp: exp,
                difficulty: _difficulty,
                category: _category,
                elapsedSeconds: 0,
                defaultDurationSeconds:
                    defaultQuestDurationSecondsForDifficulty(_difficulty),
                dueDate: _dueDate,
              ))
          .copyWith(
            title: name,
            exp: exp,
            difficulty: _difficulty,
            category: _category,
            elapsedSeconds: initialQuest?.elapsedSeconds ?? 0,
            defaultDurationSeconds: defaultQuestDurationSecondsForDifficulty(
              _difficulty,
            ),
            dueDate: _dueDate,
          ),
    );
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: '마감일 선택',
      cancelText: '취소',
      confirmText: '확인',
    );
    if (!mounted || picked == null) {
      return;
    }

    setState(() => _dueDate = normalizeQuestDueDate(picked));
  }
}

int expForDifficulty(String difficulty) {
  return switch (difficulty) {
    '쉬움' => 30,
    '보통' => 50,
    _ => 100,
  };
}

class _DialogSectionLabel extends StatelessWidget {
  const _DialogSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: _AddQuestScreenState._labelColor,
      ),
    );
  }
}

class _InsetFieldShell extends StatelessWidget {
  const _InsetFieldShell({
    required this.child,
    this.height = 48,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  });

  final Widget child;
  final double height;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return neu.Neumorphic(
      style: neu.NeumorphicStyle(
        depth: -4,
        intensity: 0.8,
        surfaceIntensity: 0.12,
        color: _AddQuestScreenState._dialogColor,
        shadowDarkColor: Color(0x18000000),
        shadowLightColor: Color(0xFFFFFFFF),
        boxShape: neu.NeumorphicBoxShape.roundRect(
          BorderRadius.all(Radius.circular(16)),
        ),
      ),
      padding: padding,
      child: SizedBox(height: height - padding.vertical, child: child),
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 48,
        child: neu.Neumorphic(
          style: neu.NeumorphicStyle(
            depth: selected ? -4 : 6,
            intensity: selected ? 0.8 : 0.95,
            surfaceIntensity: selected ? 0.12 : 0.2,
            color: _AddQuestScreenState._dialogColor,
            shadowDarkColor: selected
                ? const Color(0x18000000)
                : const Color(0x33000000),
            shadowLightColor: Colors.white,
            boxShape: neu.NeumorphicBoxShape.roundRect(
              BorderRadius.circular(14),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B1B1B),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.style,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final _CategoryChipStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = selected ? style.selectedTextColor : style.textColor;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 42,
        child: neu.Neumorphic(
          style: neu.NeumorphicStyle(
            depth: selected ? -3.5 : 5,
            intensity: selected ? 0.8 : 0.95,
            surfaceIntensity: selected ? 0.12 : 0.2,
            color: _AddQuestScreenState._dialogColor,
            shadowDarkColor: selected
                ? const Color(0x18000000)
                : const Color(0x33000000),
            shadowLightColor: Colors.white,
            boxShape: neu.NeumorphicBoxShape.roundRect(
              BorderRadius.circular(12),
            ),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                    color: textColor,
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

class _CategoryChipStyle {
  const _CategoryChipStyle({
    required this.selectedTextColor,
    required this.textColor,
  });

  final Color selectedTextColor;
  final Color textColor;
}

_CategoryChipStyle _categoryChipStyleFor(String category) {
  return switch (category) {
    'home' => const _CategoryChipStyle(
      selectedTextColor: Color(0xFFF79685),
      textColor: Color(0xFFF39482),
    ),
    'study' => const _CategoryChipStyle(
      selectedTextColor: Color(0xFFFFD954),
      textColor: Color(0xFFF4CE46),
    ),
    'work' => const _CategoryChipStyle(
      selectedTextColor: Color(0xFF68B3AD),
      textColor: Color(0xFF63ADA8),
    ),
    'life' => const _CategoryChipStyle(
      selectedTextColor: Color(0xFFA8BFAA),
      textColor: Color(0xFFA7BFA8),
    ),
    _ => const _CategoryChipStyle(
      selectedTextColor: Color(0xFF111111),
      textColor: Color(0xFF6C7480),
    ),
  };
}
