import 'package:integration_test/integration_test_driver.dart';

/// Runs the native suite kept under test/desktop instead of the project root.
Future<void> main() => integrationDriver(responseDataCallback: null);
