import 'package:equatable/equatable.dart';

sealed class AdError extends Equatable {
  final String message;
  final String? code;

  const AdError(this.message, [this.code]);

  @override
  List<Object?> get props => [message, code];
}

final class AdInitError extends AdError {
  const AdInitError(super.message, [super.code]);
}

final class AdLoadError extends AdError {
  const AdLoadError(super.message, [super.code]);
}

final class AdNotReadyError extends AdError {
  const AdNotReadyError([
    String message = 'Ad is not loaded or ready to display',
  ]) : super(message, 'AD_NOT_READY');
}

final class AdFrequencyCappedError extends AdError {
  const AdFrequencyCappedError([String message = 'Ad frequency cap in effect'])
    : super(message, 'FREQUENCY_CAPPED');
}

final class AdDisabledError extends AdError {
  const AdDisabledError([
    String message = 'Ads are disabled for this user or globally',
  ]) : super(message, 'ADS_DISABLED');
}

final class AdNetworkError extends AdError {
  const AdNetworkError([String message = 'Network connection unavailable'])
    : super(message, 'NETWORK_UNAVAILABLE');
}

final class AdConsentError extends AdError {
  const AdConsentError(super.message, [super.code]);
}

final class AdPlatformUnsupportedError extends AdError {
  const AdPlatformUnsupportedError([
    String message = 'Ads not supported on this platform',
  ]) : super(message, 'PLATFORM_UNSUPPORTED');
}
