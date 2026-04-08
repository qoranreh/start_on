import 'dart:async';
import 'dart:io';

import 'package:start_on/models/app_local_data.dart';
import 'package:start_on/storage/quest_image_store.dart';
import 'package:start_on/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
//퀘스트 눌렀을떄 나오는 화면 (타이머화면)
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
  final ImagePicker _imagePicker = ImagePicker();
  final QuestImageStore _questImageStore = const QuestImageStore();
  XFile? _proofImage;
  bool _isCompleting = false;

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
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isCompleting ? null : () => _pickProofImage(ImageSource.camera),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF667085),
                              side: const BorderSide(color: Color(0xFFD5DBE8)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.photo_camera_outlined),
                            label: const Text('카메라'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isCompleting ? null : () => _pickProofImage(ImageSource.gallery),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF667085),
                              side: const BorderSide(color: Color(0xFFD5DBE8)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('갤러리'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_proofImage == null)
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
                              '카메라 촬영 또는 갤러리에서 선택',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF7E899D),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.file(
                              File(_proofImage!.path),
                              width: double.infinity,
                              height: 220,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: IconButton.filledTonal(
                              onPressed: _isCompleting ? null : () => setState(() => _proofImage = null),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withValues(alpha: 0.88),
                                foregroundColor: const Color(0xFF667085),
                              ),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonal(
                            onPressed: _isCompleting ? null : _toggleTimer,
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
                            onPressed: _isCompleting ? null : _completeQuest,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFF6B4B9),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: _isCompleting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('완료'),
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

    Navigator.of(context).pop(
      CompletedQuestRecord(
        questId: widget.quest.id,
        title: widget.quest.title,
        difficulty: widget.quest.difficulty,
        category: widget.quest.category,
        earnedExp: widget.quest.exp,
        completedAt: completedAt.toIso8601String(),
        elapsedSeconds: _elapsed.inSeconds,
        proofImagePath: proofImagePath,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}
