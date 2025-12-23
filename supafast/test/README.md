# Supafast Test Suite

This directory contains comprehensive tests for the Supafast framework, ensuring quality, reliability, and maintainability for contributors.

## Test Structure

### Unit Tests (`unit/`)
- **Core Classes**: Tests for the main framework components
  - `supafast_app_test.dart` - Main application class functionality
  - `router_test.dart` - Routing and path matching logic
  - `middleware_test.dart` - Middleware chain execution
  - `request_response_test.dart` - Request/Response object functionality
  - `error_handling_test.dart` - Error handling and edge cases

- **Utilities**: Tests for helper utilities
  - `path_matcher_test.dart` - URL path pattern matching
  - `query_parser_test.dart` - Query string parsing
  - `content_type_test.dart` - MIME type detection

### Middleware Tests (`middleware/`)
- `cors_test.dart` - CORS middleware functionality
- `body_parser_test.dart` - Request body parsing (JSON, form data, multipart)
- `logger_test.dart` - Request/response logging
- `error_handler_test.dart` - Error handling middleware
- `static_files_test.dart` - Static file serving

### Integration Tests (`integration/`)
- `basic_integration_test.dart` - End-to-end framework functionality

## Running Tests

### Run All Tests
```bash
# From the package root
dart test

# Run specific test file
dart test test/unit/router_test.dart

# Run all tests with coverage
dart test --coverage=coverage

# Run tests with detailed output
dart test --reporter=expanded
```

### Run Test Groups
```bash
# Run only unit tests
dart test test/unit/

# Run only middleware tests
dart test test/middleware/

# Run only integration tests
dart test test/integration/
```

### Comprehensive Test Runner
```bash
# Run the complete test suite
dart test test/all_tests.dart
```

## Test Coverage Areas

### ✅ **Core Framework**
- HTTP method routing (GET, POST, PUT, DELETE, etc.)
- Path parameter extraction (`:id`, `:userId`)
- Query parameter parsing
- Request/Response object functionality
- Middleware chain execution
- Nested router mounting
- Error handling and propagation

### ✅ **Built-in Middleware**
- **CORS**: Origin validation, preflight requests, credentials
- **Body Parser**: JSON, form data, multipart file uploads
- **Logger**: Multiple formats, custom loggers, request timing
- **Error Handler**: Custom formatters, stack traces, logging
- **Static Files**: File serving, security, caching, compression

### ✅ **Security**
- Directory traversal prevention
- Input validation
- Error information disclosure
- Header injection prevention

### ✅ **Performance**
- Large request handling
- Concurrent request processing
- Memory usage optimization
- Response streaming

### ✅ **Edge Cases**
- Malformed requests
- Unicode handling
- Special characters
- Async error handling
- Resource cleanup

## Test Quality Standards

### Test Organization
- **Descriptive Names**: Each test clearly describes what it's testing
- **Grouped Tests**: Related tests are organized in logical groups
- **Setup/Teardown**: Proper test isolation with setUp/tearDown
- **Mock Data**: Realistic test data and scenarios

### Coverage Goals
- **Line Coverage**: >90% for core framework code
- **Branch Coverage**: >85% for conditional logic
- **Function Coverage**: 100% for public API methods
- **Error Paths**: All error conditions tested

### Test Types
1. **Unit Tests**: Individual function/method testing
2. **Integration Tests**: Component interaction testing
3. **End-to-End Tests**: Full request/response cycle testing
4. **Performance Tests**: Load and stress testing scenarios
5. **Security Tests**: Vulnerability and attack vector testing

## Contributing to Tests

### Adding New Tests
1. **Location**: Place tests in the appropriate directory
   - Unit tests: `test/unit/`
   - Middleware tests: `test/middleware/`
   - Integration tests: `test/integration/`

2. **Naming**: Follow the naming convention
   - File: `feature_name_test.dart`
   - Groups: `'FeatureName'`
   - Tests: `'should do something when condition'`

3. **Structure**: Use consistent test structure
   ```dart
   import 'package:test/test.dart';
   import 'package:supafast/supafast.dart';
   import 'package:supafast/testing.dart';

   void main() {
     group('FeatureName', () {
       late TestApp testApp;
       
       setUp(() async {
         // Test setup
       });
       
       tearDown(() async {
         // Cleanup
       });
       
       group('specific functionality', () {
         test('should behave correctly when...', () async {
           // Test implementation
         });
       });
     });
   }
   ```

### Test Documentation
- **Purpose**: Explain what the test verifies
- **Setup**: Document any special test setup requirements
- **Assertions**: Use descriptive assertion messages
- **Edge Cases**: Document why edge cases are tested

### Best Practices
- **Independent Tests**: Tests should not depend on each other
- **Deterministic**: Tests should produce consistent results
- **Fast Execution**: Keep tests fast and focused
- **Clear Failures**: Test failures should be easy to understand
- **Realistic Data**: Use data that represents real-world usage

## Test Utilities

### TestApp Helper
The `TestApp` class provides a convenient way to test HTTP endpoints:

```dart
final testApp = TestApp(app);
await testApp.start();

final response = await testApp.get('/api/users/123')
  .header('authorization', 'Bearer token')
  .send();

expect(response.statusCode, equals(200));
expect(response.json['id'], equals('123'));

await testApp.close();
```

### TestRequest Builder
Fluent API for building test requests:

```dart
await testApp.post('/api/users')
  .json({'name': 'John', 'age': 30})
  .header('content-type', 'application/json')
  .expect(201)
  .expectJson({'id': isNotNull});
```

### TestResponse Helpers
Convenient assertions for responses:

```dart
final response = await testApp.get('/test').send();

expect(response.isJson, isTrue);
expect(response.json['message'], equals('success'));
expect(response.hasHeader('x-custom-header'), isTrue);
```

## Continuous Integration

The test suite is designed to run in CI environments:

### GitHub Actions
```yaml
- name: Run tests
  run: dart test --coverage=coverage

- name: Check coverage
  run: dart pub global activate coverage && format_coverage --lcov
```

### Coverage Reports
Generate and view coverage reports:

```bash
# Generate coverage
dart test --coverage=coverage

# Convert to LCOV format
dart pub global activate coverage
dart pub global run coverage:format_coverage \
  --lcov --in=coverage --out=coverage/lcov.info

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html
```

## Debugging Tests

### Running Single Tests
```bash
# Run a specific test
dart test test/unit/router_test.dart -n "should match routes with parameters"

# Run with debugging
dart test --pause-after-load test/unit/router_test.dart
```

### Debug Output
```dart
test('debug test', () {
  print('Debug info: ${variable}');
  // Use setUp/tearDown for debug logging
});
```

### Common Issues
1. **Async/Await**: Ensure proper async handling in tests
2. **Resource Cleanup**: Always close TestApp in tearDown
3. **Test Isolation**: Avoid shared state between tests
4. **Timing Issues**: Use proper awaits for async operations

## Performance Testing

### Load Testing
```dart
test('handles concurrent requests', () async {
  final futures = List.generate(100, (_) => 
    testApp.get('/api/endpoint').send()
  );
  
  final responses = await Future.wait(futures);
  
  for (final response in responses) {
    expect(response.statusCode, equals(200));
  }
});
```

### Memory Testing
```dart
test('handles large payloads', () async {
  final largeData = List.generate(10000, (i) => 'item_$i');
  
  final response = await testApp.post('/api/bulk')
    .json({'items': largeData})
    .send();
  
  expect(response.statusCode, equals(200));
});
```

---

For questions about testing or to report issues with the test suite, please open an issue in the repository.