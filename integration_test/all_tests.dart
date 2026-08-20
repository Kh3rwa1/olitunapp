import 'package:integration_test/integration_test.dart';
import 'auth_flow_test.dart' as auth_flow;
import 'legal_smoke_test.dart' as legal_smoke;
import 'quiz_flow_test.dart' as quiz_flow;
import 'journeys_integration_test.dart' as journeys;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  auth_flow.main();
  legal_smoke.main();
  quiz_flow.main();
  journeys.main();
}
