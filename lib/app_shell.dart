import 'dart:async';

import 'package:start_on/models/app_local_data.dart';
import 'package:start_on/models/dungeon_api_models.dart';
import 'package:start_on/models/profile_api_models.dart';
import 'package:start_on/models/quest_api_models.dart';
import 'package:start_on/models/stats_api_models.dart';
import 'package:start_on/pages/add_quest_screen.dart';
import 'package:start_on/pages/auto_quest_from_gallery_screen.dart';
import 'package:start_on/pages/dungeon_screen.dart';
import 'package:start_on/pages/home_screen.dart';
import 'package:start_on/pages/login_screen.dart';
import 'package:start_on/pages/quest_timer/quest_timer_bottom_sheet.dart';
import 'package:start_on/pages/quest_timer_screen.dart';
import 'package:start_on/pages/ranking_screen.dart';
import 'package:start_on/pages/record_screen.dart';
import 'package:start_on/pages/settings_screen.dart';
import 'package:start_on/repositories/auth_repository.dart';
import 'package:start_on/repositories/dungeon_repository.dart';
import 'package:start_on/repositories/profile_repository.dart';
import 'package:start_on/repositories/quest_repository.dart';
import 'package:start_on/repositories/stats_repository.dart';
import 'package:start_on/services/api_client.dart';
import 'package:start_on/services/quest_timer_background_service.dart';
import 'package:start_on/storage/app_settings_store.dart';
import 'package:start_on/storage/auth_session_store.dart';
import 'package:start_on/storage/local_data_store.dart';
import 'package:start_on/widgets/common.dart';
import 'package:start_on/widgets/quest_completion_celebration.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

const _systemUiOverlayStyle = SystemUiOverlayStyle(
  systemNavigationBarColor: Color(0xFFF1F3F8),
  systemNavigationBarIconBrightness: Brightness.dark,
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.dark,
);

class AdFocusApp extends StatelessWidget {
  const AdFocusApp({
    super.key,
    AuthRepository? authRepository,
    ProfileRepository? profileRepository,
    QuestRepository? questRepository,
    StatsRepository? statsRepository,
    DungeonRepository? dungeonRepository,
  }) : _authRepository = authRepository,
       _profileRepository = profileRepository,
       _questRepository = questRepository,
       _statsRepository = statsRepository,
       _dungeonRepository = dungeonRepository;

  final AuthRepository? _authRepository;
  final ProfileRepository? _profileRepository;
  final QuestRepository? _questRepository;
  final StatsRepository? _statsRepository;
  final DungeonRepository? _dungeonRepository;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _systemUiOverlayStyle,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Start On',
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF1F3F8),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6F63FF),
            brightness: Brightness.light,
          ),
          fontFamily: 'Pretendard',
        ),
        home: _AuthGate(
          authRepository: _authRepository,
          profileRepository: _profileRepository,
          questRepository: _questRepository,
          statsRepository: _statsRepository,
          dungeonRepository: _dungeonRepository,
        ),
      ),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate({
    this.authRepository,
    this.profileRepository,
    this.questRepository,
    this.statsRepository,
    this.dungeonRepository,
  });

  final AuthRepository? authRepository;
  final ProfileRepository? profileRepository;
  final QuestRepository? questRepository;
  final StatsRepository? statsRepository;
  final DungeonRepository? dungeonRepository;

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  final AuthSessionStore _authStore = const AuthSessionStore();

  late final AuthRepository _authRepository;
  late final bool _ownsAuthRepository;
  AuthSession? _session;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _authRepository = widget.authRepository ?? AuthRepository();
    _ownsAuthRepository = widget.authRepository == null;
    unawaited(_loadSession());
  }

  @override
  void dispose() {
    if (_ownsAuthRepository) {
      _authRepository.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(color: Color(0xFFF1F3F8)),
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xFF6F63FF)),
          ),
        ),
      );
    }

    final session = _session;
    if (session == null) {
      return LoginScreen(
        onSignIn: _handleServerSignIn,
        onSignUp: _handleServerSignUp,
        onGuestStart: _handleGuestStart,
      );
    }

    return AdFocusShell(
      session: session,
      onChangeAccount: _handleAccountChange,
      profileRepository: widget.profileRepository,
      questRepository: widget.questRepository,
      statsRepository: widget.statsRepository,
      dungeonRepository: widget.dungeonRepository,
    );
  }

  Future<void> _loadSession() async {
    final session = await _authStore.load();
    if (!mounted) {
      return;
    }

    setState(() {
      _session = session;
      _isLoading = false;
    });
  }

  Future<void> _handleServerSignIn({
    required String email,
    required String password,
  }) async {
    final response = await _authRepository.signIn(
      email: email,
      password: password,
    );
    await _saveSession(AuthSession.fromAuthResponse(response));
  }

  Future<void> _handleServerSignUp({
    required String email,
    required String password,
  }) async {
    final response = await _authRepository.signUp(
      email: email,
      password: password,
    );
    await _saveSession(AuthSession.fromAuthResponse(response));
  }

  Future<void> _handleGuestStart() {
    return _saveSession(
      AuthSession.local(email: 'guest@starton.local', displayName: '게스트'),
    );
  }

  Future<void> _saveSession(AuthSession session) async {
    await _authStore.save(session);

    if (!mounted) {
      return;
    }
    setState(() => _session = session);
  }

  Future<void> _handleAccountChange() async {
    await _authStore.clear();
    if (!mounted) {
      return;
    }
    setState(() => _session = null);
  }
}

