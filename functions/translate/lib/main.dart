import 'dart:convert';
import 'dart:io';

/// Olitun Translate — Appwrite Function
///
/// Replaces the PHP proxy at olitun.in/admin-panel/api/v1/translate.php
/// Uses Google Translate's free API via HTTP.
///
/// Deploy: appwrite functions createDeployment \
///   --functionId=translate --entrypoint=lib/main.dart --code=.
///
/// Environment variables:
///   RATE_LIMIT_PER_MINUTE (default: 30)

Future<dynamic> main(final context) async {
  final method = context.req.method;

  // CORS preflight
  if (method == 'OPTIONS') {
    return context.res.send('', 204, _corsHeaders());
  }

  if (method != 'POST') {
    return context.res.json(
      {'success': false, 'message': 'POST only'},
      405,
      _corsHeaders(),
    );
  }

  try {
    final body = jsonDecode(context.req.body ?? '{}');
    final text = body['text']?.toString().trim() ?? '';
    final from = body['from']?.toString() ?? 'auto';
    final to = body['to']?.toString() ?? 'sat';

    if (text.isEmpty) {
      return context.res.json(
        {'success': false, 'message': 'Missing "text" field'},
        400,
        _corsHeaders(),
      );
    }

    if (text.length > 5000) {
      return context.res.json(
        {'success': false, 'message': 'Text too long (max 5000 chars)'},
        400,
        _corsHeaders(),
      );
    }

    // Call Google Translate
    final uri = Uri.parse(
      'https://translate.googleapis.com/translate_a/single'
      '?client=gtx&sl=$from&tl=$to&dt=t'
      '&q=${Uri.encodeQueryComponent(text)}',
    );

    final client = HttpClient();
    final request = await client.getUrl(uri);
    request.headers.set('User-Agent', 'OlitunApp/1.0');
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    client.close();

    if (response.statusCode != 200) {
      return context.res.json(
        {'success': false, 'message': 'Google API error: ${response.statusCode}'},
        502,
        _corsHeaders(),
      );
    }

    final parsed = jsonDecode(responseBody);
    final translation = _extractTranslation(parsed);
    final detectedLang = parsed[2]?.toString() ?? from;

    return context.res.json({
      'success': true,
      'data': {
        'translation': translation,
        'detectedLanguage': detectedLang,
        'from': from,
        'to': to,
        'cached': false,
      },
    }, 200, _corsHeaders());
  } catch (e) {
    context.error('Translate error: $e');
    return context.res.json(
      {'success': false, 'message': 'Internal error'},
      500,
      _corsHeaders(),
    );
  }
}

String _extractTranslation(dynamic parsed) {
  if (parsed is List && parsed.isNotEmpty && parsed[0] is List) {
    final buffer = StringBuffer();
    for (final segment in parsed[0]) {
      if (segment is List && segment.isNotEmpty) {
        buffer.write(segment[0]?.toString() ?? '');
      }
    }
    return buffer.toString();
  }
  return '';
}

Map<String, String> _corsHeaders() => {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};
