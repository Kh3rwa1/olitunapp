import 'dart:convert';
import 'dart:typed_data';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/account_scope.dart';
import '../../../core/auth/appwrite_auth_service.dart';
import '../../../core/config/appwrite_config.dart';

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
    'QUOTA_EXCEEDED' =>
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
  final auth = ref.watch(appwriteAuthServiceProvider);
  final transport = _StudioTransport(auth);
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
    configured:
        _studioFunctionId.isNotEmpty && AppwriteConfig.isBackendConfigured,
  );
});

const _studioFunctionId = String.fromEnvironment(
  'AI_STUDIO_FUNCTION_ID',
  defaultValue: 'aiStudio',
);
const _inputBucket = 'ai_studio_inputs';

class _StudioTransport {
  _StudioTransport(this.auth);
  final AppwriteAuthService auth;
  bool active = true;

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
    // Keep the session stable until upload, execution and cleanup finish.
    // A second SDK client still shares cookies; adding setJWT to it causes
    // Appwrite's user_jwt_and_cookie_set rejection. Authenticate SDK requests
    // using the existing session and forward JWT only inside execution headers.
    final token = await auth.account.createJWT();
    _check();
    final client = auth.client;
    final storage = Storage(client);
    String? fileId;
    try {
      final user = await Account(client).get();
      _check();
      if (input != null) {
        fileId = ID.unique();
        final extension = input.name.split('.').last.toLowerCase();
        await storage.createFile(
          bucketId: _inputBucket,
          fileId: fileId,
          file: InputFile.fromBytes(
            bytes: input.bytes,
            filename: 'input.$extension',
          ),
          permissions: [
            Permission.read(Role.user(user.$id)),
            Permission.delete(Role.user(user.$id)),
          ],
        );
        _check();
      }
      final response = await Functions(client).createExecution(
        functionId: _studioFunctionId,
        method: ExecutionMethod.pOST,
        xasync: false,
        headers: {'Authorization': 'Bearer ${token.jwt}'},
        body: jsonEncode({...body, 'fileId': ?fileId}),
      );
      _check();
      final decoded = jsonDecode(response.responseBody);
      if (response.responseStatusCode != 200 ||
          decoded is! Map ||
          decoded['success'] != true ||
          decoded['data'] is! Map) {
        throw StudioException(
          decoded is Map && decoded['error'] is String
              ? decoded['error'] as String
              : 'REQUEST_FAILED',
        );
      }
      return Map<String, dynamic>.from(decoded['data'] as Map);
    } finally {
      if (fileId != null) {
        // OCR submission uploads to Sarvam before acknowledging; it does not
        // need our input file while polling. Best effort cleanup on all paths.
        try {
          await storage.deleteFile(bucketId: _inputBucket, fileId: fileId);
        } catch (_) {
          /* Server retention cleanup handles interrupted uploads. */
        }
      }
    }
  }
}
