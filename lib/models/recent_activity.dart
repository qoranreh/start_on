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
    return {'date': date, 'subtitle': subtitle, 'exp': exp};
  }

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      date: json['date'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      exp: json['exp'] as int? ?? 0,
    );
  }
}
