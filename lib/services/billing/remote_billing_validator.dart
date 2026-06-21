import 'package:dio/dio.dart';

import '../../core/constants/app_constants.dart';
import '../../features/settings/data/settings_repository.dart';

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

  /// Returns true when verification succeeds or backend is not configured.
  Future<bool> verifyPlayPurchase({
    required String productId,
    required String purchaseToken,
    required String packageName,
    String? backendUrl,
  }) async {
    final base = backendUrl?.trim();
    if (base == null || base.isEmpty) return true;

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
      return data?['valid'] == true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 501) return true;
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<String> effectiveBackendUrl() async {
    final settings = await SettingsRepository.instance.get();
    return settings.effectiveBackendUrl;
  }
}
