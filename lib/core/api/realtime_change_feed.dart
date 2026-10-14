import 'dart:async';

import 'package:appwrite/appwrite.dart';

import '../auth/appwrite_auth_service.dart';

/// Neutral, Appwrite-free view of one realtime database change event.
class RealtimeChangeEvent {
  const RealtimeChangeEvent({
    required this.events,
    required this.channels,
    required this.payload,
  });

  final List<String> events;
  final List<String> channels;
  final Map<String, dynamic> payload;
}

/// An open realtime subscription. Call [close] to stop receiving events.
abstract interface class RealtimeChangeSubscription {
  Stream<RealtimeChangeEvent> get stream;
  Future<void> close();
}

/// Anti-corruption seam over Appwrite Realtime so shared/feature layers can
/// react to backend changes without importing `package:appwrite`.
abstract interface class RealtimeChangeFeed {
  RealtimeChangeSubscription subscribe(List<String> channels);
}

/// [RealtimeChangeFeed] backed by the Appwrite Realtime websocket.
class AppwriteRealtimeChangeFeed implements RealtimeChangeFeed {
  AppwriteRealtimeChangeFeed(this._realtime);

  /// Builds a feed on the app-wide authenticated Appwrite client.
  factory AppwriteRealtimeChangeFeed.fromAuth([AppwriteAuthService? auth]) =>
      AppwriteRealtimeChangeFeed(
        Realtime((auth ?? AppwriteAuthService()).client),
      );

  final Realtime _realtime;

  @override
  RealtimeChangeSubscription subscribe(List<String> channels) =>
      _AppwriteRealtimeChangeSubscription(_realtime.subscribe(channels));
}

class _AppwriteRealtimeChangeSubscription
    implements RealtimeChangeSubscription {
  _AppwriteRealtimeChangeSubscription(this._subscription);

  final RealtimeSubscription _subscription;

  @override
  late final Stream<RealtimeChangeEvent> stream = _subscription.stream.map(
    (message) => RealtimeChangeEvent(
      events: message.events,
      channels: message.channels,
      payload: message.payload,
    ),
  );

  @override
  Future<void> close() => _subscription.close();
}
