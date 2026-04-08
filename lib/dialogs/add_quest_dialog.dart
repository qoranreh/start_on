import 'package:start_on/models/app_local_data.dart';
import 'package:flutter/material.dart';
//퀘스트 추가dialog
class AddQuestDialog extends StatefulWidget {
  const AddQuestDialog({super.key});

  @override
  State<AddQuestDialog> createState() => _AddQuestDialogState();
}

class _AddQuestDialogState extends State<AddQuestDialog> {
  final TextEditingController _controller = TextEditingController();

  String _difficulty = '보통';
  String _category = '지능';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(28, 26, 28, 28 + viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '새 퀘스트 추가',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1C2940),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF95A0B4)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                '퀘스트 이름',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF33415C),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: '예: 아침 운동하기',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: Color(0xFFFF9EA5), width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: Color(0xFFFF7F88), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                '난이도',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF33415C),
                ),
              ),
              const SizedBox(height: 12),
              ChoiceRow(
                values: const ['쉬움', '보통', '어려움'],
                selected: _difficulty,
                selectedColor: const Color(0xFFFF8B93),
                onSelected: (value) => setState(() => _difficulty = value),
              ),
              const SizedBox(height: 18),
              const Text(
                '카테고리',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF33415C),
                ),
              ),
              const SizedBox(height: 12),
              ChoiceRow(
                values: const ['정돈', '지능', '체력'],
                selected: _category,
                selectedColor: const Color(0xFFAED7FF),
                onSelected: (value) => setState(() => _category = value),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F3F8),
                        foregroundColor: const Color(0xFF667085),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFF6B4B9),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text('추가'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      return;
    }

    final exp = switch (_difficulty) {
      '쉬움' => 30,
      '보통' => 50,
      _ => 100,
    };

    Navigator.of(context).pop(
      QuestItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: name,
        exp: exp,
        difficulty: _difficulty,
        category: _category,
      ),
    );
  }
}

class ChoiceRow extends StatelessWidget {
  const ChoiceRow({
    required this.values,
    required this.selected,
    required this.selectedColor,
    required this.onSelected,
    super.key,
  });

  final List<String> values;
  final String selected;
  final Color selectedColor;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < values.length; i++) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => onSelected(values[i]),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: values[i] == selected ? selectedColor : const Color(0xFFF1F3F8),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: values[i] == selected
                      ? [
                          BoxShadow(
                            color: selectedColor.withValues(alpha: 0.25),
                            blurRadius: 14,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    values[i],
                    style: TextStyle(
                      color: values[i] == selected ? Colors.white : const Color(0xFF667085),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (i != values.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}
