import 'dart:async';

import 'package:start_on/dialogs/add_quest_dialog.dart';
import 'package:start_on/models/app_local_data.dart';
import 'package:start_on/pages/dungeon_screen.dart';
import 'package:start_on/pages/home_screen.dart';
import 'package:start_on/pages/quest_timer_screen.dart';
import 'package:start_on/pages/record_screen.dart';
import 'package:start_on/pages/settings_screen.dart';
import 'package:start_on/pages/shop_screen.dart';
import 'package:start_on/storage/local_data_store.dart';
import 'package:start_on/widgets/common.dart';
import 'package:start_on/widgets/quest_completion_celebration.dart';
import 'package:flutter/material.dart';

class AdFocusApp extends StatelessWidget {
  const AdFocusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AD Focus',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7FAFF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF7F88),
          brightness: Brightness.light,
        ),
        fontFamily: 'Pretendard',
      ),
      home: const AdFocusShell(),
    );
  }
}

class AdFocusShell extends StatefulWidget {
  const AdFocusShell({super.key});

  @override
  State<AdFocusShell> createState() => _AdFocusShellState();
}

class _AdFocusShellState extends State<AdFocusShell> {
  final LocalDataStore _store = const LocalDataStore();

  int _currentIndex = 0;
  int _celebrationSeed = 0;
  bool _isLoading = true;
  bool _showQuestCelebration = false;
  AppLocalData _localData = AppLocalData.initial();

  @override
  void initState() {
    super.initState();
    _loadLocalData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFF8EF), Color(0xFFF7FBFF), Color(0xFFFFF0F3)],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF8B93)),
          ),
        ),
      );
    }

    final screens = [
      HomeScreen(
        data: _localData,
        onAddQuest: _openAddQuest,
        onAddQuestForCategory: _openAddQuestForCategory,
        onQuestTap: _openQuestTimer,
        onDeleteQuest: _deleteQuest,
        onOpenSettings: _openSettings,
        onTabChange: _changeTab,
      ),
      DungeonScreen(data: _localData, onClearDungeon: _completeDungeon),
      ShopScreen(data: _localData),
      RecordScreen(data: _localData),
    ];

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Container(
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
            child: SafeArea(child: screens[_currentIndex]),
          ),
          if (_showQuestCelebration)
            Positioned(
              left: 0,
              right: 0,
              bottom: 46,
              height: 220,
              child: QuestCompletionCelebration(
                key: ValueKey(_celebrationSeed),
                seed: _celebrationSeed,
                onComplete: _hideQuestCelebration,
              ),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF8B93).withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _openAddQuest,
          backgroundColor: const Color(0xFFFF8B93),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const CircleBorder(),
          child: const Icon(Icons.add_rounded, size: 28),
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }

  void _changeTab(int index) {
    setState(() => _currentIndex = index);
  }

  Future<void> _openAddQuest() async {
    await _showAddQuestDialog();
  }

  Future<void> _openAddQuestForCategory(String category) async {
    await _showAddQuestDialog(initialCategory: category);
  }

  Future<void> _showAddQuestDialog({String? initialCategory}) async {
    final quest = await showDialog<QuestItem>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.28),
      builder: (context) => AddQuestDialog(initialCategory: initialCategory),
    );

    if (quest == null) {
      return;
    }

    _setLocalData(_localData.copyWith(quests: [quest, ..._localData.quests]));
  }

  Future<void> _openQuestTimer(QuestItem quest) async {
    final result = await Navigator.of(context).push<Object?>(
      MaterialPageRoute<Object?>(
        builder: (_) =>
            QuestTimerScreen(quest: quest, onDelete: () => _deleteQuest(quest)),
      ),
    );

    if (result == null) {
      return;
    }

    if (result case CompletedQuestRecord completedRecord) {
      _setLocalData(_store.completeQuest(_localData, completedRecord));
      _triggerQuestCelebration();
      return;
    }

    if (result case QuestItem updatedQuest) {
      _updateQuest(updatedQuest);
    }
  }

  Future<void> _openSettings() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
  }

  void _deleteQuest(QuestItem quest) {
    _setLocalData(
      _localData.copyWith(
        quests: _localData.quests.where((item) => item.id != quest.id).toList(),
      ),
    );
  }

  void _updateQuest(QuestItem updatedQuest) {
    _setLocalData(
      _localData.copyWith(
        quests: _localData.quests
            .map((item) => item.id == updatedQuest.id ? updatedQuest : item)
            .toList(),
      ),
    );
  }

  void _completeDungeon(String dungeonId) {
    const dungeonRewards = {
      'dungeon_meditation': 8,
      'dungeon_evening_workout': 12,
    };

    final reward = dungeonRewards[dungeonId];
    if (reward == null) {
      return;
    }

    _setLocalData(
      _store.completeDungeon(
        _localData,
        dungeonId: dungeonId,
        creditReward: reward,
      ),
    );
  }

  Future<void> _loadLocalData() async {
    final data = await _store.load();
    if (!mounted) {
      return;
    }

    setState(() {
      _localData = data;
      _isLoading = false;
    });
  }

  void _setLocalData(AppLocalData data) {
    setState(() => _localData = data);
    unawaited(_store.save(data));
  }

  void _triggerQuestCelebration() {
    setState(() {
      _celebrationSeed += 1;
      _showQuestCelebration = true;
    });
  }

  void _hideQuestCelebration() {
    if (!mounted) {
      return;
    }
    setState(() => _showQuestCelebration = false);
  }
}
