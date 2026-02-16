import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

/// Configuration for API
class ApiConfig {
  static const String baseUrl = 'http://www.olitun.in/admin-panel/api/v1';
}

/// Centralized API Service for handling HTTP requests
class ApiService {
  final http.Client _client = http.Client();

  /// GET Request
  Future<dynamic> get(String endpoint, {Map<String, String>? params}) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}$endpoint',
      ).replace(queryParameters: params);
      debugPrint('API CALL: $uri');
      final response = await _client.get(uri);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network Error: $e');
    }
  }

  /// POST Request
  Future<dynamic> post(String endpoint, dynamic data) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network Error: $e');
    }
  }

  /// PUT Request
  Future<dynamic> put(String endpoint, dynamic data) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final response = await _client.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network Error: $e');
    }
  }

  /// DELETE Request
  Future<dynamic> delete(String endpoint, {Map<String, String>? params}) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}$endpoint',
      ).replace(queryParameters: params);
      final response = await _client.delete(uri);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network Error: $e');
    }
  }

  /// Handle HTTP Response
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = jsonDecode(response.body);
      if (body is Map && body.containsKey('data')) {
        return body['data'];
      }
      return body; // Fallback if no 'data' wrapper
    } else {
      throw Exception('API Error ${response.statusCode}: ${response.body}');
    }
  }
}

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
