import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart' as neu;

class QuestTimerCountdown extends StatelessWidget {
  const QuestTimerCountdown({
    super.key,
    required this.controller,
    required this.durationSeconds,
    required this.elapsedSeconds,
    required this.timerViewRevision,
    required this.running,
    required this.onComplete,
    required this.onToggleTimer,
    required this.formatDuration,
  });

  final CountDownController controller;
  final int durationSeconds;
  final int elapsedSeconds;
  final int timerViewRevision;
  final bool running;
  final VoidCallback onComplete;
  final VoidCallback onToggleTimer;
  final String Function(Duration duration) formatDuration;

  @override
  Widget build(BuildContext context) {
    final clampedElapsedSeconds = elapsedSeconds > durationSeconds
        ? durationSeconds
        : elapsedSeconds;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            CircularCountDownTimer(
              key: ValueKey(
                '${clampedElapsedSeconds == durationSeconds}:$timerViewRevision',
              ),
              duration: durationSeconds,
              initialDuration: clampedElapsedSeconds,
              controller: controller,
              width: 190,
              height: 190,
              autoStart: false,
              isReverse: false,
              isReverseAnimation: false,
              strokeWidth: 19,
              strokeCap: StrokeCap.round,
              ringColor: const Color(0xFFE8EDF6),
              fillColor: const Color(0xFF8177FF),
              backgroundColor: Colors.transparent,
              isTimerTextShown: false,
              onComplete: onComplete,
              timeFormatterFunction: (defaultFormatterFunction, duration) {
                return formatDuration(duration);
              },
            ),
            _QuestTimerCore(
              elapsedSeconds: elapsedSeconds,
              running: running,
              onToggleTimer: onToggleTimer,
            ),
          ],
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _QuestTimerCore extends StatelessWidget {
  const _QuestTimerCore({
    required this.elapsedSeconds,
    required this.running,
    required this.onToggleTimer,
  });

  final int elapsedSeconds;
  final bool running;
  final VoidCallback onToggleTimer;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: running ? null : onToggleTimer,
      child: neu.Neumorphic(
        style: const neu.NeumorphicStyle(
          depth: 5,
          intensity: 0.88,
          surfaceIntensity: 0.18,
          color: Color(0xFFF1F3F8),
          shadowLightColor: Colors.white,
          shadowDarkColor: Color(0xFFD0D7E5),
          boxShape: neu.NeumorphicBoxShape.circle(),
        ),
        child: SizedBox(
          width: 82,
          height: 82,
          child: Center(
            child: running
                ? Text(
                    _formatCenterDuration(elapsedSeconds),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  )
                : const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.black,
                    size: 42,
                  ),
          ),
        ),
      ),
    );
  }
}

String _formatCenterDuration(int seconds) {
  final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
  final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
  return '$minutes:$remainingSeconds';
}
