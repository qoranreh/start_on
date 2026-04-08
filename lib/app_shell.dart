import 'dart:async';

import 'package:start_on/dialogs/add_quest_dialog.dart';
import 'package:start_on/models/app_local_data.dart';
import 'package:start_on/pages/dungeon_screen.dart';
import 'package:start_on/pages/home_screen.dart';
import 'package:start_on/pages/profile_screen.dart';
import 'package:start_on/pages/quest_timer_screen.dart';
import 'package:start_on/pages/record_screen.dart';
import 'package:start_on/pages/shop_screen.dart';
import 'package:start_on/storage/local_data_store.dart';
import 'package:start_on/widgets/common.dart';
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
  bool _isLoading = true;
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
              colors: [
                Color(0xFFFFF8EF),
                Color(0xFFF7FBFF),
                Color(0xFFFFF0F3),
              ],
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
        onQuestTap: _openQuestTimer,
        onDeleteQuest: _deleteQuest,
        onTabChange: _changeTab,
      ),
      const DungeonScreen(),
      ProfileScreen(
        data: _localData,
        onOpenRecord: _openRecordScreen,
      ),
      ShopScreen(data: _localData),
    ];

    return Scaffold(
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
        child: SafeArea(child: screens[_currentIndex]),
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
    final quest = await showDialog<QuestItem>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.28),
      builder: (context) => const AddQuestDialog(),
    );

    if (quest == null) {
      return;
    }

    _setLocalData(
      _localData.copyWith(
        quests: [quest, ..._localData.quests],
      ),
    );
  }

  Future<void> _openQuestTimer(QuestItem quest) async {
    final result = await Navigator.of(context).push<CompletedQuestRecord>(
      MaterialPageRoute<CompletedQuestRecord>(
        builder: (_) => QuestTimerScreen(
          quest: quest,
          onDelete: () => _deleteQuest(quest),
        ),
      ),
    );

    if (result == null) {
      return;
    }

    _setLocalData(_store.completeQuest(_localData, result));
  }

  void _deleteQuest(QuestItem quest) {
    _setLocalData(
      _localData.copyWith(
        quests: _localData.quests.where((item) => item.id != quest.id).toList(),
      ),
    );
  }

  Future<void> _openRecordScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RecordScreen(data: _localData),
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
}
