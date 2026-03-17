import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/post.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Custom exceptions
// ─────────────────────────────────────────────────────────────────────────────
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

// ─────────────────────────────────────────────────────────────────────────────
// API Service
// ─────────────────────────────────────────────────────────────────────────────
class ApiService {
  static const String _baseUrl =
      'https://jsonplaceholder.typicode.com';

  static const Duration _timeout = Duration(seconds: 15);

  static final Map<String, String> _headers = {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
  };

  // ── Helper ───────────────────────────────────────────────────
  static Future<http.Response> _safeRequest(
      Future<http.Response> Function() request) async {
    try {
      final response = await request().timeout(_timeout);
      return response;
    } on SocketException {
      throw const NetworkException(
          'No internet connection. Please check your network.');
    } on HttpException {
      throw const NetworkException('Could not reach the server.');
    } catch (e) {
      throw NetworkException('Unexpected error: $e');
    }
  }

  static void _checkStatus(http.Response response,
      {List<int> expected = const [200, 201]}) {
    if (!expected.contains(response.statusCode)) {
      throw ApiException(
        _statusMessage(response.statusCode),
        statusCode: response.statusCode,
      );
    }
  }

  static String _statusMessage(int code) {
    switch (code) {
      case 400:
        return 'Bad request — please check your input.';
      case 401:
        return 'Unauthorized — please log in again.';
      case 403:
        return 'Forbidden — you don\'t have permission.';
      case 404:
        return 'Not found — this post no longer exists.';
      case 422:
        return 'Validation failed — please check your input.';
      case 500:
        return 'Server error — please try again later.';
      default:
        return 'Something went wrong (HTTP $code).';
    }
  }

  // ── GET all posts ─────────────────────────────────────────────
  static Future<List<Post>> getPosts() async {
    final response = await _safeRequest(
      () => http.get(
        Uri.parse('$_baseUrl/posts'),
        headers: _headers,
      ),
    );
    _checkStatus(response);
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Post.fromJson(json)).toList();
  }

  // ── GET single post ───────────────────────────────────────────
  static Future<Post> getPost(int id) async {
    final response = await _safeRequest(
      () => http.get(
        Uri.parse('$_baseUrl/posts/$id'),
        headers: _headers,
      ),
    );
    _checkStatus(response);
    return Post.fromJson(jsonDecode(response.body));
  }

  // ── POST create post ──────────────────────────────────────────
  static Future<Post> createPost({
    required String title,
    required String body,
    int userId = 1,
  }) async {
    final response = await _safeRequest(
      () => http.post(
        Uri.parse('$_baseUrl/posts'),
        headers: _headers,
        body: jsonEncode({
          'title': title,
          'body': body,
          'userId': userId,
        }),
      ),
    );
    _checkStatus(response, expected: [200, 201]);
    return Post.fromJson(jsonDecode(response.body));
  }

  // ── PUT update post ───────────────────────────────────────────
  static Future<Post> updatePost(Post post) async {
    final response = await _safeRequest(
      () => http.put(
        Uri.parse('$_baseUrl/posts/${post.id}'),
        headers: _headers,
        body: jsonEncode(post.toJson()),
      ),
    );
    _checkStatus(response);
    return Post.fromJson(jsonDecode(response.body));
  }

  // ── PATCH partial update ──────────────────────────────────────
  static Future<Post> patchPost(int id,
      {String? title, String? body}) async {
    final Map<String, dynamic> payload = {};
    if (title != null) payload['title'] = title;
    if (body != null) payload['body'] = body;

    final response = await _safeRequest(
      () => http.patch(
        Uri.parse('$_baseUrl/posts/$id'),
        headers: _headers,
        body: jsonEncode(payload),
      ),
    );
    _checkStatus(response);
    return Post.fromJson(jsonDecode(response.body));
  }

  // ── DELETE post ───────────────────────────────────────────────
  static Future<void> deletePost(int id) async {
    final response = await _safeRequest(
      () => http.delete(
        Uri.parse('$_baseUrl/posts/$id'),
        headers: _headers,
      ),
    );
    // JSONPlaceholder returns 200 with empty body on delete
    if (response.statusCode != 200) {
      _checkStatus(response, expected: [200]);
    }
  }
}
