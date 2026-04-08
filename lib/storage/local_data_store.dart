import 'dart:convert';
import 'dart:math' as math;

import 'package:start_on/models/app_local_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalDataStore {
  const LocalDataStore();

  static const _storageKey = 'ad_focus.local_data';

  Future<AppLocalData> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw == null || raw.isEmpty) {
      final initialData = _normalizeForDate(AppLocalData.initial());
      await prefs.setString(_storageKey, jsonEncode(initialData.toJson()));
      return initialData;
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final normalized = _normalizeForDate(AppLocalData.fromJson(decoded));
      final normalizedRaw = jsonEncode(normalized.toJson());
      if (normalizedRaw != raw) {
        await prefs.setString(_storageKey, normalizedRaw);
      }
      return normalized;
    } catch (_) {
      final fallback = _normalizeForDate(AppLocalData.initial());
      await prefs.setString(_storageKey, jsonEncode(fallback.toJson()));
      return fallback;
    }
  }

  Future<void> save(AppLocalData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(data.toJson()));
  }

  AppLocalData completeQuest(
    AppLocalData currentData,
    CompletedQuestRecord record,
  ) {
    final completedAt = DateTime.tryParse(record.completedAt)?.toLocal() ?? DateTime.now();
    final normalized = _normalizeForDate(currentData, now: completedAt);

    final nextLevelState = _applyExp(
      level: normalized.level,
      currentExp: normalized.currentExp,
      maxExp: normalized.maxExp,
      gainedExp: record.earnedExp,
    );

    final weeklyCounts = List<int>.from(
      normalized.weeklyActivityCounts.isEmpty
          ? List<int>.filled(7, 0)
          : normalized.weeklyActivityCounts,
    );
    while (weeklyCounts.length < 7) {
      weeklyCounts.add(0);
    }
    final weekdayIndex = completedAt.weekday - 1;
    weeklyCounts[weekdayIndex] += 1;

    final weeklyBars = _buildWeeklyBars(weeklyCounts);
    final weeklyCompletedCount = normalized.weeklyCompletedCount + 1;
    final weeklyCompletionRate = _calculateWeeklyCompletionRate(
      weeklyCompletedCount,
      normalized.weeklyRewardTarget,
    );
    final weeklyRateDelta = weeklyCompletionRate - normalized.previousWeeklyCompletionRate;
    final recentActivities = [
      RecentActivity(
        date: _formatActivityDate(completedAt),
        subtitle: '${record.title} 완료',
        exp: record.earnedExp,
      ),
      ...normalized.recentActivities,
    ].take(20).toList();
    final completedQuests = [record, ...normalized.completedQuests].take(100).toList();

    final categoryStats = _applyCategoryStats(
      diligenceStat: normalized.diligenceStat,
      orderStat: normalized.orderStat,
      intelligenceStat: normalized.intelligenceStat,
      healthStat: normalized.healthStat,
      category: record.category,
      difficulty: record.difficulty,
    );

    return normalized.copyWith(
      userRole: _roleForLevel(nextLevelState.level),
      level: nextLevelState.level,
      currentExp: nextLevelState.currentExp,
      maxExp: nextLevelState.maxExp,
      credits: normalized.credits + math.max(1, record.earnedExp ~/ 10),
      completedQuestCount: normalized.completedQuestCount + 1,
      earnedExp: normalized.earnedExp + record.earnedExp,
      dailyRewardCount: math.min(normalized.dailyRewardTarget, normalized.dailyRewardCount + 1),
      weeklyRewardCount: math.min(normalized.weeklyRewardTarget, normalized.weeklyRewardCount + 1),
      monthlyRewardCount: math.min(normalized.monthlyRewardTarget, normalized.monthlyRewardCount + 1),
      weeklyCompletedCount: weeklyCompletedCount,
      weeklyCompletionRate: weeklyCompletionRate,
      weeklyRateDelta: weeklyRateDelta,
      diligenceStat: categoryStats.diligenceStat,
      orderStat: categoryStats.orderStat,
      intelligenceStat: categoryStats.intelligenceStat,
      healthStat: categoryStats.healthStat,
      weeklyActivityCounts: weeklyCounts,
      weeklyActivityBars: weeklyBars,
      recentActivities: recentActivities,
      completedQuests: completedQuests,
      quests: normalized.quests.where((item) => item.id != record.questId).toList(),
    );
  }

  AppLocalData _normalizeForDate(AppLocalData data, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final todayKey = _dateKey(current);
    final weekKey = _weekKey(current);
    final monthKey = _monthKey(current);

    var normalized = data;

    final counts = List<int>.from(
      normalized.weeklyActivityCounts.isEmpty
          ? _activityCountsFromBars(normalized.weeklyActivityBars)
          : normalized.weeklyActivityCounts,
    );
    while (counts.length < 7) {
      counts.add(0);
    }
    if (counts.length > 7) {
      counts.removeRange(7, counts.length);
    }

    if (normalized.dailyResetKey != todayKey) {
      normalized = normalized.copyWith(
        dailyRewardCount: 0,
        dailyResetKey: todayKey,
      );
    }

    if (normalized.weeklyResetKey != weekKey) {
      normalized = normalized.copyWith(
        weeklyRewardCount: 0,
        weeklyCompletedCount: 0,
        previousWeeklyCompletionRate: normalized.weeklyCompletionRate,
        weeklyCompletionRate: 0,
        weeklyRateDelta: 0,
        weeklyActivityCounts: List<int>.filled(7, 0),
        weeklyActivityBars: List<double>.filled(7, 0),
        weeklyResetKey: weekKey,
      );
    } else {
      normalized = normalized.copyWith(
        weeklyActivityCounts: counts,
        weeklyActivityBars: _buildWeeklyBars(counts),
        weeklyResetKey: weekKey,
      );
    }

    if (normalized.monthlyResetKey != monthKey) {
      normalized = normalized.copyWith(
        monthlyRewardCount: 0,
        monthlyResetKey: monthKey,
      );
    }

    if (normalized.userRole != _roleForLevel(normalized.level)) {
      normalized = normalized.copyWith(userRole: _roleForLevel(normalized.level));
    }

    return normalized.copyWith(
      dailyResetKey: normalized.dailyResetKey.isEmpty ? todayKey : normalized.dailyResetKey,
      weeklyResetKey: normalized.weeklyResetKey.isEmpty ? weekKey : normalized.weeklyResetKey,
      monthlyResetKey: normalized.monthlyResetKey.isEmpty ? monthKey : normalized.monthlyResetKey,
    );
  }

  _LevelState _applyExp({
    required int level,
    required int currentExp,
    required int maxExp,
    required int gainedExp,
  }) {
    var nextLevel = level;
    var nextCurrentExp = currentExp + gainedExp;
    var nextMaxExp = maxExp;

    while (nextCurrentExp >= nextMaxExp && nextMaxExp > 0) {
      nextCurrentExp -= nextMaxExp;
      nextLevel += 1;
      nextMaxExp = _requiredExpForLevel(nextLevel);
    }

    return _LevelState(
      level: nextLevel,
      currentExp: nextCurrentExp,
      maxExp: nextMaxExp,
    );
  }

  _CategoryStats _applyCategoryStats({
    required int diligenceStat,
    required int orderStat,
    required int intelligenceStat,
    required int healthStat,
    required String category,
    required String difficulty,
  }) {
    final diligenceGain = switch (difficulty) {
      '쉬움' => 4,
      '보통' => 6,
      _ => 9,
    };
    final categoryGain = switch (difficulty) {
      '쉬움' => 5,
      '보통' => 8,
      _ => 12,
    };

    return _CategoryStats(
      diligenceStat: math.min(100, diligenceStat + diligenceGain),
      orderStat: category == '정돈' ? math.min(100, orderStat + categoryGain) : orderStat,
      intelligenceStat: category == '지능'
          ? math.min(100, intelligenceStat + categoryGain)
          : intelligenceStat,
      healthStat: category == '체력' ? math.min(100, healthStat + categoryGain) : healthStat,
    );
  }

  List<int> _activityCountsFromBars(List<double> bars) {
    final source = bars.isEmpty ? List<double>.filled(7, 0) : bars;
    return List<int>.generate(
      7,
      (index) => index < source.length ? (source[index] * 5).round() : 0,
    );
  }

  List<double> _buildWeeklyBars(List<int> counts) {
    final cappedCounts = counts.take(7).toList();
    final maxCount = cappedCounts.fold<int>(0, math.max);
    if (maxCount <= 0) {
      return List<double>.filled(7, 0);
    }

    return cappedCounts.map((count) => count / maxCount).toList();
  }

  int _calculateWeeklyCompletionRate(int completedCount, int weeklyTarget) {
    if (weeklyTarget <= 0) {
      return 0;
    }

    return math.min(100, ((completedCount / weeklyTarget) * 100).round());
  }

  int _requiredExpForLevel(int level) {
    return 500 + (level * 100);
  }

  String _roleForLevel(int level) {
    if (level >= 8) {
      return '마스터';
    }
    if (level >= 5) {
      return '숙련가';
    }
    if (level >= 2) {
      return '모험가';
    }
    return '초보자';
  }

  String _formatActivityDate(DateTime dateTime) {
    return '${dateTime.year}.${_twoDigits(dateTime.month)}.${_twoDigits(dateTime.day)} '
        '${_twoDigits(dateTime.hour)}:${_twoDigits(dateTime.minute)}';
  }

  String _dateKey(DateTime dateTime) {
    return '${dateTime.year}-${_twoDigits(dateTime.month)}-${_twoDigits(dateTime.day)}';
  }

  String _monthKey(DateTime dateTime) {
    return '${dateTime.year}-${_twoDigits(dateTime.month)}';
  }

  String _weekKey(DateTime dateTime) {
    final startOfWeek = DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
    ).subtract(Duration(days: dateTime.weekday - 1));
    return _dateKey(startOfWeek);
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

class _LevelState {
  const _LevelState({
    required this.level,
    required this.currentExp,
    required this.maxExp,
  });

  final int level;
  final int currentExp;
  final int maxExp;
}

class _CategoryStats {
  const _CategoryStats({
    required this.diligenceStat,
    required this.orderStat,
    required this.intelligenceStat,
    required this.healthStat,
  });

  final int diligenceStat;
  final int orderStat;
  final int intelligenceStat;
  final int healthStat;
}
