import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart' as neu;

class QuestTimerActionButtons extends StatelessWidget {
  const QuestTimerActionButtons({
    super.key,
    required this.isCompleting,
    required this.running,
    required this.canReset,
    required this.canComplete,
    required this.onResetTimer,
    required this.onToggleTimer,
    required this.onStopTimer,
  });

  final bool isCompleting;
  final bool running;
  final bool canReset;
  final bool canComplete;
  final VoidCallback onResetTimer;
  final VoidCallback onToggleTimer;
  final VoidCallback onStopTimer;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _QuestTimerCircleButton(
          icon: Icons.replay_rounded,
          backgroundColor: const Color(0xFFF1F3F8),
          iconColor: Colors.black,
          size: 42,
          iconSize: 18,
          onTap: isCompleting || !canReset ? null : onResetTimer,
        ),
        const SizedBox(width: 46),
        _QuestTimerCircleButton(
          icon: Icons.check_rounded,
          backgroundColor: canComplete
              ? const Color(0xFFFF727A)
              : const Color(0xFFBFC4CF),
          iconColor: Colors.white,
          size: 56,
          iconSize: 28,
          onTap: isCompleting || !canComplete ? null : onStopTimer,
          loading: isCompleting,
          disabledOpacity: 1,
        ),
        const SizedBox(width: 46),
        _QuestTimerCircleButton(
          icon: running ? Icons.pause_rounded : Icons.play_arrow_rounded,
          backgroundColor: const Color(0xFFF1F3F8),
          iconColor: Colors.black,
          size: 42,
          iconSize: running ? 19 : 23,
          onTap: isCompleting ? null : onToggleTimer,
        ),
      ],
    );
  }
}

class _QuestTimerCircleButton extends StatelessWidget {
  const _QuestTimerCircleButton({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.onTap,
    required this.size,
    required this.iconSize,
    this.loading = false,
    this.disabledOpacity = 0.42,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final bool loading;
  final double disabledOpacity;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !loading;

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: enabled || loading ? 1 : disabledOpacity,
        child: neu.Neumorphic(
          style: neu.NeumorphicStyle(
            depth: 7,
            intensity: 0.9,
            surfaceIntensity: 0.22,
            color: backgroundColor,
            shadowLightColor: Colors.white,
            shadowDarkColor: const Color(0xFFD0D7E5),
            boxShape: const neu.NeumorphicBoxShape.circle(),
          ),
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: loading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.6,
                        color: iconColor,
                      ),
                    )
                  : Icon(icon, color: iconColor, size: iconSize),
            ),
          ),
        ),
      ),
    );
  }
}
