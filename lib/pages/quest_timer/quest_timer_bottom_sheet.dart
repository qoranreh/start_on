import 'dart:async';

import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart' as neu;
import 'package:start_on/models/app_local_data.dart';
import 'package:start_on/services/quest_timer_background_service.dart';

const double _bottomSheetControlWidth = 128;
const Color _bottomSheetBackgroundColor = Color(0xFFF1F3F8);

class QuestTimerBottomSheet extends StatefulWidget {
  const QuestTimerBottomSheet({
    super.key,
    required this.quest,
    required this.notificationsEnabled,
    required this.onQuestChanged,
  });

  final QuestItem quest;
  final bool notificationsEnabled;
  final ValueChanged<QuestItem> onQuestChanged;

  @override
  State<QuestTimerBottomSheet> createState() => _QuestTimerBottomSheetState();
}

class _QuestTimerBottomSheetState extends State<QuestTimerBottomSheet> {
  final CountDownController _countDownController = CountDownController();
  final QuestTimerBackgroundService _questTimerService =
      QuestTimerBackgroundService.instance;

  Timer? _localTicker;
  StreamSubscription<QuestTimerSnapshot>? _questTimerTickSubscription;
  late int _elapsedSeconds;
  int _timerViewRevision = 0;
  bool _hasStarted = false;
  bool _running = false;

  int get _durationSeconds => widget.quest.defaultDurationSeconds;

  @override
  void initState() {
    super.initState();
    _elapsedSeconds = widget.quest.elapsedSeconds;
    if (widget.notificationsEnabled) {
      _listenToBackgroundTimer();
    }
  }

  @override
  void dispose() {
    _localTicker?.cancel();
    _questTimerTickSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clampedElapsedSeconds = _elapsedSeconds > _durationSeconds
        ? _durationSeconds
        : _elapsedSeconds;

    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _bottomSheetBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.5),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 12, 28, 20),
            child: Column(
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC9D0DE),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '당장 일을 시작하세요!',
                              style: TextStyle(
                                color: Color(0xFF8177FF),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: _bottomSheetControlWidth,
                              height: 68,
                              child: neu.Neumorphic(
                                style: neu.NeumorphicStyle(
                                  depth: 6,
                                  intensity: 0.9,
                                  surfaceIntensity: 0.2,
                                  color: _bottomSheetBackgroundColor,
                                  shadowLightColor: Colors.white,
                                  shadowDarkColor: const Color(0xFFD0D7E5),
                                  boxShape: neu.NeumorphicBoxShape.roundRect(
                                    BorderRadius.circular(16),
                                  ),
                                ),
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    child: Text(
                                      widget.quest.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFF1C2940),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            _StartButton(
                              running: _running,
                              onTap: _toggleTimer,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 18),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularCountDownTimer(
                            key: ValueKey(
                              '${clampedElapsedSeconds == _durationSeconds}:$_timerViewRevision',
                            ),
                            duration: _durationSeconds,
                            initialDuration: clampedElapsedSeconds,
                            controller: _countDownController,
                            width: 118,
                            height: 118,
                            autoStart: false,
                            isReverse: false,
                            isReverseAnimation: false,
                            strokeWidth: 11,
                            strokeCap: StrokeCap.round,
                            ringColor: const Color(0xFFE8EDF6),
                            fillColor: const Color(0xFF8177FF),
                            backgroundColor: Colors.transparent,
                            isTimerTextShown: false,
                            onComplete: _pauseTimer,
                          ),
                          Text(
                            _formatDuration(Duration(seconds: _elapsedSeconds)),
                            style: const TextStyle(
                              color: Color(0xFF111318),
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggleTimer() {
    unawaited(_toggleTimerAsync());
  }

  Future<void> _toggleTimerAsync() async {
    if (_running) {
      await _pauseTimer();
      return;
    }

    if (_elapsedSeconds >= _durationSeconds) {
      setState(() {
        _elapsedSeconds = 0;
        _hasStarted = false;
        _timerViewRevision += 1;
      });
      _notifyQuestChanged();
    }

    if (_hasStarted) {
      _countDownController.resume();
    } else {
      _countDownController.start();
      _hasStarted = true;
    }

    if (widget.notificationsEnabled) {
      await _questTimerService.startOrResumeTimer(
        questId: widget.quest.id,
        questTitle: widget.quest.title,
        elapsedSeconds: _elapsedSeconds,
        defaultDurationSeconds: _durationSeconds,
      );
    } else {
      _startLocalTicker();
    }

    if (!mounted) {
      return;
    }
    setState(() => _running = true);
  }

  Future<void> _pauseTimer() async {
    if (_elapsedSeconds < _durationSeconds) {
      _countDownController.pause();
    }

    if (widget.notificationsEnabled) {
      await _questTimerService.pauseTimer(
        questId: widget.quest.id,
        questTitle: widget.quest.title,
        elapsedSeconds: _elapsedSeconds,
        defaultDurationSeconds: _durationSeconds,
      );
    } else {
      _stopLocalTicker();
    }

    if (!mounted) {
      return;
    }

    setState(() => _running = false);
    _notifyQuestChanged();
  }

  void _startLocalTicker() {
    _localTicker?.cancel();
    _localTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_running) {
        return;
      }

      final nextElapsedSeconds = (_elapsedSeconds + 1).clamp(
        0,
        _durationSeconds,
      );
      setState(() => _elapsedSeconds = nextElapsedSeconds);
      _notifyQuestChanged();

      if (nextElapsedSeconds >= _durationSeconds) {
        unawaited(_pauseTimer());
      }
    });
  }

  void _stopLocalTicker() {
    _localTicker?.cancel();
    _localTicker = null;
  }

  void _listenToBackgroundTimer() {
    _questTimerTickSubscription = _questTimerService.timerTicks.listen((tick) {
      if (!mounted || tick.questId != widget.quest.id) {
        return;
      }

      setState(() {
        _elapsedSeconds = tick.elapsedSeconds.clamp(0, _durationSeconds);
        _running = tick.isRunning;
        _hasStarted = tick.elapsedSeconds > 0 || tick.isRunning;
      });
      _notifyQuestChanged();
    });
  }

  void _notifyQuestChanged() {
    widget.onQuestChanged(
      widget.quest.copyWith(elapsedSeconds: _elapsedSeconds),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({required this.running, required this.onTap});

  final bool running;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: neu.Neumorphic(
        style: neu.NeumorphicStyle(
          depth: 7,
          intensity: 0.9,
          surfaceIntensity: 0.22,
          color: const Color(0xFFF1F3F8),
          shadowLightColor: Colors.white,
          shadowDarkColor: const Color(0xFFD0D7E5),
          boxShape: neu.NeumorphicBoxShape.roundRect(BorderRadius.circular(18)),
        ),
        child: SizedBox(
          width: _bottomSheetControlWidth,
          height: 40,
          child: Center(
            child: Icon(
              running ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.black,
              size: running ? 21 : 26,
            ),
          ),
        ),
      ),
    );
  }
}
