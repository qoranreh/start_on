import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart' as neu;
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
        SizedBox(
          width: 48,
          height: 48,
          child: neu.Neumorphic(
            style: neu.NeumorphicStyle(
              depth: -5,
              intensity: 0.86,
              surfaceIntensity: 0.26,
              color: const Color(0xFFE3E9F6),
              shadowLightColor: Colors.white,
              shadowDarkColor: const Color(0xFFC9D0DE),
              boxShape: const neu.NeumorphicBoxShape.circle(),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Color(0xFFF6B42D),
              size: 29,
            ),
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
          child: neu.Neumorphic(
            style: neu.NeumorphicStyle(
              depth: showCreditAmount ? -3 : 0,
              intensity: 0.82,
              surfaceIntensity: 0.22,
              color: const Color(0xFFF1F3F8),
              shadowLightColor: Colors.white,
              shadowDarkColor: const Color(0xFFD0D7E5),
              boxShape: neu.NeumorphicBoxShape.roundRect(
                BorderRadius.circular(7),
              ),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: showCreditAmount ? 8 : 0,
              vertical: showCreditAmount ? 5 : 0,
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
        ),
        const SizedBox(width: 12),
        HomeTopIconButton(icon: Icons.notifications_none_rounded, onTap: () {}),
        const SizedBox(width: 12),
        HomeTopIconButton(icon: Icons.settings_outlined, onTap: onOpenSettings),
      ],
    );
  }
}
