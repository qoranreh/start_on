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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFE3E9F6),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD5DAE5).withValues(alpha: 0.7),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.person_rounded,
            color: Color(0xFFF6B42D),
            size: 29,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '좋은 아침이에요 :)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF24262C),
                ),
              ),
              const SizedBox(height: 1),
              const Text(
                '사용자 님',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF07080A),
                  height: 1.05,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: showCreditAmount ? 8 : 0,
            vertical: showCreditAmount ? 5 : 0,
          ),
          decoration: BoxDecoration(
            color: showCreditAmount
                ? Colors.white.withValues(alpha: 0.92)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            boxShadow: showCreditAmount
                ? [
                    BoxShadow(
                      color: const Color(0xFFD8DEE9).withValues(alpha: 0.8),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : const [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                size: 13,
                color: Color(0xFFFF4B4B),
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
                          '$credits위',
                          style: const TextStyle(
                            color: Color(0xFF111318),
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      )
                    : const SizedBox(key: ValueKey('credit-empty')),
              ),
              if (!showCreditAmount) const SizedBox(width: 6, height: 16),
            ],
          ),
        ),
        const SizedBox(width: 12),
        HomeTopIconButton(icon: Icons.notifications_none_rounded, onTap: () {}),
        const SizedBox(width: 12),
        HomeTopIconButton(icon: Icons.settings_outlined, onTap: onOpenSettings),
      ],
    );
  }
}
