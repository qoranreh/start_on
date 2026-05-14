class StatsSummaryResponse {
  const StatsSummaryResponse({
    required this.dailyRewardCount,
    required this.dailyRewardTarget,
    required this.weeklyRewardCount,
    required this.weeklyRewardTarget,
    required this.monthlyRewardCount,
    required this.monthlyRewardTarget,
    required this.weeklyCompletedCount,
    required this.weeklyCompletionRate,
    required this.weeklyRateDelta,
    required this.diligenceStat,
    required this.orderStat,
    required this.intelligenceStat,
    required this.healthStat,
  });

  factory StatsSummaryResponse.fromJson(Object? json) {
    final object = _asJsonObject(json, 'Stats summary must be a JSON object.');

    return StatsSummaryResponse(
      dailyRewardCount: _readInt(object, 'dailyRewardCount'),
      dailyRewardTarget: _readInt(object, 'dailyRewardTarget'),
      weeklyRewardCount: _readInt(object, 'weeklyRewardCount'),
      weeklyRewardTarget: _readInt(object, 'weeklyRewardTarget'),
      monthlyRewardCount: _readInt(object, 'monthlyRewardCount'),
      monthlyRewardTarget: _readInt(object, 'monthlyRewardTarget'),
      weeklyCompletedCount: _readInt(object, 'weeklyCompletedCount'),
      weeklyCompletionRate: _readInt(object, 'weeklyCompletionRate'),
      weeklyRateDelta: _readInt(object, 'weeklyRateDelta'),
      diligenceStat: _readInt(object, 'diligenceStat'),
      orderStat: _readInt(object, 'orderStat'),
      intelligenceStat: _readInt(object, 'intelligenceStat'),
      healthStat: _readInt(object, 'healthStat'),
    );
  }

  final int dailyRewardCount;
  final int dailyRewardTarget;
  final int weeklyRewardCount;
  final int weeklyRewardTarget;
  final int monthlyRewardCount;
  final int monthlyRewardTarget;
  final int weeklyCompletedCount;
  final int weeklyCompletionRate;
  final int weeklyRateDelta;
  final int diligenceStat;
  final int orderStat;
  final int intelligenceStat;
  final int healthStat;
}

Map<String, dynamic> _asJsonObject(Object? value, String message) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map<String, dynamic>(
      (key, value) => MapEntry(key.toString(), value),
    );
  }
  throw FormatException(message);
}

int _readInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  throw FormatException('$key must be a number.');
}
