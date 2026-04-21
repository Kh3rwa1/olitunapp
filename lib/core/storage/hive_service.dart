import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Global SharedPreferences instance
late SharedPreferences prefs;

/// Centralized storage initialization
Future<void> initStorage() async {
  // Initialize SharedPreferences
  prefs = await SharedPreferences.getInstance();

  // Initialize Hive
  await Hive.initFlutter();
}
