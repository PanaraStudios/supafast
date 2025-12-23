import 'dart:io';
import 'package:supafast/supafast.dart';

void main() async {
  final app = Supafast();

  // Add logging middleware first to see all requests
  app.use(logger());
  
  // Add a simple debug middleware to see what's happening
  app.use((req, res, next) async {
    print('DEBUG: Request received - ${req.method} ${req.path}');
    await next();
    print('DEBUG: Response status - ${res.statusCode}');
  });

  // Add static file middleware normally
  app.use(serveStatic('public'));

  // Add a catch-all route to see what requests fall through
  app.all('*', (req, res) {
    print('DEBUG: Catch-all route hit for ${req.method} ${req.path}');
    return res.status(404).json({
      'error': 'Not Found',
      'method': req.method,
      'path': req.path,
    });
  });

  print('Starting debug server on port 3001...');
  print('Test with: curl -v http://localhost:3001/styles.css');
  print('Or test with: curl -v http://localhost:3001/index.html');
  print('Current directory: ${Directory.current.path}');
  print('Public directory exists: ${Directory('public').existsSync()}');
  
  await app.listen(3001);
}