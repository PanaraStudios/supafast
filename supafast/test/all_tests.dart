// Comprehensive test runner for all Supafast framework tests
// Run with: dart test test/all_tests.dart

import 'package:test/test.dart';

// Core unit tests
import 'unit/path_matcher_test.dart' as path_matcher_tests;
import 'unit/router_test.dart' as router_tests;
import 'unit/request_response_test.dart' as request_response_tests;

// Middleware tests
import 'middleware/cors_test.dart' as cors_tests;
import 'middleware/body_parser_test.dart' as body_parser_tests;
import 'middleware/logger_test.dart' as logger_tests;
import 'middleware/error_handler_test.dart' as error_handler_tests;

// Integration tests
import 'integration/basic_integration_test.dart' as integration_tests;

void main() {
  group('Supafast Framework - Complete Test Suite', () {
    group('Core Unit Tests', () {
      group('Utils', () {
        path_matcher_tests.main();
      });

      group('Core Classes', () {
        router_tests.main();
        request_response_tests.main();
      });
    });

    group('Middleware Tests', () {
      cors_tests.main();
      body_parser_tests.main();
      logger_tests.main();
      error_handler_tests.main();
    });

    group('Integration Tests', () {
      integration_tests.main();
    });
  });
}
