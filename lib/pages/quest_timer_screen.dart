import 'dart:async';

import 'package:ad_focus/models/app_local_data.dart';
import 'package:ad_focus/widgets/common.dart';
import 'package:flutter/material.dart';

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
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _running = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF8EF),
              Color(0xFFF7FBFF),
              Color(0xFFFFF0F3),
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 32),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '퀘스트 진행',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1C2940),
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      widget.onDelete();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('삭제'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFFF7F88),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              RoundedCard(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      widget.quest.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1C2940),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '난이도: ${widget.quest.difficulty} · 보상: +${widget.quest.exp} EXP',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF7E899D),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBFCFF),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _formatDuration(_elapsed),
                            style: const TextStyle(
                              fontSize: 54,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1C2940),
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _running ? '타이머가 진행 중입니다' : '타이머를 시작하세요',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF7E899D),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '인증 사진',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1C2940),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 34),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFD5DBE8)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.upload_outlined, size: 34, color: Color(0xFF8E9AAE)),
                          SizedBox(height: 8),
                          Text(
                            '사진 업로드',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF7E899D),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonal(
                            onPressed: _toggleTimer,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFB8DCFF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Text(_running ? '일시정지' : '시작'),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFF6B4B9),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text('완료'),
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
    );
  }

  void _toggleTimer() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }

    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}
