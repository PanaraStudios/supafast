import 'package:supafast/supafast.dart';

// Mock database
final List<Map<String, dynamic>> users = [
  {
    'id': '1',
    'name': 'Alice Johnson',
    'email': 'alice@example.com',
    'createdAt': '2023-01-01T00:00:00Z',
  },
  {
    'id': '2',
    'name': 'Bob Smith',
    'email': 'bob@example.com',
    'createdAt': '2023-01-02T00:00:00Z',
  },
];

final List<Map<String, dynamic>> posts = [
  {
    'id': '1',
    'title': 'Getting Started with Supafast',
    'content': 'Supafast is a lightweight backend framework for Dart...',
    'authorId': '1',
    'createdAt': '2023-01-03T00:00:00Z',
  },
  {
    'id': '2',
    'title': 'Building REST APIs with Dart',
    'content': 'Learn how to build RESTful APIs using Supafast...',
    'authorId': '2',
    'createdAt': '2023-01-04T00:00:00Z',
  },
];

int _nextUserId = 3;
int _nextPostId = 3;

void main() async {
  final app = Supafast();

  // Global middleware
  app.use(logger());
  app.use(cors());
  app.use(bodyParser());

  // API info route
  app.get('/', (req, res) {
    return res.json({
      'name': 'Supafast REST API Example',
      'version': '1.0.0',
      'endpoints': {
        'users': '/users',
        'posts': '/posts',
      },
      'documentation': 'See the source code for available operations',
    });
  });

  // Health check
  app.get('/health', (req, res) {
    return res.json({
      'status': 'healthy',
      'timestamp': DateTime.now().toIso8601String(),
      'uptime': app.uptime?.inSeconds,
    });
  });

  // User routes
  setupUserRoutes(app);

  // Post routes
  setupPostRoutes(app);

  // Error handling middleware (should be last)
  app.use(errorHandler());

  // Start server
  const port = 3001;
  await app.listen(port);

  print('🚀 REST API running on http://localhost:$port');
  print('');
  print('Available endpoints:');
  print('  GET    /                  - API information');
  print('  GET    /health           - Health check');
  print('  GET    /users            - List all users');
  print('  GET    /users/:id        - Get user by ID');
  print('  POST   /users            - Create new user');
  print('  PUT    /users/:id        - Update user');
  print('  DELETE /users/:id        - Delete user');
  print('  GET    /posts            - List all posts');
  print('  GET    /posts/:id        - Get post by ID');
  print('  POST   /posts            - Create new post');
  print('  PUT    /posts/:id        - Update post');
  print('  DELETE /posts/:id        - Delete post');
  print('');
  print('Try it out:');
  print('  curl http://localhost:$port/users');
  print(
      '  curl -X POST http://localhost:$port/users -H "Content-Type: application/json" -d \'{"name": "John Doe", "email": "john@example.com"}\'');
}

void setupUserRoutes(Supafast app) {
  // List all users
  app.get('/users', (req, res) {
    return res.json(users);
  });

  // Get user by ID
  app.get('/users/:id', (req, res) {
    final id = req.params['id']!;
    final user = users.where((u) => u['id'] == id).firstOrNull;

    if (user == null) {
      return res.notFound('User not found');
    }

    return res.json(user);
  });

  // Create new user
  app.post('/users', (req, res) {
    try {
      final data = req.body as Map<String, dynamic>;

      // Validation
      if (data['name'] == null || data['name'].toString().trim().isEmpty) {
        return res.badRequest('Name is required');
      }

      if (data['email'] == null || data['email'].toString().trim().isEmpty) {
        return res.badRequest('Email is required');
      }

      // Check if email already exists
      final existingUser =
          users.where((u) => u['email'] == data['email']).firstOrNull;
      if (existingUser != null) {
        return res.status(409).json({
          'error': 'Conflict',
          'message': 'Email already exists',
          'statusCode': 409,
        });
      }

      // Create user
      final user = {
        'id': _nextUserId.toString(),
        'name': data['name'].toString().trim(),
        'email': data['email'].toString().trim(),
        'createdAt': DateTime.now().toIso8601String(),
      };

      users.add(user);
      _nextUserId++;

      return res.status(201).json(user);
    } catch (e) {
      return res.badRequest('Invalid JSON data');
    }
  });

  // Update user
  app.put('/users/:id', (req, res) {
    try {
      final id = req.params['id']!;
      final data = req.body as Map<String, dynamic>;

      final userIndex = users.indexWhere((u) => u['id'] == id);
      if (userIndex == -1) {
        return res.notFound('User not found');
      }

      // Update user
      final user = users[userIndex];
      if (data['name'] != null) {
        user['name'] = data['name'].toString().trim();
      }
      if (data['email'] != null) {
        // Check email uniqueness
        final existingUser = users
            .where((u) => u['email'] == data['email'] && u['id'] != id)
            .firstOrNull;
        if (existingUser != null) {
          return res.status(409).json({
            'error': 'Conflict',
            'message': 'Email already exists',
            'statusCode': 409,
          });
        }
        user['email'] = data['email'].toString().trim();
      }
      user['updatedAt'] = DateTime.now().toIso8601String();

      users[userIndex] = user;

      return res.json(user);
    } catch (e) {
      return res.badRequest('Invalid JSON data');
    }
  });

  // Delete user
  app.delete('/users/:id', (req, res) {
    final id = req.params['id']!;
    final userIndex = users.indexWhere((u) => u['id'] == id);

    if (userIndex == -1) {
      return res.notFound('User not found');
    }

    users.removeAt(userIndex);

    // Also remove posts by this user
    posts.removeWhere((p) => p['authorId'] == id);

    return res.status(204).send('');
  });
}

