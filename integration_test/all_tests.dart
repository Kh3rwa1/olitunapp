import 'package:integration_test/integration_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'admob_integration_test.dart' as admob;
import 'auth_flow_test.dart' as auth_flow;
import 'legal_smoke_test.dart' as legal_smoke;
import 'quiz_flow_test.dart' as quiz_flow;
import 'journeys_integration_test.dart' as journeys;

Future<void> main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  try {
    await Hive.initFlutter();
  } catch (_) {}
  admob.main();
  auth_flow.main();
  legal_smoke.main();
  quiz_flow.main();
  journeys.main();
}
