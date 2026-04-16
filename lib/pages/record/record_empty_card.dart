import 'package:flutter/material.dart';
import 'package:start_on/widgets/common.dart';

class RecordEmptyCard extends StatelessWidget {
  const RecordEmptyCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const NeumorphicRoundedCard(
      padding: EdgeInsets.all(20),
      color: Color(0xFFF8FBFF),
      shadowDarkColor: Color(0xFFD5DDEA),
      child: Column(
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 34,
            color: Color(0xFFC0C7D4),
          ),
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
            style: TextStyle(fontSize: 14, color: Color(0xFF8E9AAE)),
          ),
        ],
      ),
    );
  }
}
