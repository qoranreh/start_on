import 'dart:async';

import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:start_on/models/app_local_data.dart';
import 'package:start_on/pages/quest_timer/quest_timer_sections.dart';
import 'package:start_on/storage/quest_image_store.dart';

class QuestTimerScreen extends StatefulWidget {
  const QuestTimerScreen({
    super.key,
    required this.quest,
    required this.onDelete,
  });

  final QuestItem quest;
  final VoidCallback onDelete;

  @override
  State<QuestTimerScreen> createState() => _QuestTimerScreenState();
}

class _QuestTimerScreenState extends State<QuestTimerScreen> {
  static const int _defaultTimerSeconds = 60 * 60;
  static const int _minimumRewardSeconds = 10 * 60;

  // 타이머 제어, 이미지 선택, 인증 이미지 저장을 담당하는 객체들.
  final CountDownController _countDownController = CountDownController();
  final ImagePicker _imagePicker = ImagePicker();
  final QuestImageStore _questImageStore = const QuestImageStore();

  // 화면에서 직접 관리하는 진행 상태.
  Timer? _ticker;
  XFile? _proofImage;
  int _elapsedSeconds = 0;
  bool _hasStarted = false;
  bool _running = false;
  bool _isCompleting = false;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 32),
          children: [
            QuestTimerHeader(
              onBack: () => Navigator.of(context).pop(),
              onDelete: () {
                widget.onDelete();
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 18),
            // 메인 카드 안에서 퀘스트 정보, 타이머, 액션, 인증 사진 흐름을 순서대로 보여준다.
            QuestTimerContentCard(
              questSummary: QuestTimerSummary(
                quest: widget.quest,
                earnedExp: _calculateEarnedExp(),
              ),
              countdown: QuestTimerCountdown(
                controller: _countDownController,
                durationSeconds: _defaultTimerSeconds,
                elapsedSeconds: _elapsedSeconds,
                running: _running,
                onComplete: _handleTimerComplete,
                formatDuration: _formatDuration,
              ),
              actionButtons: QuestTimerActionButtons(
                isCompleting: _isCompleting,
                running: _running,
                onToggleTimer: _toggleTimer,
                onCompleteQuest: _completeQuest,
              ),
              proofSection: QuestTimerProofSection(
                proofImagePath: _proofImage?.path,
                isCompleting: _isCompleting,
                onPickCamera: () => _pickProofImage(ImageSource.camera),
                onPickGallery: () => _pickProofImage(ImageSource.gallery),
                onClearImage: () => setState(() => _proofImage = null),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTimerComplete() {
    if (!mounted) {
      return;
    }
    _stopLocalTicker();
    setState(() {
      _running = false;
      _elapsedSeconds = _defaultTimerSeconds;
    });
  }

  void _toggleTimer() {
    // 진행 중이면 일시정지, 끝까지 찼으면 초기화 후 재시작, 그 외에는 시작/재개.
    if (_running) {
      _countDownController.pause();
      _stopLocalTicker();
      setState(() => _running = false);
      return;
    }

    if (_elapsedSeconds == _defaultTimerSeconds) {
      _stopLocalTicker();
      setState(() {
        _elapsedSeconds = 0;
        _hasStarted = false;
        _running = true;
      });
      _countDownController.restart(duration: _defaultTimerSeconds);
      _hasStarted = true;
      _startLocalTicker();
      return;
    }

    if (_hasStarted) {
      _countDownController.resume();
    } else {
      _countDownController.start();
      _hasStarted = true;
    }

    _startLocalTicker();
    setState(() => _running = true);
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
      _toggleTimer();
    }

    setState(() => _isCompleting = true);

    final completedAt = DateTime.now();
    String? proofImagePath;
    if (_proofImage != null) {
      proofImagePath = await _questImageStore.savePickedImage(
        _proofImage!,
        questId: widget.quest.id,
        completedAt: completedAt,
      );
    }

    if (!mounted) {
      return;
    }

    final earnedExp = _calculateEarnedExp();

    Navigator.of(context).pop(
      CompletedQuestRecord(
        questId: widget.quest.id,
        title: widget.quest.title,
        difficulty: widget.quest.difficulty,
        category: widget.quest.category,
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

  void _startLocalTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        if (_elapsedSeconds < _defaultTimerSeconds) {
          _elapsedSeconds += 1;
        }
      });
    });
  }

  void _stopLocalTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}
