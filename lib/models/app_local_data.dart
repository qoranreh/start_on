class QuestItem {
  QuestItem({
    required this.id,
    required this.title,
    required this.exp,
    required this.difficulty,
    required this.category,
  });

  final String id;
  final String title;
  final int exp;
  final String difficulty;
  final String category;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'exp': exp,
      'difficulty': difficulty,
      'category': category,
    };
  }

  factory QuestItem.fromJson(Map<String, dynamic> json) {
    return QuestItem(
      id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: json['title'] as String? ?? '',
      exp: json['exp'] as int? ?? 0,
      difficulty: json['difficulty'] as String? ?? '보통',
      category: json['category'] as String? ?? '지능',
    );
  }
}

class RecentActivity {
  RecentActivity({
    required this.date,
    required this.subtitle,
    required this.exp,
  });

  final String date;
  final String subtitle;
  final int exp;

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'subtitle': subtitle,
      'exp': exp,
    };
  }

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      date: json['date'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      exp: json['exp'] as int? ?? 0,
    );
  }
}

class AppLocalData {
  AppLocalData({
    required this.userName,
    required this.userRole,
    required this.level,
    required this.currentExp,
    required this.maxExp,
    required this.credits,
    required this.completedQuestCount,
    required this.earnedExp,
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
    required this.weeklyActivityBars,
    required this.recentActivities,
    required this.quests,
  });

  final String userName;
  final String userRole;
  final int level;
  final int currentExp;
  final int maxExp;
  final int credits;
  final int completedQuestCount;
  final int earnedExp;
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
  final List<double> weeklyActivityBars;
  final List<RecentActivity> recentActivities;
  final List<QuestItem> quests;

  factory AppLocalData.initial() {
    return AppLocalData(
      userName: '용감한 모험가',
      userRole: '초보자',
      level: 0,
      currentExp: 0,
      maxExp: 500,
      credits: 0,
      completedQuestCount: 0,
      earnedExp: 0,
      dailyRewardCount: 0,
      dailyRewardTarget: 3,
      weeklyRewardCount: 0,
      weeklyRewardTarget: 7,
      monthlyRewardCount: 0,
      monthlyRewardTarget: 30,
      weeklyCompletedCount: 0,
      weeklyCompletionRate: 0,
      weeklyRateDelta: 0,
      diligenceStat: 0,
      orderStat: 0,
      intelligenceStat: 0,
      healthStat: 0,
      weeklyActivityBars: List<double>.filled(7, 0),
      recentActivities: const [],
      quests: const [],
    );
  }

