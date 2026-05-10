import 'dart:async';

import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:start_on/pages/add_quest_screen.dart';
import 'package:start_on/models/app_local_data.dart';
import 'package:start_on/pages/quest_timer/quest_timer_sections.dart';
import 'package:start_on/services/quest_timer_background_service.dart';
import 'package:start_on/storage/quest_image_store.dart';

class QuestTimerScreen extends StatefulWidget {
  const QuestTimerScreen({
    super.key,
    required this.quest,
    required this.userLevel,
    required this.notificationsEnabled,
  });

  final QuestItem quest;
  final int userLevel;
  final bool notificationsEnabled;

  @override
  State<QuestTimerScreen> createState() => _QuestTimerScreenState();
}

class QuestTimerScreenResult {
  const QuestTimerScreenResult({
    required this.quest,
    required this.didPauseTimer,
  });

  final QuestItem quest;
  final bool didPauseTimer;
}

class _QuestTimerScreenState extends State<QuestTimerScreen> {
  static const int _minimumRewardSeconds = 10 * 60;

  // 타이머 제어, 이미지 선택, 인증 이미지 저장을 담당하는 객체들.
  final CountDownController _countDownController = CountDownController();
  final ImagePicker _imagePicker = ImagePicker();
  final QuestImageStore _questImageStore = const QuestImageStore();

  // 화면에서 직접 관리하는 진행 상태.
  final QuestTimerBackgroundService _questTimerService =
      QuestTimerBackgroundService.instance;

