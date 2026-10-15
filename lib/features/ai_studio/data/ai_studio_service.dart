import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/auth/account_scope.dart';
import '../../../core/auth/edge_auth.dart';
import '../../../core/config/cloudflare_config.dart';

const studioLanguages = {
  'hi-IN': 'Hindi',
  'bn-IN': 'Bengali',
  'as-IN': 'Assamese',
  'od-IN': 'Odia',
  'sat-IN': 'Santali',
};

class StudioInput {
  const StudioInput({required this.bytes, required this.name});
  final Uint8List bytes;
  final String name;
}

class StudioJob {
  const StudioJob({required this.id, required this.status, this.text = ''});
  final String id;
  final String status;
  final String text;
  bool get isTerminal => const {
    'completed',
    'partially_completed',
    'failed',
    'rejected',
  }.contains(status);

  factory StudioJob.fromJson(Map<String, dynamic> data) {
    if (data['jobId'] is! String || data['status'] is! String) {
      throw const StudioException('INVALID_RESPONSE');
    }
    return StudioJob(
      id: data['jobId'] as String,
      status: data['status'] as String,
      text: data['text'] is String ? data['text'] as String : '',
    );
  }
}

class StudioException implements Exception {
  const StudioException(this.code);
  final String code;
  String get userMessage => switch (code) {
    'UNAUTHENTICATED' || 'LOGIN_REQUIRED' || 'SESSION_REQUIRED' =>
      'Please sign in again, then retry. Your input is still here.',
    'QUOTA_EXCEEDED' || 'RATE_LIMITED' =>
      'The AI processing allowance is temporarily reached. Please try later.',
    'INVALID_INPUT' || 'INVALID_FILE' || 'INVALID_TEXT' =>
      'Check the selected language, file format and input limits.',
    'INVALID_AUDIO' =>
      'The recording is invalid or too long. Record a clip of 30 seconds or less.',
    'MIC_PERMISSION' =>
      'Allow microphone access in your browser or device settings, then try again.',
    'REQUEST_NOT_REPLAYABLE' =>
      'This request is pending or could not be confirmed. It will not be submitted again automatically.',
    'PROVIDER_UNAVAILABLE' =>
      'Sarvam could not complete this request. Please try later.',
    'ACCOUNT_CHANGED' =>
      'Your account changed. Reopen AI Studio before trying again.',
    _ => 'AI processing could not finish. Please try again later.',
  };
  @override
  String toString() => 'AI Studio: $code';
}

typedef StudioCall =
    Future<Map<String, dynamic>> Function(
      Map<String, dynamic> body,
      StudioInput? input,
    );

/// Separate paid workflows; the existing free translation service is unchanged.
class AiStudioService {
  AiStudioService({required StudioCall call, required this.configured})
    : _call = call;
  final StudioCall _call;
  final bool configured;

  void _language(String language, {bool translation = false}) {
    if (!studioLanguages.containsKey(language) ||
        (translation && language == 'sat-IN')) {
      throw const StudioException('UNSUPPORTED_LANGUAGE');
    }
    if (!configured) throw const StudioException('NOT_CONFIGURED');
  }

  Future<String> translate(String text, String language) async {
    _language(language, translation: true);
    if (text.trim().isEmpty || text.runes.length > 2000) {
      throw const StudioException('INVALID_TEXT');
    }
    return _text(
      await _call({
        'action': 'translate',
        'text': text.trim(),
        'language': language,
      }, null),
    );
  }

  Future<String> transcribe(StudioInput input, String language) async {
    _language(language);
    _input(input, audio: true);
    return _text(
      await _call({'action': 'transcribe', 'language': language}, input),
    );
  }

  Future<StudioJob> startOcr(StudioInput input, String language) async {
    _language(language);
    _input(input, audio: false);
    return StudioJob.fromJson(
      await _call({'action': 'ocrStart', 'language': language}, input),
    );
  }

  Future<StudioJob> pollOcr(String jobId) async {
    if (!configured) throw const StudioException('NOT_CONFIGURED');
    if (!RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9._-]{0,35}$').hasMatch(jobId)) {
      throw const StudioException('INVALID_JOB');
    }
    return StudioJob.fromJson(
      await _call({'action': 'ocrStatus', 'jobId': jobId}, null),
    );
  }

  static void _input(StudioInput input, {required bool audio}) {
    final extension = input.name.split('.').last.toLowerCase();
    if (input.bytes.isEmpty ||
        input.bytes.length > 10 * 1024 * 1024 ||
        !(audio ? ['wav'] : ['pdf', 'png', 'jpg', 'jpeg']).contains(
          extension,
        )) {
      throw const StudioException('INVALID_FILE');
    }
  }

  static String _text(Map<String, dynamic> data) {
    final text = data['text'];
    if (text is! String || text.trim().isEmpty) {
      throw const StudioException('EMPTY_RESULT');
    }
    return text;
  }
}

final aiStudioServiceProvider = Provider<AiStudioService>((ref) {
  final transport = _StudioTransport(EdgeAuth.instance);
  final subscription = AccountScope.changes.listen((_) {
    transport.active = false;
    ref.invalidateSelf();
  });
  ref.onDispose(() {
    transport.active = false;
    subscription.cancel();
  });
  return AiStudioService(
    call: transport.call,
    configured: CloudflareConfig.baseUrl.isNotEmpty,
  );
});

/// Sends Studio requests to the Cloudflare Worker, signed with the session
/// JWT. Input files travel inline as base64.
class _StudioTransport {
  _StudioTransport(this.edgeAuth);
  final EdgeAuth edgeAuth;
  bool active = true;

  static const _url = '${CloudflareConfig.baseUrl}/api/v1/studio/process';

  void _check() {
    if (!active) throw const StudioException('ACCOUNT_CHANGED');
  }

  Future<Map<String, dynamic>> call(
    Map<String, dynamic> body,
    StudioInput? input,
  ) => AccountScope.dispatch(() => _callWithSession(body, input));

  Future<Map<String, dynamic>> _callWithSession(
    Map<String, dynamic> body,
    StudioInput? input,
  ) async {
    _check();
    final payload = Map<String, dynamic>.from(body);
    if (input != null && input.bytes.isNotEmpty) {
      payload['audioBase64'] = base64Encode(input.bytes);
      payload['fileBase64'] = base64Encode(input.bytes);
      payload['fileName'] = input.name;
    }
    final authHeaders = await edgeAuth.headers();
    _check();
    final http.Response res;
    try {
      res = await http
          .post(
            Uri.parse(_url),
            headers: {'Content-Type': 'application/json', ...authHeaders},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 60));
    } catch (_) {
      throw const StudioException('REQUEST_FAILED');
    }
    _check();
    Object? decoded;
    try {
      decoded = jsonDecode(res.body);
    } catch (_) {
      throw const StudioException('INVALID_RESPONSE');
    }
    if (res.statusCode == 200 &&
        decoded is Map &&
        (decoded['success'] == true || decoded['ok'] == true) &&
        decoded['data'] is Map) {
      return Map<String, dynamic>.from(decoded['data'] as Map);
    }
    throw StudioException(
      decoded is Map && decoded['error'] is String
          ? decoded['error'] as String
          : 'REQUEST_FAILED',
    );
  }
}
