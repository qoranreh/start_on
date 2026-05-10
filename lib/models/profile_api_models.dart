class ProfileResponse {
  const ProfileResponse({
    required this.userName,
    required this.userRole,
    required this.level,
    required this.currentExp,
    required this.maxExp,
    required this.credits,
    required this.completedQuestCount,
    required this.earnedExp,
  });

  factory ProfileResponse.fromJson(Object? json) {
    final object = _asJsonObject(json, 'Profile must be a JSON object.');

    return ProfileResponse(
      userName: _readString(object, 'userName'),
      userRole: _readString(object, 'userRole'),
      level: _readInt(object, 'level'),
      currentExp: _readInt(object, 'currentExp'),
      maxExp: _readInt(object, 'maxExp'),
      credits: _readInt(object, 'credits'),
      completedQuestCount: _readInt(object, 'completedQuestCount'),
      earnedExp: _readInt(object, 'earnedExp'),
    );
  }

  final String userName;
  final String userRole;
  final int level;
  final int currentExp;
  final int maxExp;
  final int credits;
  final int completedQuestCount;
  final int earnedExp;
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

String _readString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }
  throw FormatException('$key must be a non-empty string.');
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