  Timer? _localTicker;
  StreamSubscription<QuestTimerSnapshot>? _questTimerTickSubscription;
  late QuestItem _quest;
  XFile? _proofImage;
  int _elapsedSeconds = 0;
  int _timerViewRevision = 0;
  bool _hasStarted = false;
  bool _running = false;
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    _quest = widget.quest;
    _elapsedSeconds = _quest.elapsedSeconds;
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
    final maxDurationSeconds = _quest.defaultDurationSeconds;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        _popWithProgress();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F3F8),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final useLandscapeLayout =
                  constraints.maxWidth > constraints.maxHeight &&
                  constraints.maxWidth >= 640;

              return ListView(
                padding: EdgeInsets.fromLTRB(
                  useLandscapeLayout ? 30 : 22,
                  useLandscapeLayout ? 20 : 16,
                  useLandscapeLayout ? 30 : 22,
                  32,
                ),
                children: [
                  if (!useLandscapeLayout) ...[
                    QuestTimerHeader(
                      onBack: _popWithProgress,
                      onEdit: _editQuest,
                    ),
                    const SizedBox(height: 18),
                  ],
                  // 세로 화면은 기존 흐름을 유지하고, 가로 화면에서만 타이머를 오른쪽에 배치한다.
                  QuestTimerContentCard(
                    useLandscapeLayout: useLandscapeLayout,
                    questSummary: QuestTimerSummary(
                      quest: _quest,
                      userLevel: widget.userLevel,
                      earnedExp: _calculateEarnedExp(),
                      maxDurationSeconds: maxDurationSeconds,
                    ),
                    countdown: QuestTimerCountdown(
                      controller: _countDownController,
                      durationSeconds: maxDurationSeconds,
                      elapsedSeconds: _elapsedSeconds,
                      timerViewRevision: _timerViewRevision,
                      running: _running,
                      onComplete: _handleTimerComplete,
                      onToggleTimer: _toggleTimer,
                      formatDuration: _formatDuration,
                    ),
                    actionButtons: QuestTimerActionButtons(
                      isCompleting: _isCompleting,
                      running: _running,
                      canReset: _elapsedSeconds > 0,
                      canComplete: _elapsedSeconds > 60,
                      onResetTimer: _resetTimer,
                      onToggleTimer: _toggleTimer,
                      onStopTimer: _completeQuest,
                    ),
                    proofSection: QuestTimerProofSection(
                      proofImagePath: _proofImage?.path,
                      isCompleting: _isCompleting,
                      compact: useLandscapeLayout,
                      onPickCamera: () => _pickProofImage(ImageSource.camera),
                      onPickGallery: () => _pickProofImage(ImageSource.gallery),
                      onClearImage: () => setState(() => _proofImage = null),
                    ),
                    categoryTimes: QuestTimerCategoryTimes(
                      category: _quest.category,
                      elapsedSeconds: _elapsedSeconds,
                      compact: useLandscapeLayout,
                      formatDuration: _formatDuration,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _handleTimerComplete() {
    if (!mounted || _isCompleting) {
      return;
    }
    unawaited(_completeQuest());
  }

  void _toggleTimer() {
    unawaited(_toggleTimerAsync());
  }

  void _resetTimer() {
    unawaited(_resetTimerAsync());
  }

  Future<void> _toggleTimerAsync() async {
    // 진행 중이면 일시정지, 끝까지 찼으면 초기화 후 재시작, 그 외에는 시작/재개.
    if (_running) {
      if (_elapsedSeconds < _quest.defaultDurationSeconds) {
        _countDownController.pause();
      }
      if (widget.notificationsEnabled) {
        await _questTimerService.pauseTimer(
          questId: _quest.id,
          questTitle: _quest.title,
          elapsedSeconds: _elapsedSeconds,
          defaultDurationSeconds: _quest.defaultDurationSeconds,
        );
      } else {
        _stopLocalTicker();
      }
      if (!mounted) {
        return;
      }
      setState(() => _running = false);
      return;
    }

    if (_elapsedSeconds >= _quest.defaultDurationSeconds) {
      if (widget.notificationsEnabled) {
        await _questTimerService.startOrResumeTimer(
          questId: _quest.id,
          questTitle: _quest.title,
          elapsedSeconds: _elapsedSeconds,
          defaultDurationSeconds: _quest.defaultDurationSeconds,
        );
      } else {
        _startLocalTicker();
      }
      if (!mounted) {
        return;
      }
      setState(() => _running = true);
      return;
    }

    if (_hasStarted) {
      _countDownController.resume();
    } else {
      _countDownController.start();
      _hasStarted = true;
    }

    if (widget.notificationsEnabled) {
      await _questTimerService.startOrResumeTimer(
        questId: _quest.id,
        questTitle: _quest.title,
        elapsedSeconds: _elapsedSeconds,
        defaultDurationSeconds: _quest.defaultDurationSeconds,
      );
    } else {
      _startLocalTicker();
    }
    if (!mounted) {
      return;
    }
    setState(() => _running = true);
  }

  Future<void> _resetTimerAsync() async {
    if (_running && _elapsedSeconds < _quest.defaultDurationSeconds) {
      _countDownController.pause();
    }

    _stopLocalTicker();

    if (widget.notificationsEnabled) {
      await _questTimerService.stopTimer();
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _elapsedSeconds = 0;
      _hasStarted = false;
      _running = false;
      _timerViewRevision += 1;
    });
  }

  Future<void> _editQuest() async {
    final updatedQuest = await Navigator.of(context).push<QuestItem>(
      MaterialPageRoute<QuestItem>(
        builder: (context) => AddQuestScreen(
          initialQuest: _quest.copyWith(elapsedSeconds: _elapsedSeconds),
          title: '퀘스트 수정',
          submitLabel: '적용',
        ),
      ),
    );

    if (!mounted || updatedQuest == null) {
      return;
    }

    final questWithProgress = updatedQuest.copyWith(
      elapsedSeconds: _elapsedSeconds,
    );

    setState(() {
      _quest = questWithProgress;
      _timerViewRevision += 1;
    });

    if (_running && widget.notificationsEnabled) {
      await _questTimerService.startOrResumeTimer(
        questId: _quest.id,
        questTitle: _quest.title,
        elapsedSeconds: _elapsedSeconds,
        defaultDurationSeconds: _quest.defaultDurationSeconds,
      );
    }

    if (_running && _elapsedSeconds < _quest.defaultDurationSeconds) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _countDownController.start();
      });
    }
  }

  Future<void> _pickProofImage(ImageSource source) async {
    final image = await _imagePicker.pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 1800,
    );

    if (image == null || !mounted) {
      return;
    }

    setState(() => _proofImage = image);
  }

  Future<void> _completeQuest() async {
    // 완료 시 현재 경과 시간과 인증 사진 경로를 기록 화면으로 전달한다.
    if (_running) {
      _stopLocalTicker();
      if (widget.notificationsEnabled) {
        await _questTimerService.stopTimer();
      }
      if (!mounted) {
        return;
      }
      setState(() => _running = false);
    } else if (widget.notificationsEnabled) {
      await _questTimerService.stopTimer();
    }

    setState(() => _isCompleting = true);

    final completedAt = DateTime.now();
    String? proofImagePath;
    if (_proofImage != null) {
      proofImagePath = await _questImageStore.savePickedImage(
        _proofImage!,
        questId: _quest.id,
        completedAt: completedAt,
      );
    }

    if (!mounted) {
      return;
    }

    final earnedExp = _calculateEarnedExp();

    Navigator.of(context).pop(
      CompletedQuestRecord(
        questId: _quest.id,
        title: _quest.title,
        difficulty: _quest.difficulty,
        category: _quest.category,
        earnedExp: earnedExp,
        completedAt: completedAt.toIso8601String(),
        elapsedSeconds: _elapsedSeconds,
        proofImagePath: proofImagePath,
      ),
    );
  }

  int _calculateEarnedExp() {
    if (_elapsedSeconds < _minimumRewardSeconds) {
      return 0;
    }
    return _elapsedSeconds ~/ 60;
  }

  void _popWithProgress() {
    unawaited(_popWithProgressAsync());
  }

  Future<void> _popWithProgressAsync() async {
    var didPauseTimer = false;

    if (_running) {
      if (_elapsedSeconds < _quest.defaultDurationSeconds) {
        _countDownController.pause();
      }
      if (widget.notificationsEnabled) {
        await _questTimerService.pauseTimer(
          questId: _quest.id,
          questTitle: _quest.title,
          elapsedSeconds: _elapsedSeconds,
          defaultDurationSeconds: _quest.defaultDurationSeconds,
        );
      } else {
        _stopLocalTicker();
      }
      if (!mounted) {
        return;
      }
      setState(() => _running = false);
      didPauseTimer = true;
    }

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(
      QuestTimerScreenResult(
        quest: _quest.copyWith(elapsedSeconds: _elapsedSeconds),
        didPauseTimer: didPauseTimer,
      ),
    );
  }

  void _startLocalTicker() {
    _localTicker?.cancel();
    _localTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _elapsedSeconds += 1;
      });
    });
  }

  void _stopLocalTicker() {
    _localTicker?.cancel();
    _localTicker = null;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  void _listenToBackgroundTimer() {
    _questTimerTickSubscription = _questTimerService.timerTicks.listen((tick) {
      if (!mounted || tick.questId != _quest.id) {
        return;
      }

      setState(() {
        _elapsedSeconds = tick.elapsedSeconds;
        _running = tick.isRunning;
        _hasStarted = tick.elapsedSeconds > 0 || tick.isRunning;
      });
    });

    unawaited(_syncBackgroundTimerState());
  }

  Future<void> _syncBackgroundTimerState() async {
    final snapshot = await _questTimerService.currentState();
    if (!mounted || snapshot == null || snapshot.questId != _quest.id) {
      return;
    }

    final shouldStartCountdown =
        snapshot.isRunning &&
        snapshot.elapsedSeconds < _quest.defaultDurationSeconds;

    setState(() {
      _elapsedSeconds = snapshot.elapsedSeconds;
      _running = snapshot.isRunning;
      _hasStarted = snapshot.elapsedSeconds > 0 || snapshot.isRunning;
    });

    if (shouldStartCountdown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _countDownController.start();
      });
    }
  }
}
