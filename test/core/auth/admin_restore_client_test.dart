import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itun/core/auth/admin_restore_client.dart';

class _Preferences extends Mock implements SharedPreferences {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Map<String, dynamic> reply(Map<String, dynamic> request, bool complete) => {
    'success': true,
    'complete': complete,
    'jobId': request['restoreId'],
    'fileId': request['fileId'],
    'phase': complete ? 'complete' : 'restoring',
  };

  test(
    'partial responses retain one operation ID until acknowledged complete',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final requests = <Map<String, dynamic>>[];
      final client = AdminRestoreClient(
        prefs: prefs,
        projectId: 'test',
        newId: () => 'operation1',
        execute: (request) async {
          requests.add(request);
          return reply(request, requests.length == 3);
        },
      );
      final result = await client.restore(fileId: 'backup');
      expect(result['complete'], isTrue);
      expect(
        requests.map((request) => request['restoreId']),
        everyElement('operation1'),
      );
      expect(prefs.containsKey(client.pendingKey('backup')), isFalse);
    },
  );

  test('new client resumes persisted identity after a lost response', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final first = AdminRestoreClient(
      prefs: prefs,
      projectId: 'restart',
      newId: () => 'original',
      execute: (_) async => throw AppwriteException('Lost response', 503),
    );
    await expectLater(
      first.restore(fileId: 'backup'),
      throwsA(isA<AppwriteException>()),
    );
    expect(prefs.getString(first.pendingKey('backup')), 'original');
    final second = AdminRestoreClient(
      prefs: prefs,
      projectId: 'restart',
      newId: () => throw StateError('Must not allocate a new operation'),
      execute: (request) async {
        expect(request['restoreId'], 'original');
        return reply(request, true);
      },
    );
    await second.restore(fileId: 'backup');
  });

  test(
    'pause keeps a resumable operation without starting another chunk',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      var calls = 0;
      final client = AdminRestoreClient(
        prefs: prefs,
        projectId: 'pause',
        newId: () => 'paused',
        execute: (request) async {
          calls++;
          return reply(request, false);
        },
      );
      await expectLater(
        client.restore(fileId: 'backup', shouldContinue: () => calls == 0),
        throwsA(isA<AppwriteException>()),
      );
      expect(calls, 1);
      expect(prefs.getString(client.pendingKey('backup')), 'paused');
    },
  );

  test('unrelated response cannot clear recovery identity', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final client = AdminRestoreClient(
      prefs: prefs,
      projectId: 'binding',
      newId: () => 'mine',
      execute: (request) async => {...reply(request, true), 'jobId': 'other'},
    );
    await expectLater(
      client.restore(fileId: 'backup'),
      throwsA(isA<AppwriteException>()),
    );
    expect(prefs.getString(client.pendingKey('backup')), 'mine');
  });

  test('storage failure prevents any destructive request', () async {
    final prefs = _Preferences();
    when(() => prefs.getString(any())).thenReturn(null);
    when(() => prefs.setString(any(), any())).thenAnswer((_) async => false);
    var calls = 0;
    final client = AdminRestoreClient(
      prefs: prefs,
      projectId: 'storage',
      newId: () => 'safe',
      execute: (request) async {
        calls++;
        return reply(request, true);
      },
    );
    await expectLater(
      client.restore(fileId: 'backup'),
      throwsA(isA<AppwriteException>()),
    );
    expect(calls, 0);
  });

  test('202 means checkpointed progress, not completed restore', () {
    final response = parseAdminRestoreResponse(
      statusCode: 202,
      body: jsonEncode({'success': true, 'complete': false}),
    );
    expect(response['complete'], isFalse);
    expect(
      () =>
          parseAdminRestoreResponse(statusCode: 200, body: '{"success":true}'),
      throwsA(isA<AppwriteException>()),
    );
    expect(
      () =>
          parseAdminRestoreResponse(statusCode: 503, body: '{"success":false}'),
      throwsA(isA<AppwriteException>()),
    );
  });
}
