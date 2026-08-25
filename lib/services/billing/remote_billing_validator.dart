import 'package:dio/dio.dart';

import '../../core/constants/app_constants.dart';
import '../../features/settings/data/settings_repository.dart';

/// Outcome of optional server-side purchase verification.
enum RemoteVerification {
  /// Backend confirmed the purchase.
  verified,

  /// Backend has no verification configured (501) or none reachable.
  notConfigured,

  /// Backend explicitly rejected the purchase (or errored).
  invalid,
}

/// Optional server-side Play purchase verification (self-hosted / hosted backend).
class RemoteBillingValidator {
  RemoteBillingValidator._();
  static final RemoteBillingValidator instance = RemoteBillingValidator._();

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: AppConstants.networkTimeout,
      receiveTimeout: AppConstants.networkTimeout,
    ),
  );

  /// Never treat an unconfigured backend as a successful verification:
  /// [RemoteVerification.notConfigured] lets the caller fall back to the
  /// local Google Play purchase state instead of blindly trusting it.
  Future<RemoteVerification> verifyPlayPurchase({
    required String productId,
    required String purchaseToken,
    required String packageName,
    String? backendUrl,
  }) async {
    final base = backendUrl?.trim();
    if (base == null || base.isEmpty) return RemoteVerification.notConfigured;

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$base/billing/play/verify',
        data: {
          'productId': productId,
          'purchaseToken': purchaseToken,
          'packageName': packageName,
        },
      );
      final data = response.data;
      if (data?['valid'] == true) return RemoteVerification.verified;
      return RemoteVerification.invalid;
    } on DioException catch (e) {
      if (e.response?.statusCode == 501) {
        return RemoteVerification.notConfigured;
      }
      return RemoteVerification.invalid;
    } catch (_) {
      return RemoteVerification.invalid;
    }
  }

  Future<String> effectiveBackendUrl() async {
    final settings = await SettingsRepository.instance.get();
    return settings.effectiveBackendUrl;
  }
}
