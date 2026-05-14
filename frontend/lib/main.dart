import 'package:start_on/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:start_on/services/quest_timer_background_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await QuestTimerBackgroundService.instance.initialize();
  runApp(const AdFocusApp());
}
