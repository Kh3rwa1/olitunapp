import 'package:shared_preferences/shared_preferences.dart';

/// Global SharedPreferences instance
late SharedPreferences prefs;

/// Centralized storage initialization
Future<void> initStorage() async {
  prefs = await SharedPreferences.getInstance();
}