void setupPostRoutes(Supafast app) {
  // List all posts
  app.get('/posts', (req, res) {
    // Add author information
    final postsWithAuthors = posts.map((post) {
      final author =
          users.where((u) => u['id'] == post['authorId']).firstOrNull;
      return {
        ...post,
        'author': author != null
            ? {
                'id': author['id'],
                'name': author['name'],
                'email': author['email'],
              }
            : null,
      };
    }).toList();

    return res.json(postsWithAuthors);
  });

  // Get post by ID
  app.get('/posts/:id', (req, res) {
    final id = req.params['id']!;
    final post = posts.where((p) => p['id'] == id).firstOrNull;

    if (post == null) {
      return res.notFound('Post not found');
    }

    // Add author information
    final author = users.where((u) => u['id'] == post['authorId']).firstOrNull;
    final postWithAuthor = {
      ...post,
      'author': author != null
          ? {
              'id': author['id'],
              'name': author['name'],
              'email': author['email'],
            }
          : null,
    };

    return res.json(postWithAuthor);
  });

  // Create new post
  app.post('/posts', (req, res) {
    try {
      final data = req.body as Map<String, dynamic>;

      // Validation
      if (data['title'] == null || data['title'].toString().trim().isEmpty) {
        return res.badRequest('Title is required');
      }

      if (data['content'] == null ||
          data['content'].toString().trim().isEmpty) {
        return res.badRequest('Content is required');
      }

      if (data['authorId'] == null ||
          data['authorId'].toString().trim().isEmpty) {
        return res.badRequest('Author ID is required');
      }

      // Check if author exists
      final author =
          users.where((u) => u['id'] == data['authorId']).firstOrNull;
      if (author == null) {
        return res.badRequest('Author not found');
      }

      // Create post
      final post = {
        'id': _nextPostId.toString(),
        'title': data['title'].toString().trim(),
        'content': data['content'].toString().trim(),
        'authorId': data['authorId'].toString(),
        'createdAt': DateTime.now().toIso8601String(),
      };

      posts.add(post);
      _nextPostId++;

      return res.status(201).json(post);
    } catch (e) {
      return res.badRequest('Invalid JSON data');
    }
  });

  // Update post
  app.put('/posts/:id', (req, res) {
    try {
      final id = req.params['id']!;
      final data = req.body as Map<String, dynamic>;

      final postIndex = posts.indexWhere((p) => p['id'] == id);
      if (postIndex == -1) {
        return res.notFound('Post not found');
      }

      // Update post
      final post = posts[postIndex];
      if (data['title'] != null) {
        post['title'] = data['title'].toString().trim();
      }
      if (data['content'] != null) {
        post['content'] = data['content'].toString().trim();
      }
      post['updatedAt'] = DateTime.now().toIso8601String();

      posts[postIndex] = post;

      return res.json(post);
    } catch (e) {
      return res.badRequest('Invalid JSON data');
    }
  });

  // Delete post
  app.delete('/posts/:id', (req, res) {
    final id = req.params['id']!;
    final postIndex = posts.indexWhere((p) => p['id'] == id);

    if (postIndex == -1) {
      return res.notFound('Post not found');
    }

    posts.removeAt(postIndex);

    return res.status(204).send('');
  });
}
