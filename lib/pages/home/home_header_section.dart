import 'package:flutter/material.dart';
import 'package:start_on/pages/home/home_top_icon_button.dart';

// 오늘 인사말과 빠른 액션 버튼을 보여주는 헤더 영역입니다.
class HomeHeaderSection extends StatelessWidget {
  const HomeHeaderSection({
    super.key,
    required this.todayLabel,
    required this.credits,
    required this.showCreditAmount,
    required this.onOpenSettings,
  });

  final String todayLabel;
  final int credits;
  final bool showCreditAmount;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFF8FBFF),
            border: Border.all(color: const Color(0xFFE3EAF4), width: 0.5),
          ),
          child: const Icon(
            Icons.person_outline_rounded,
            color: Color(0xFF9AABC1),
            size: 26,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '좋은 아침이에요 :)',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF000000),
                ),
              ),

              const SizedBox(height: 2),
              const Text(
                '사용자 님',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1C2940),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: showCreditAmount ? 12 : 0,
            vertical: showCreditAmount ? 9 : 0,
          ),
          decoration: BoxDecoration(
            color: showCreditAmount
                ? const Color(0xFFFFE48A)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: showCreditAmount
                ? [
                    BoxShadow(
                      color: const Color(0xFFFFE48A).withValues(alpha: 0.24),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : const [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.monetization_on_outlined,
                size: 16,
                color: Color(0xFF745C00),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SizeTransition(
                      sizeFactor: animation,
                      axis: Axis.horizontal,
                      axisAlignment: -1,
                      child: child,
                    ),
                  );
                },
                child: showCreditAmount
                    ? Padding(
                        key: const ValueKey('credit-text'),
                        padding: const EdgeInsets.only(left: 5),
                        child: Text(
                          '$credits',
                          style: const TextStyle(
                            color: Color(0xFF473200),
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : const SizedBox(key: ValueKey('credit-empty')),
              ),
              if (!showCreditAmount) const SizedBox(width: 6, height: 16),
            ],
          ),
        ),
        const SizedBox(width: 10),
        HomeTopIconButton(icon: Icons.settings_outlined, onTap: onOpenSettings),
      ],
    );
  }
}
