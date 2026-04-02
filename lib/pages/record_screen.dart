import 'package:start_on/models/app_local_data.dart';
import 'package:start_on/widgets/common.dart';
import 'package:flutter/material.dart';

class RecordScreen extends StatelessWidget {
  const RecordScreen({super.key, required this.data});

  final AppLocalData data;

  @override
  Widget build(BuildContext context) {
    final recent = data.recentActivities;

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
                    '기록',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1C2940),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: RecordSummaryCard(
                      bgColor: const Color(0xFFFF7F88),
                      title: '이번 주',
                      value: '${data.weeklyCompletedCount}',
                      subtitle: '완료한 퀘스트',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: RecordSummaryCard(
                      bgColor: const Color(0xFFAED7FF),
                      title: '달성률',
                      value: '${data.weeklyCompletionRate}%',
                      subtitle: '지난 주 대비 ${data.weeklyRateDelta >= 0 ? '+' : ''}${data.weeklyRateDelta}%',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              ActivityChartCard(data: data),
              const SizedBox(height: 22),
              const SectionHeading(icon: Icons.emoji_events_outlined, title: '최근 활동'),
              const SizedBox(height: 14),
              if (recent.isEmpty)
                const EmptyRecordCard()
              else
                for (final item in recent) ...[
                  RecentRecordCard(
                    date: item.date,
                    subtitle: item.subtitle,
                    exp: '+${item.exp}',
                  ),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class RecordSummaryCard extends StatelessWidget {
  const RecordSummaryCard({
    super.key,
    required this.bgColor,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final Color bgColor;
  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 42,
              height: 1,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class ActivityChartCard extends StatelessWidget {
  const ActivityChartCard({super.key, required this.data});

  final AppLocalData data;

  @override
  Widget build(BuildContext context) {
    const labels = ['월', '화', '수', '목', '금', '토', '일'];

    return RoundedCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeading(icon: Icons.calendar_today_outlined, title: '이번 주 활동'),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(data.weeklyActivityBars.length, (index) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: index == data.weeklyActivityBars.length - 1 ? 0 : 10,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F4F9),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.bottomCenter,
                                heightFactor: data.weeklyActivityBars[index],
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Color(0xFFFFE2A5),
                                        Color(0xFFFFA9A3),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          labels[index],
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF7E899D),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class RecentRecordCard extends StatelessWidget {
  const RecentRecordCard({
    super.key,
    required this.date,
    required this.subtitle,
    required this.exp,
  });

  final String date;
  final String subtitle;
  final String exp;

  @override
  Widget build(BuildContext context) {
    return RoundedCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF33415C),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF7E899D),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                exp,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFFF8B93),
                ),
              ),
              const Text(
                'EXP',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF98A2B3),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF98A2B3)),
        ],
      ),
    );
  }
}

class EmptyRecordCard extends StatelessWidget {
  const EmptyRecordCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoundedCard(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 34, color: Color(0xFFC0C7D4)),
          SizedBox(height: 12),
          Text(
            '최근 활동 기록이 없습니다',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF33415C),
            ),
          ),
          SizedBox(height: 6),
          Text(
            '퀘스트를 완료하면 활동 내역이 여기에 표시됩니다',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF8E9AAE),
            ),
          ),
        ],
      ),
    );
  }
}
