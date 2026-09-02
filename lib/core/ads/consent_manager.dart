import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AdError;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/ad_config.dart';
import '../logging/app_logger.dart';
import 'ad_error.dart';

class ConsentManager {
  static const String consentStatusPrefKey = 'admob_consent_status';

  final SharedPreferences? _prefs;

  ConsentManager([this._prefs]);

  /// Request consent information update from Google UMP.
  Future<Either<AdError, ConsentStatus>> requestConsentInfo() async {
    if (kIsWeb) {
      return right<AdError, ConsentStatus>(ConsentStatus.notRequired);
    }

    final completer = Completer<Either<AdError, ConsentStatus>>();

    final debugSettings = AdConfig.isTestMode
        ? ConsentDebugSettings(
            debugGeography: DebugGeography.debugGeographyEea,
            testIdentifiers: AdConfig.testDeviceIds,
          )
        : null;

    final params = ConsentRequestParameters(
      tagForUnderAgeOfConsent: false,
      consentDebugSettings: debugSettings,
    );

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        try {
          final status = await ConsentInformation.instance.getConsentStatus();
          await _saveConsentStatus(status);
          AppLogger.debug('ConsentManager: Consent info updated: $status');
          completer.complete(right<AdError, ConsentStatus>(status));
        } catch (e) {
          AppLogger.debug('ConsentManager: Failed to read consent status: $e');
          completer.complete(
            right<AdError, ConsentStatus>(ConsentStatus.unknown),
          );
        }
      },
      (FormError error) {
        AppLogger.debug(
          'ConsentManager: UMP request failed: ${error.errorCode} - ${error.message}',
        );
        completer.complete(
          left<AdError, ConsentStatus>(
            AdConsentError(error.message, error.errorCode.toString()),
          ),
        );
      },
    );

    return completer.future;
  }

  /// Show consent form if required by UMP regulations.
  Future<Either<AdError, ConsentStatus>> showConsentFormIfRequired() async {
    if (kIsWeb) {
      return right<AdError, ConsentStatus>(ConsentStatus.notRequired);
    }

    final completer = Completer<Either<AdError, ConsentStatus>>();

    ConsentForm.loadAndShowConsentFormIfRequired((FormError? formError) async {
      if (formError != null) {
        AppLogger.debug(
          'ConsentManager: Consent form error: ${formError.errorCode} - ${formError.message}',
        );
        completer.complete(
          left<AdError, ConsentStatus>(
            AdConsentError(formError.message, formError.errorCode.toString()),
          ),
        );
        return;
      }

      try {
        final status = await ConsentInformation.instance.getConsentStatus();
        await _saveConsentStatus(status);
        AppLogger.debug(
          'ConsentManager: Consent form dismissed. Status: $status',
        );
        completer.complete(right<AdError, ConsentStatus>(status));
      } catch (e) {
        completer.complete(
          right<AdError, ConsentStatus>(ConsentStatus.unknown),
        );
      }
    });

    return completer.future;
  }

  /// Whether ads can be requested based on consent.
  Future<bool> canRequestAds() async {
    if (kIsWeb) return false;
    try {
      return await ConsentInformation.instance.canRequestAds();
    } catch (_) {
      // UMP unavailable (e.g. before initialisation) — do not block ad
      // serving; consent enforcement still happens at form level.
      return true;
    }
  }

  /// Get cached consent status or query UMP.
  Future<ConsentStatus> getConsentStatus() async {
    if (kIsWeb) return ConsentStatus.notRequired;
    try {
      return await ConsentInformation.instance.getConsentStatus();
    } catch (_) {
      // UMP unavailable — fall back to the cached status or unknown.
      final cached = _prefs?.getString(consentStatusPrefKey);
      if (cached != null) {
        return _statusFromString(cached);
      }
      return ConsentStatus.unknown;
    }
  }

  Future<void> _saveConsentStatus(ConsentStatus status) async {
    try {
      await _prefs?.setString(consentStatusPrefKey, status.name);
    } catch (e) {
      AppLogger.debug('ConsentManager: Save to prefs failed: $e');
    }
  }

  static ConsentStatus _statusFromString(String name) {
    switch (name) {
      case 'required':
        return ConsentStatus.required;
      case 'obtained':
        return ConsentStatus.obtained;
      case 'notRequired':
        return ConsentStatus.notRequired;
      default:
        return ConsentStatus.unknown;
    }
  }

  /// Reset consent status (useful for debug/testing).
  Future<void> reset() async {
    if (kIsWeb) return;
    try {
      await ConsentInformation.instance.reset();
      await _prefs?.remove(consentStatusPrefKey);
    } catch (e) {
      AppLogger.debug('ConsentManager: Reset failed: $e');
    }
  }
}
