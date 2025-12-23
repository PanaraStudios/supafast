// Clean test runner for Supafast framework
// Run with: dart test test/all_tests_clean.dart

import 'package:test/test.dart';

// Import working unit tests
import 'unit/path_matcher_test.dart' as path_matcher_tests;
import 'unit/router_test.dart' as router_tests;
import 'unit/request_response_test.dart' as request_response_tests;

// Import working middleware tests
import 'middleware/cors_test.dart' as cors_tests;
import 'middleware/body_parser_test.dart' as body_parser_tests;
import 'middleware/logger_test.dart' as logger_tests;
import 'middleware/error_handler_test.dart' as error_handler_tests;

// Import integration tests
import 'integration/basic_integration_test.dart' as integration_tests;

void main() {
  group('Supafast Framework - Clean Test Suite', () {
    group('Core Utilities', () {
      path_matcher_tests.main();
    });

    group('Core Framework', () {
      router_tests.main();
      request_response_tests.main();
    });

    group('Middleware', () {
      cors_tests.main();
      body_parser_tests.main();
      logger_tests.main();
      error_handler_tests.main();
    });

    group('Integration', () {
      integration_tests.main();
    });
  });
}