class _BottomNavCenterFabLocation extends FloatingActionButtonLocation {
  const _BottomNavCenterFabLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final fabSize = scaffoldGeometry.floatingActionButtonSize;
    final bottomBarHeight =
        scaffoldGeometry.scaffoldSize.height - scaffoldGeometry.contentBottom;

    return Offset(
      (scaffoldGeometry.scaffoldSize.width - fabSize.width) / 2,
      scaffoldGeometry.contentBottom +
          (bottomBarHeight - fabSize.height) / 2 -
          18,
    );
  }
}

class AdFocusShell extends StatefulWidget {
  const AdFocusShell({
    required this.session,
    required this.onChangeAccount,
    this.profileRepository,
    this.questRepository,
    this.statsRepository,
    this.dungeonRepository,
    super.key,
  });

  final AuthSession session;
  final Future<void> Function() onChangeAccount;
  final ProfileRepository? profileRepository;
  final QuestRepository? questRepository;
  final StatsRepository? statsRepository;
  final DungeonRepository? dungeonRepository;

  @override
  State<AdFocusShell> createState() => _AdFocusShellState();
}

class _AdFocusShellState extends State<AdFocusShell>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AppSettingsStore _settingsStore = const AppSettingsStore();
  final LocalDataStore _store = const LocalDataStore();
  final QuestTimerBackgroundService _questTimerService =
      QuestTimerBackgroundService.instance;

  late final ProfileRepository? _profileRepository;
  late final QuestRepository? _questRepository;
  late final StatsRepository? _statsRepository;
  late final DungeonRepository? _dungeonRepository;
  late final bool _usesServerData;
  late final bool _ownsProfileRepository;
  late final bool _ownsQuestRepository;
  late final bool _ownsStatsRepository;
  late final bool _ownsDungeonRepository;
  int _currentIndex = 0;
  int _celebrationSeed = 0;
  bool _isLoading = true;
  bool _isOpeningQuestTimer = false;
  bool _isQuestTimerRouteOpen = false;
  bool _isQuestTimerBottomSheetOpen = false;
  bool _didShowLaunchQuestTimerSheet = false;
  bool _notificationsEnabled = true;
  bool _showQuestCelebration = false;
  AppLocalData _localData = AppLocalData.initial();
  PersistentBottomSheetController? _questTimerBottomSheetController;
  StreamSubscription<QuestTimerSnapshot>? _questTimerTickSubscription;
  late final AnimationController _fabPopController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final Animation<double> _fabPopScale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1,
        end: 1.16,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 42,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1.16,
        end: 0.94,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 28,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 0.94,
        end: 1,
      ).chain(CurveTween(curve: Curves.easeOutBack)),
      weight: 30,
    ),
  ]).animate(_fabPopController);

  @override
  void initState() {
    super.initState();
    _usesServerData =
        !widget.session.isLocalOnly && widget.session.hasBearerToken;
    _profileRepository = _usesServerData
        ? widget.profileRepository ?? ProfileRepository()
        : null;
    _questRepository = _usesServerData
        ? widget.questRepository ?? QuestRepository()
        : null;
    _statsRepository = _usesServerData
        ? widget.statsRepository ?? StatsRepository()
        : null;
    _dungeonRepository = _usesServerData
        ? widget.dungeonRepository ?? DungeonRepository()
        : null;
    _ownsProfileRepository =
        _usesServerData && widget.profileRepository == null;
    _ownsQuestRepository = _usesServerData && widget.questRepository == null;
    _ownsStatsRepository = _usesServerData && widget.statsRepository == null;
    _ownsDungeonRepository =
        _usesServerData && widget.dungeonRepository == null;
    _listenToQuestTimerTicks();
    unawaited(_initializeAppState());
  }

  @override
  void dispose() {
    _lifecycleObserver.dispose();
    _questTimerTickSubscription?.cancel();
    _fabPopController.dispose();
    if (_ownsProfileRepository) {
      _profileRepository?.close();
    }
    if (_ownsQuestRepository) {
      _questRepository?.close();
    }
    if (_ownsStatsRepository) {
      _statsRepository?.close();
    }
    if (_ownsDungeonRepository) {
      _dungeonRepository?.close();
    }
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
          decoration: const BoxDecoration(color: Color(0xFFF1F3F8)),
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xFF6F63FF)),
          ),
        ),
      );
    }

    final screens = [
      HomeScreen(
        data: _localData,
        userName: _homeUserName,
        onAddQuest: _openAddQuest,
        onAddQuestForCategory: _openAddQuestForCategory,
        onQuestTap: _openQuestTimer,
        onDeleteQuest: _deleteQuest,
        onOpenSettings: _openSettings,
        onOpenAutoQuestFromGallery: _openAutoQuestFromGallery,
        onTabChange: _changeTab,
      ),
      DungeonScreen(data: _localData, onClearDungeon: _completeDungeon),
      RankingScreen(data: _localData),
      RecordScreen(data: _localData),
    ];

    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(color: Color(0xFFF1F3F8)),
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
      floatingActionButtonLocation: const _BottomNavCenterFabLocation(),
      floatingActionButton: ScaleTransition(
        scale: _fabPopScale,
        child: NeumorphicRoundedCard(
          padding: EdgeInsets.zero,
          color: const Color(0xFFD0CBFF),
          borderRadius: 18,
          child: SizedBox(
            width: 56,
            height: 42,
            child: FloatingActionButton(
              onPressed: _openAddQuest,
              backgroundColor: const Color(0xFFD0CBFF),
              foregroundColor: const Color(0xFF6358FF),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.add_rounded, size: 23),
            ),
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

  String get _homeUserName {
    if (_usesServerData && _localData.userName.trim().isNotEmpty) {
      return _localData.userName;
    }
    return widget.session.displayName;
  }

  Future<void> _openAddQuest() async {
    await _openAddQuestScreen();
  }

  Future<void> _openAddQuestForCategory(String category) async {
    await _openAddQuestScreen(initialCategory: category);
  }

  Future<void> _openAddQuestScreen({String? initialCategory}) async {
    final quest = await Navigator.of(context).push<QuestItem>(
      MaterialPageRoute<QuestItem>(
        builder: (context) => AddQuestScreen(initialCategory: initialCategory),
      ),
    );

    if (quest == null) {
      return;
    }

    final createdQuest = await _createQuest(quest);
    if (!mounted || createdQuest == null) {
      return;
    }

    _setLocalData(
      _localData.copyWith(quests: [createdQuest, ..._localData.quests]),
    );
  }

  Future<void> _openQuestTimer(QuestItem quest) async {
    _isOpeningQuestTimer = true;
    _isQuestTimerRouteOpen = true;
    final result = await Navigator.of(context).push<Object?>(
      MaterialPageRoute<Object?>(
        builder: (_) => QuestTimerScreen(
          quest: quest,
          userLevel: _localData.level,
          notificationsEnabled: _notificationsEnabled,
        ),
      ),
    );
    _isOpeningQuestTimer = false;
    _isQuestTimerRouteOpen = false;

    if (result == null) {
      return;
    }

    await _handleQuestTimerResult(result);
  }

  Future<void> _handleQuestTimerResult(Object? result) async {
    if (result == null) {
      return;
    }

    if (result case CompletedQuestRecord completedRecord) {
      final savedRecord = await _completeQuest(completedRecord);
      if (!mounted || savedRecord == null) {
        return;
      }

      _setLocalData(_store.completeQuest(_localData, savedRecord));
      _triggerQuestCelebration();
      return;
    }

    if (result case QuestTimerScreenResult timerResult) {
      _updateQuest(timerResult.quest);
      if (timerResult.didPauseTimer) {
        _showStyledSnackBar('타이머 일시중지됨', centerText: true, compact: true);
      }
      return;
    }

    if (result case QuestItem updatedQuest) {
      _updateQuest(updatedQuest);
    }
  }

  Future<void> _openSettings() async {
    final result = await Navigator.of(context).push<SettingsScreenResult>(
      MaterialPageRoute<SettingsScreenResult>(
        builder: (_) => SettingsScreen(
          userName: widget.session.displayName,
          userEmail: widget.session.email,
        ),
      ),
    );

    if (result == SettingsScreenResult.changeAccount) {
      await widget.onChangeAccount();
      return;
    }

    await _reloadSettingsAfterSettingsScreen();
    await _reloadLocalDataAfterSettingsScreen();
  }

  Future<void> _openAutoQuestFromGallery() async {
    final generatedQuests = await Navigator.of(context).push<List<QuestItem>>(
      MaterialPageRoute<List<QuestItem>>(
        builder: (_) => const AutoQuestFromGalleryScreen(),
      ),
    );

    if (!mounted || generatedQuests == null || generatedQuests.isEmpty) {
      return;
    }

    final createdQuests = await _createQuests(generatedQuests);
    if (!mounted || createdQuests.isEmpty) {
      return;
    }

    _setLocalData(
      _localData.copyWith(quests: [...createdQuests, ..._localData.quests]),
    );
    _showStyledSnackBar('${createdQuests.length}개의 퀘스트를 추가했어요.');
  }

  void _deleteQuest(QuestItem quest) {
    unawaited(_deleteQuestAsync(quest));
  }

  Future<void> _deleteQuestAsync(QuestItem quest) async {
    await _stopQuestTimerIfActive(quest.id);

    final questRepository = _questRepository;
    if (questRepository != null) {
      try {
        await questRepository.deleteQuest(quest.id);
      } catch (error) {
        _showQuestSyncError('퀘스트를 삭제하지 못했어요.', error);
        return;
      }
    }

    if (!mounted) {
      return;
    }

    _setLocalData(
      _localData.copyWith(
        quests: _localData.quests.where((item) => item.id != quest.id).toList(),
      ),
    );
  }

  void _updateQuest(
    QuestItem updatedQuest, {
    bool syncServer = true,
    bool persist = true,
  }) {
    _setLocalData(_replaceQuest(_localData, updatedQuest), persist: persist);

    if (syncServer) {
      unawaited(_syncQuestUpdate(updatedQuest));
    }
  }

  void _completeDungeon(String dungeonId) {
    unawaited(_completeDungeonAsync(dungeonId));
  }

  Future<void> _completeDungeonAsync(String dungeonId) async {
    final dungeonRepository = _dungeonRepository;
    if (dungeonRepository != null) {
      try {
        final clearResult = await dungeonRepository.clearDungeon(dungeonId);
        if (!mounted) {
          return;
        }
        _setLocalData(
          _localData.copyWith(
            credits: clearResult.credits,
            clearedDungeonIds: _withClearedDungeonId(
              _localData.clearedDungeonIds,
              clearResult.dungeonId,
            ),
          ),
        );
      } catch (error) {
        _showQuestSyncError('던전 보상을 서버에 저장하지 못했어요.', error);
      }
      return;
    }

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
    final data = await _buildLoadedLocalData();
    final activeSnapshot = await _questTimerService.currentState();

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
      return;
    }

    _scheduleLaunchQuestTimerBottomSheet();
  }

  void _setLocalData(AppLocalData data, {bool persist = true}) {
    setState(() => _localData = data);
    if (persist) {
      unawaited(_store.save(data));
    }
  }

  void _scheduleLaunchQuestTimerBottomSheet() {
    if (_didShowLaunchQuestTimerSheet || _localData.quests.isEmpty) {
      return;
    }

    _didShowLaunchQuestTimerSheet = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _currentIndex != 0 || _localData.quests.isEmpty) {
        return;
      }

      unawaited(_openQuestTimerBottomSheet(_localData.quests.first));
    });
  }

  Future<void> _openQuestTimerBottomSheet(QuestItem quest) async {
    if (!mounted ||
        _isOpeningQuestTimer ||
        _isQuestTimerRouteOpen ||
        _isQuestTimerBottomSheetOpen) {
      return;
    }

    final scaffoldState = _scaffoldKey.currentState;
    if (scaffoldState == null) {
      return;
    }

    _isQuestTimerBottomSheetOpen = true;
    QuestItem? fullTimerQuest;

    late final PersistentBottomSheetController controller;
    controller = scaffoldState.showBottomSheet(
      (context) => SizedBox(
        width: double.infinity,
        height: MediaQuery.sizeOf(context).height * 0.34,
        child: QuestTimerBottomSheet(
          quest: quest,
          notificationsEnabled: _notificationsEnabled,
          onQuestChanged: (updatedQuest) =>
              _updateQuest(updatedQuest, syncServer: false, persist: false),
          onOpenFullTimer: (updatedQuest) {
            fullTimerQuest = updatedQuest;
            controller.close();
          },
          onClose: () => controller.close(),
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      enableDrag: false,
      sheetAnimationStyle: const AnimationStyle(
        curve: Curves.easeOutCubic,
        duration: Duration(milliseconds: 360),
        reverseCurve: Curves.easeInCubic,
        reverseDuration: Duration(milliseconds: 260),
      ),
    );
    _questTimerBottomSheetController = controller;

    await controller.closed;

    if (!mounted) {
      return;
    }

    _isQuestTimerBottomSheetOpen = false;
    if (identical(_questTimerBottomSheetController, controller)) {
      _questTimerBottomSheetController = null;
    }

    final questForFullTimer = fullTimerQuest;
    if (questForFullTimer != null) {
      await _openQuestTimer(questForFullTimer);
      return;
    }

    var questToPersist = _findQuest(quest.id) ?? quest;
    if (_notificationsEnabled) {
      final snapshot = await _questTimerService.currentState();
      if (snapshot?.questId == quest.id && snapshot?.isRunning == true) {
        await _questTimerService.pauseTimer(
          questId: snapshot!.questId,
          questTitle: snapshot.questTitle,
          elapsedSeconds: snapshot.elapsedSeconds,
          defaultDurationSeconds: snapshot.defaultDurationSeconds,
        );
        questToPersist = questToPersist.copyWith(
          elapsedSeconds: snapshot.elapsedSeconds,
        );
      }
    }

    if (questToPersist.elapsedSeconds != quest.elapsedSeconds) {
      _updateQuest(questToPersist);
    }
  }

  void _showStyledSnackBar(
    String message, {
    bool centerText = false,
    bool compact = false,
  }) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final textStyle =
        theme.snackBarTheme.contentTextStyle ??
        theme.textTheme.bodyMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ) ??
        const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        );

    final compactWidth = compact
        ? (() {
            final textPainter = TextPainter(
              text: TextSpan(text: message, style: textStyle),
              maxLines: 1,
              textDirection: Directionality.of(context),
            )..layout(maxWidth: mediaQuery.size.width - 72);
            return (textPainter.width + 32).clamp(
              120.0,
              mediaQuery.size.width - 40,
            );
          })()
        : null;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            textAlign: centerText ? TextAlign.center : null,
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFFF8B93),
          margin: compact ? null : const EdgeInsets.fromLTRB(20, 0, 20, 20),
          width: compact ? compactWidth : null,
          padding: compact
              ? const EdgeInsets.symmetric(horizontal: 16, vertical: 14)
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          duration: const Duration(seconds: 2),
        ),
        snackBarAnimationStyle: const AnimationStyle(
          curve: Curves.easeOutCubic,
          duration: Duration(milliseconds: 420),
          reverseCurve: Curves.easeInCubic,
          reverseDuration: Duration(milliseconds: 320),
        ),
      );
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

    final quest = _findQuest(questId);
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

  Future<void> _reloadLocalDataAfterSettingsScreen() async {
    final data = await _buildLoadedLocalData();
    if (!mounted) {
      return;
    }
    setState(() => _localData = data);
  }

  Future<AppLocalData> _buildLoadedLocalData() async {
    var data = await _store.load();
    data = await _loadServerInitialData(data);

    final activeSnapshot = await _questTimerService.currentState();
    if (activeSnapshot != null) {
      data = _copyWithQuestElapsed(
        data,
        questId: activeSnapshot.questId,
        elapsedSeconds: activeSnapshot.elapsedSeconds,
      );
    }
    return data;
  }

  Future<AppLocalData> _loadServerInitialData(AppLocalData fallbackData) async {
    final profileRepository = _profileRepository;
    final questRepository = _questRepository;
    final statsRepository = _statsRepository;
    final dungeonRepository = _dungeonRepository;
    if (profileRepository == null ||
        questRepository == null ||
        statsRepository == null ||
        dungeonRepository == null) {
      return fallbackData;
    }

    try {
      final profileFuture = profileRepository.getProfile();
      final questsFuture = questRepository.listQuests();
      final statsFuture = statsRepository.getSummary();
      final dungeonsFuture = dungeonRepository.listDungeons();

      await Future.wait<Object>([
        profileFuture,
        questsFuture,
        statsFuture,
        dungeonsFuture,
      ]);

      final data = _copyWithServerInitialData(
        fallbackData,
        profile: await profileFuture,
        quests: await questsFuture,
        stats: await statsFuture,
        dungeonList: await dungeonsFuture,
      );
      await _store.save(data);
      return data;
    } catch (error) {
      _scheduleQuestSyncError('서버 초기 데이터를 불러오지 못해 저장된 데이터를 표시합니다.', error);
      return fallbackData;
    }
  }

  AppLocalData _copyWithServerInitialData(
    AppLocalData data, {
    required ProfileResponse profile,
    required List<QuestItemResponse> quests,
    required StatsSummaryResponse stats,
    required DungeonListResponse dungeonList,
  }) {
    return data.copyWith(
      userName: profile.userName,
      userRole: profile.userRole,
      level: profile.level,
      currentExp: profile.currentExp,
      maxExp: profile.maxExp,
      credits: profile.credits,
      completedQuestCount: profile.completedQuestCount,
      earnedExp: profile.earnedExp,
      dailyRewardCount: stats.dailyRewardCount,
      dailyRewardTarget: stats.dailyRewardTarget,
      weeklyRewardCount: stats.weeklyRewardCount,
      weeklyRewardTarget: stats.weeklyRewardTarget,
      monthlyRewardCount: stats.monthlyRewardCount,
      monthlyRewardTarget: stats.monthlyRewardTarget,
      weeklyCompletedCount: stats.weeklyCompletedCount,
      weeklyCompletionRate: stats.weeklyCompletionRate,
      weeklyRateDelta: stats.weeklyRateDelta,
      diligenceStat: stats.diligenceStat,
      orderStat: stats.orderStat,
      intelligenceStat: stats.intelligenceStat,
      healthStat: stats.healthStat,
      quests: quests.map(QuestItem.fromApiResponse).toList(),
      clearedDungeonIds: dungeonList.dungeons
          .where((dungeon) => dungeon.cleared)
          .map((dungeon) => dungeon.dungeonId)
          .toList(),
    );
  }

  Future<QuestItem?> _createQuest(QuestItem quest) async {
    final questRepository = _questRepository;
    if (questRepository == null) {
      return quest;
    }

    try {
      final createdQuest = await questRepository.createQuest(
        quest.toCreateRequest(),
      );
      return QuestItem.fromApiResponse(createdQuest);
    } catch (error) {
      _showQuestSyncError('퀘스트를 서버에 저장하지 못했어요.', error);
      return null;
    }
  }

  Future<List<QuestItem>> _createQuests(List<QuestItem> quests) async {
    final questRepository = _questRepository;
    if (questRepository == null) {
      return quests;
    }

    final createdQuests = <QuestItem>[];
    for (final quest in quests) {
      try {
        final createdQuest = await questRepository.createQuest(
          quest.toCreateRequest(),
        );
        createdQuests.add(QuestItem.fromApiResponse(createdQuest));
      } catch (error) {
        _showQuestSyncError('퀘스트 일부를 서버에 저장하지 못했어요.', error);
        break;
      }
    }
    return createdQuests;
  }

  Future<void> _syncQuestUpdate(QuestItem quest) async {
    final questRepository = _questRepository;
    if (questRepository == null) {
      return;
    }

    try {
      final updatedQuest = await questRepository.updateQuest(
        quest.id,
        quest.toUpdateRequest(),
      );
      if (!mounted) {
        return;
      }
      _setLocalData(
        _replaceQuest(_localData, QuestItem.fromApiResponse(updatedQuest)),
      );
    } catch (error) {
      _showQuestSyncError('퀘스트 변경사항을 서버에 저장하지 못했어요.', error);
    }
  }

  Future<CompletedQuestRecord?> _completeQuest(
    CompletedQuestRecord completedRecord,
  ) async {
    final questRepository = _questRepository;
    if (questRepository == null) {
      return completedRecord;
    }

    try {
      final savedRecord = await questRepository.completeQuest(
        completedRecord.questId,
        elapsedSeconds: completedRecord.elapsedSeconds,
        proofImagePath: completedRecord.proofImagePath,
      );
      return CompletedQuestRecord.fromApiResponse(savedRecord);
    } catch (error) {
      _showQuestSyncError('퀘스트 완료를 서버에 저장하지 못했어요.', error);
      _updateQuest(_copyQuestWithElapsed(completedRecord), syncServer: false);
      return null;
    }
  }

  QuestItem _copyQuestWithElapsed(CompletedQuestRecord completedRecord) {
    final quest = _findQuest(completedRecord.questId);
    if (quest != null) {
      return quest.copyWith(elapsedSeconds: completedRecord.elapsedSeconds);
    }
    return QuestItem(
      id: completedRecord.questId,
      title: completedRecord.title,
      exp: completedRecord.earnedExp,
      difficulty: completedRecord.difficulty,
      category: completedRecord.category,
      elapsedSeconds: completedRecord.elapsedSeconds,
      defaultDurationSeconds: defaultQuestDurationSecondsForDifficulty(
        completedRecord.difficulty,
      ),
    );
  }

  QuestItem? _findQuest(String questId) {
    for (final quest in _localData.quests) {
      if (quest.id == questId) {
        return quest;
      }
    }
    return null;
  }

  List<String> _withClearedDungeonId(
    List<String> clearedDungeonIds,
    String dungeonId,
  ) {
    if (clearedDungeonIds.contains(dungeonId)) {
      return clearedDungeonIds;
    }
    return [...clearedDungeonIds, dungeonId];
  }

  AppLocalData _replaceQuest(AppLocalData data, QuestItem updatedQuest) {
    return data.copyWith(
      quests: data.quests
          .map((item) => item.id == updatedQuest.id ? updatedQuest : item)
          .toList(),
    );
  }

  void _scheduleQuestSyncError(String fallbackMessage, Object error) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showQuestSyncError(fallbackMessage, error);
    });
  }

  void _showQuestSyncError(String fallbackMessage, Object error) {
    if (!mounted) {
      return;
    }
    _showStyledSnackBar(_questSyncErrorMessage(fallbackMessage, error));
  }

  String _questSyncErrorMessage(String fallbackMessage, Object error) {
    if (error is ApiClientException && error.statusCode == 401) {
      return '로그인이 만료됐어요. 다시 로그인해 주세요.';
    }
    if (error is QuestRepositoryException && error.code == 'quest_not_found') {
      return '서버에서 퀘스트를 찾지 못했어요.';
    }
    return fallbackMessage;
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
