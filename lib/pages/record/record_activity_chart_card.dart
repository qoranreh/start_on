import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart' as neu;
import 'package:start_on/models/app_local_data.dart';
import 'package:start_on/widgets/common.dart';

class RecordActivityChartCard extends StatelessWidget {
  const RecordActivityChartCard({super.key, required this.data});

  final AppLocalData data;

  @override
  Widget build(BuildContext context) {
    const labels = ['월', '화', '수', '목', '금', '토', '일'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeading(
          icon: Icons.calendar_today_outlined,
          title: '이번 주 활동',
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 150,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(data.weeklyActivityBars.length, (index) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == data.weeklyActivityBars.length - 1
                        ? 0
                        : 10,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: SizedBox.expand(
                            child: FractionallySizedBox(
                              alignment: Alignment.bottomCenter,
                              heightFactor: data.weeklyActivityBars[index],
                              child: neu.Neumorphic(
                                style: neu.NeumorphicStyle(
                                  depth: 5,
                                  intensity: 0.88,
                                  surfaceIntensity: 0.22,
                                  color: const Color(0xFFFFC8B0),
                                  shadowLightColor: Colors.white.withValues(
                                    alpha: 0.96,
                                  ),
                                  shadowDarkColor: const Color(
                                    0xFFFFA79E,
                                  ).withValues(alpha: 0.4),
                                  boxShape:
                                      neu.NeumorphicBoxShape.roundRect(
                                        BorderRadius.circular(14),
                                      ),
                                ),
                                child: const SizedBox.expand(),
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
    );
  }
}