  AppLocalData copyWith({
    String? userName,
    String? userRole,
    int? level,
    int? currentExp,
    int? maxExp,
    int? credits,
    int? completedQuestCount,
    int? earnedExp,
    int? dailyRewardCount,
    int? dailyRewardTarget,
    int? weeklyRewardCount,
    int? weeklyRewardTarget,
    int? monthlyRewardCount,
    int? monthlyRewardTarget,
    int? weeklyCompletedCount,
    int? weeklyCompletionRate,
    int? weeklyRateDelta,
    int? diligenceStat,
    int? orderStat,
    int? intelligenceStat,
    int? healthStat,
    List<double>? weeklyActivityBars,
    List<RecentActivity>? recentActivities,
    List<QuestItem>? quests,
  }) {
    return AppLocalData(
      userName: userName ?? this.userName,
      userRole: userRole ?? this.userRole,
      level: level ?? this.level,
      currentExp: currentExp ?? this.currentExp,
      maxExp: maxExp ?? this.maxExp,
      credits: credits ?? this.credits,
      completedQuestCount: completedQuestCount ?? this.completedQuestCount,
      earnedExp: earnedExp ?? this.earnedExp,
      dailyRewardCount: dailyRewardCount ?? this.dailyRewardCount,
      dailyRewardTarget: dailyRewardTarget ?? this.dailyRewardTarget,
      weeklyRewardCount: weeklyRewardCount ?? this.weeklyRewardCount,
      weeklyRewardTarget: weeklyRewardTarget ?? this.weeklyRewardTarget,
      monthlyRewardCount: monthlyRewardCount ?? this.monthlyRewardCount,
      monthlyRewardTarget: monthlyRewardTarget ?? this.monthlyRewardTarget,
      weeklyCompletedCount: weeklyCompletedCount ?? this.weeklyCompletedCount,
      weeklyCompletionRate: weeklyCompletionRate ?? this.weeklyCompletionRate,
      weeklyRateDelta: weeklyRateDelta ?? this.weeklyRateDelta,
      diligenceStat: diligenceStat ?? this.diligenceStat,
      orderStat: orderStat ?? this.orderStat,
      intelligenceStat: intelligenceStat ?? this.intelligenceStat,
      healthStat: healthStat ?? this.healthStat,
      weeklyActivityBars: weeklyActivityBars ?? this.weeklyActivityBars,
      recentActivities: recentActivities ?? this.recentActivities,
      quests: quests ?? this.quests,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userName': userName,
      'userRole': userRole,
      'level': level,
      'currentExp': currentExp,
      'maxExp': maxExp,
      'credits': credits,
      'completedQuestCount': completedQuestCount,
      'earnedExp': earnedExp,
      'dailyRewardCount': dailyRewardCount,
      'dailyRewardTarget': dailyRewardTarget,
      'weeklyRewardCount': weeklyRewardCount,
      'weeklyRewardTarget': weeklyRewardTarget,
      'monthlyRewardCount': monthlyRewardCount,
      'monthlyRewardTarget': monthlyRewardTarget,
      'weeklyCompletedCount': weeklyCompletedCount,
      'weeklyCompletionRate': weeklyCompletionRate,
      'weeklyRateDelta': weeklyRateDelta,
      'diligenceStat': diligenceStat,
      'orderStat': orderStat,
      'intelligenceStat': intelligenceStat,
      'healthStat': healthStat,
      'weeklyActivityBars': weeklyActivityBars,
      'recentActivities': recentActivities.map((item) => item.toJson()).toList(),
      'quests': quests.map((item) => item.toJson()).toList(),
    };
  }

  factory AppLocalData.fromJson(Map<String, dynamic> json) {
    final defaults = AppLocalData.initial();
    return AppLocalData(
      userName: json['userName'] as String? ?? defaults.userName,
      userRole: json['userRole'] as String? ?? defaults.userRole,
      level: json['level'] as int? ?? defaults.level,
      currentExp: json['currentExp'] as int? ?? defaults.currentExp,
      maxExp: json['maxExp'] as int? ?? defaults.maxExp,
      credits: json['credits'] as int? ?? defaults.credits,
      completedQuestCount: json['completedQuestCount'] as int? ?? defaults.completedQuestCount,
      earnedExp: json['earnedExp'] as int? ?? defaults.earnedExp,
      dailyRewardCount: json['dailyRewardCount'] as int? ?? defaults.dailyRewardCount,
      dailyRewardTarget: json['dailyRewardTarget'] as int? ?? defaults.dailyRewardTarget,
      weeklyRewardCount: json['weeklyRewardCount'] as int? ?? defaults.weeklyRewardCount,
      weeklyRewardTarget: json['weeklyRewardTarget'] as int? ?? defaults.weeklyRewardTarget,
      monthlyRewardCount: json['monthlyRewardCount'] as int? ?? defaults.monthlyRewardCount,
      monthlyRewardTarget: json['monthlyRewardTarget'] as int? ?? defaults.monthlyRewardTarget,
      weeklyCompletedCount: json['weeklyCompletedCount'] as int? ?? defaults.weeklyCompletedCount,
      weeklyCompletionRate: json['weeklyCompletionRate'] as int? ?? defaults.weeklyCompletionRate,
      weeklyRateDelta: json['weeklyRateDelta'] as int? ?? defaults.weeklyRateDelta,
      diligenceStat: json['diligenceStat'] as int? ?? defaults.diligenceStat,
      orderStat: json['orderStat'] as int? ?? defaults.orderStat,
      intelligenceStat: json['intelligenceStat'] as int? ?? defaults.intelligenceStat,
      healthStat: json['healthStat'] as int? ?? defaults.healthStat,
      weeklyActivityBars: ((json['weeklyActivityBars'] as List<dynamic>?) ?? defaults.weeklyActivityBars)
          .map((item) => (item as num).toDouble())
          .toList(),
      recentActivities: ((json['recentActivities'] as List<dynamic>?) ?? const [])
          .map((item) => RecentActivity.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      quests: ((json['quests'] as List<dynamic>?) ?? const [])
          .map((item) => QuestItem.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }
}
