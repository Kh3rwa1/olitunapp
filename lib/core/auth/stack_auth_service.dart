import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StackAuthService {
  final String baseUrl = 'https://api.stack-auth.com/api/v1';
  final String projectId;
  final String publishableKey;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'X-Stack-Project-Id': projectId,
    'X-Stack-Publishable-Client-Key': publishableKey,
    'X-Stack-Access-Type': 'client',
  };

  final _storage = const FlutterSecureStorage();

  StackAuthService({required this.projectId, required this.publishableKey});

  static const _tokenKey = 'stack_auth_token';
  static const _refreshTokenKey = 'stack_auth_refresh_token';
  static const _otpNonceKey = 'stack_auth_otp_nonce';

  static const _networkError =
      'No internet connection. Please check your network and try again.';
  static const _timeoutError = 'Connection timed out. Please try again.';

  Future<String?> get token async => await _storage.read(key: _tokenKey);

  Future<void> sendOtpCode(String email) async {
    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('$baseUrl/auth/otp/send-sign-in-code'),
            headers: _headers,
            body: jsonEncode({
              'email': email,
              'callback_url': 'https://olitun.in/auth/callback',
            }),
          )
          .timeout(const Duration(seconds: 15));
    } on http.ClientException {
      throw Exception(_networkError);
    } on TimeoutException {
      throw Exception(_timeoutError);
    } catch (_) {
      throw Exception(_networkError);
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['nonce'] != null) {
        await _storage.write(key: _otpNonceKey, value: data['nonce']);
      }
    } else {
      final body = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : {'error': 'Failed to send OTP'};
      throw Exception(body['error'] ?? 'Failed to send OTP code');
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String code) async {
    final nonce = await _storage.read(key: _otpNonceKey);
    final verificationCode = nonce != null ? '$code$nonce' : code;

    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('$baseUrl/auth/otp/sign-in'),
            headers: _headers,
            body: jsonEncode({'code': verificationCode}),
          )
          .timeout(const Duration(seconds: 15));
    } on http.ClientException {
      throw Exception(_networkError);
    } on TimeoutException {
      throw Exception(_timeoutError);
    } catch (_) {
      throw Exception(_networkError);
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _storage.delete(key: _otpNonceKey);
      await _storage.write(key: _tokenKey, value: data['access_token']);
      if (data['refresh_token'] != null) {
        await _storage.write(
          key: _refreshTokenKey,
          value: data['refresh_token'],
        );
      }
      return data;
    } else {
      final body = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : {'error': 'Verification failed'};
      throw Exception(body['error'] ?? 'Invalid or expired code');
    }
  }

  Future<void> signOut() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<Map<String, dynamic>> getMe() async {
    final currentToken = await token;
    if (currentToken == null) throw Exception('No session found');

    final http.Response response;
    try {
      response = await http
          .get(
            Uri.parse('$baseUrl/users/me'),
            headers: {..._headers, 'Authorization': 'Bearer $currentToken'},
          )
          .timeout(const Duration(seconds: 15));
    } on http.ClientException {
      throw Exception(_networkError);
    } on TimeoutException {
      throw Exception(_timeoutError);
    } catch (_) {
      throw Exception(_networkError);
    }

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch user: ${response.body}');
    }
  }

  Future<void> updateMetadata(Map<String, dynamic> metadata) async {
    await updateProfile({'client_metadata': metadata});
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final currentToken = await token;
    if (currentToken == null) throw Exception('No session found');

    final http.Response response;
    try {
      response = await http
          .patch(
            Uri.parse('$baseUrl/users/me'),
            headers: {..._headers, 'Authorization': 'Bearer $currentToken'},
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 15));
    } on http.ClientException {
      throw Exception(_networkError);
    } on TimeoutException {
      throw Exception(_timeoutError);
    } catch (_) {
      throw Exception(_networkError);
    }

    if (response.statusCode != 200) {
      throw Exception('Failed to update profile: ${response.body}');
    }
  }
}
