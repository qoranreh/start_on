import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 오늘 진행할 퀘스트 목록 제목입니다.
class HomeQuestSectionHeader extends StatefulWidget {
  const HomeQuestSectionHeader({
    super.key,
    required this.onOpenAutoAdd,
    required this.questCount,
  });

  final VoidCallback onOpenAutoAdd;
  final int questCount;

  @override
  State<HomeQuestSectionHeader> createState() => _HomeQuestSectionHeaderState();
}

class _HomeQuestSectionHeaderState extends State<HomeQuestSectionHeader>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _animationLockDateKey = 'home.auto_add_animation_lock_date';

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;
  Timer? _startTimer;
  Timer? _repeatTimer;
  String? _lockedDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _shakeAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0, end: -0.12), weight: 1),
          TweenSequenceItem(tween: Tween(begin: -0.12, end: 0.12), weight: 1.3),
          TweenSequenceItem(tween: Tween(begin: 0.12, end: -0.1), weight: 1.1),
          TweenSequenceItem(tween: Tween(begin: -0.1, end: 0.08), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 0.08, end: -0.05), weight: 0.9),
          TweenSequenceItem(tween: Tween(begin: -0.05, end: 0), weight: 1.1),
        ]).animate(
          CurvedAnimation(
            parent: _shakeController,
            curve: Curves.easeInOutCubic,
          ),
        );
    unawaited(_refreshReminderState());
  }

  @override
  void didUpdateWidget(covariant HomeQuestSectionHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.questCount != widget.questCount) {
      unawaited(_refreshReminderState());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _startTimer?.cancel();
    _repeatTimer?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshReminderState());
    }
  }

  Future<void> _refreshReminderState() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = _dateKey(DateTime.now());
    var lockedDate = prefs.getString(_animationLockDateKey);

    if (widget.questCount > 3) {
      if (lockedDate != todayKey) {
        await prefs.setString(_animationLockDateKey, todayKey);
      }
      lockedDate = todayKey;
    }

    if (!mounted) {
      return;
    }

    _lockedDate = lockedDate;
    _configureShakeSchedule();
  }

  void _configureShakeSchedule() {
    _startTimer?.cancel();
    _repeatTimer?.cancel();

    if (widget.questCount > 3 || _lockedDate == _dateKey(DateTime.now())) {
      return;
    }

    _startTimer = Timer(const Duration(milliseconds: 550), _playShake);
    _repeatTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_lockedDate == _dateKey(DateTime.now())) {
        _repeatTimer?.cancel();
        return;
      }
      _playShake();
    });
  }

  void _playShake() {
    if (!mounted) {
      return;
    }

    _shakeController.forward(from: 0);
  }

  String _dateKey(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '${dateTime.year}-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            '오늘의 퀘스트',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              color: Color(0xFF050608),
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _shakeAnimation.value,
              alignment: Alignment.center,
              child: Transform.translate(
                offset: Offset(
                  math.sin(_shakeController.value * math.pi * 8) * 1.6,
                  0,
                ),
                child: child,
              ),
            );
          },
          child: GestureDetector(
            onTap: widget.onOpenAutoAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'view all',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8A8E98),
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.auto_fix_high_rounded,
                    color: Color(0xFF8A8E98),
                    size: 15,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
