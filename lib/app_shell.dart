import 'dart:async';

import 'package:start_on/dialogs/add_quest_dialog.dart';
import 'package:start_on/models/app_local_data.dart';
import 'package:start_on/pages/auto_quest_from_gallery_screen.dart';
import 'package:start_on/pages/dungeon_screen.dart';
import 'package:start_on/pages/home_screen.dart';
import 'package:start_on/pages/quest_timer_screen.dart';
import 'package:start_on/pages/record_screen.dart';
import 'package:start_on/pages/settings_screen.dart';
import 'package:start_on/pages/shop_screen.dart';
import 'package:start_on/services/quest_timer_background_service.dart';
import 'package:start_on/storage/app_settings_store.dart';
import 'package:start_on/storage/local_data_store.dart';
import 'package:start_on/widgets/common.dart';
import 'package:start_on/widgets/quest_completion_celebration.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

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

class _AdFocusShellState extends State<AdFocusShell>
    with SingleTickerProviderStateMixin {
  final AppSettingsStore _settingsStore = const AppSettingsStore();
  final LocalDataStore _store = const LocalDataStore();
  final QuestTimerBackgroundService _questTimerService =
      QuestTimerBackgroundService.instance;

  int _currentIndex = 0;
  int _celebrationSeed = 0;
  bool _isLoading = true;
  bool _isOpeningQuestTimer = false;
  bool _isQuestTimerRouteOpen = false;
  bool _notificationsEnabled = true;
  bool _showQuestCelebration = false;
  AppLocalData _localData = AppLocalData.initial();
  StreamSubscription<QuestTimerSnapshot>? _questTimerTickSubscription;
  late final AnimationController _fabPopController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final Animation<double> _fabPopScale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(begin: 1, end: 1.16).chain(
        CurveTween(curve: Curves.easeOutCubic),
      ),
      weight: 42,
    ),
    TweenSequenceItem(
      tween: Tween<double>(begin: 1.16, end: 0.94).chain(
        CurveTween(curve: Curves.easeInOut),
      ),
      weight: 28,
    ),
    TweenSequenceItem(
      tween: Tween<double>(begin: 0.94, end: 1).chain(
        CurveTween(curve: Curves.easeOutBack),
      ),
      weight: 30,
    ),
  ]).animate(_fabPopController);

  @override
  void initState() {
    super.initState();
    _listenToQuestTimerTicks();
    unawaited(_initializeAppState());
  }

  @override
  void dispose() {
    _lifecycleObserver.dispose();
    _questTimerTickSubscription?.cancel();
    _fabPopController.dispose();
    super.dispose();
  }

  late final AppLifecycleListener _lifecycleObserver = AppLifecycleListener(
    onResume: _handleAppResumed,
  );

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
        onOpenAutoQuestFromGallery: _openAutoQuestFromGallery,
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
      floatingActionButton: ScaleTransition(
        scale: _fabPopScale,
        child: Container(
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
    _isOpeningQuestTimer = true;
    _isQuestTimerRouteOpen = true;
    final result = await Navigator.of(context).push<Object?>(
      MaterialPageRoute<Object?>(
        builder: (_) => QuestTimerScreen(
          quest: quest,
          notificationsEnabled: _notificationsEnabled,
          onDelete: () => _deleteQuest(quest),
        ),
      ),
    );
    _isOpeningQuestTimer = false;
    _isQuestTimerRouteOpen = false;

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
    await _reloadSettingsAfterSettingsScreen();
  }

  Future<void> _openAutoQuestFromGallery() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AutoQuestFromGalleryScreen(),
      ),
    );
  }

  void _deleteQuest(QuestItem quest) {
    unawaited(_stopQuestTimerIfActive(quest.id));
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
    var data = await _store.load();
    final activeSnapshot = await _questTimerService.currentState();
    if (activeSnapshot != null) {
      data = _copyWithQuestElapsed(
        data,
        questId: activeSnapshot.questId,
        elapsedSeconds: activeSnapshot.elapsedSeconds,
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _localData = data;
      _isLoading = false;
    });

    if (_notificationsEnabled && activeSnapshot?.isRunning == true) {
      unawaited(
        _openActiveQuestTimerIfNeeded(questId: activeSnapshot!.questId),
      );
    }
  }

  void _setLocalData(AppLocalData data) {
    setState(() => _localData = data);
    unawaited(_store.save(data));
  }

  void _listenToQuestTimerTicks() {
    _questTimerTickSubscription = _questTimerService.timerTicks.listen((tick) {
      if (!mounted) {
        return;
      }

      setState(() {
        _localData = _copyWithQuestElapsed(
          _localData,
          questId: tick.questId,
          elapsedSeconds: tick.elapsedSeconds,
        );
      });
    });
  }

  AppLocalData _copyWithQuestElapsed(
    AppLocalData data, {
    required String questId,
    required int elapsedSeconds,
  }) {
    final nextQuests = data.quests
        .map(
          (item) => item.id == questId
              ? item.copyWith(elapsedSeconds: elapsedSeconds)
              : item,
        )
        .toList();
    return data.copyWith(quests: nextQuests);
  }

  Future<void> _stopQuestTimerIfActive(String questId) async {
    final snapshot = await _questTimerService.currentState();
    if (snapshot?.questId == questId && snapshot?.isRunning == true) {
      await _questTimerService.stopTimer();
    }
  }

  Future<void> _handleAppResumed() async {
    if (!_notificationsEnabled) {
      return;
    }

    final activeSnapshot = await _questTimerService.currentState();
    if (activeSnapshot?.isRunning != true) {
      return;
    }

    await _openActiveQuestTimerIfNeeded(questId: activeSnapshot!.questId);
  }

  Future<void> _openActiveQuestTimerIfNeeded({required String questId}) async {
    if (!mounted ||
        _isLoading ||
        _isOpeningQuestTimer ||
        _isQuestTimerRouteOpen) {
      return;
    }

    QuestItem? quest;
    for (final item in _localData.quests) {
      if (item.id == questId) {
        quest = item;
        break;
      }
    }

    if (quest == null) {
      return;
    }

    await _openQuestTimer(quest);
  }

  Future<void> _requestNotificationPermissionOnLaunch() async {
    if (!_notificationsEnabled) {
      return;
    }

    final status = await Permission.notification.status;
    if (status.isGranted || status.isPermanentlyDenied) {
      return;
    }

    await Permission.notification.request();
  }

  Future<void> _initializeAppState() async {
    await _loadNotificationSetting();
    await _requestNotificationPermissionOnLaunch();
    await _loadLocalData();
  }

  Future<void> _loadNotificationSetting() async {
    final settings = await _settingsStore.load();
    if (!mounted) {
      return;
    }

    setState(() => _notificationsEnabled = settings.notificationsEnabled);
  }

  Future<void> _reloadSettingsAfterSettingsScreen() async {
    final previousValue = _notificationsEnabled;
    final settings = await _settingsStore.load();
    if (!mounted) {
      return;
    }

    setState(() => _notificationsEnabled = settings.notificationsEnabled);

    if (previousValue && !settings.notificationsEnabled) {
      final activeSnapshot = await _questTimerService.currentState();
      if (activeSnapshot?.isRunning == true) {
        await _questTimerService.pauseTimer(
          questId: activeSnapshot!.questId,
          questTitle: activeSnapshot.questTitle,
          elapsedSeconds: activeSnapshot.elapsedSeconds,
          defaultDurationSeconds: activeSnapshot.defaultDurationSeconds,
        );
      }
    }
  }

  void _triggerQuestCelebration() {
    _fabPopController.forward(from: 0);
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
