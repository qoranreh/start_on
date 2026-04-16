import 'package:flutter/material.dart';

// 카테고리 한 칸의 아이콘과 이름을 표현하는 카드입니다.
class HomeCategoryCard extends StatelessWidget {
  const HomeCategoryCard({
    super.key,
    required this.title,
    required this.completedCount,
    required this.pendingCount,
    required this.onTap,
    required this.onAddTap,
    required this.icon,
    required this.accentColor,
    required this.backgroundColor,
  });

  final String title;
  final int completedCount;
  final int pendingCount;
  final VoidCallback onTap;
  final VoidCallback onAddTap;
  final IconData icon;
  final Color accentColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          // Keep this category-colored shadow setup unchanged unless explicitly requested.
          BoxShadow(
            color: accentColor.withValues(alpha: 0.14),
            blurRadius: 18,
            spreadRadius: -2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: accentColor.withValues(alpha: 0.09),
            blurRadius: 28,
            spreadRadius: -6,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: accentColor.withValues(alpha: 0.18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                    const Spacer(),
                    Transform.translate(
                      offset: const Offset(4, -4),
                      child: IconButton(
                        onPressed: onAddTap,
                        icon: Icon(
                          Icons.add_rounded,
                          color: accentColor,
                          size: 18,
                        ),
                        splashRadius: 15,
                        constraints: const BoxConstraints.tightFor(
                          width: 26,
                          height: 26,
                        ),
                        padding: EdgeInsets.zero,
                        visualDensity: const VisualDensity(
                          horizontal: -4,
                          vertical: -4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF24324A),
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$completedCount/$pendingCount',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
