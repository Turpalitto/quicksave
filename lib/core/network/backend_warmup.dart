import 'package:dio/dio.dart';

import '../constants/app_constants.dart';

/// Hosts that sleep on free tiers and need longer timeouts + retries.
bool backendNeedsWarmUp(String backendUrl) {
  final lower = backendUrl.toLowerCase();
  return lower.contains('onrender.com') ||
      lower.contains('railway.app') ||
      lower.contains('fly.dev');
}

int backendResolveMaxAttempts(String backendUrl) =>
    backendNeedsWarmUp(backendUrl) ? 3 : 1;

Duration backendResolveTimeout(String backendUrl) =>
    backendNeedsWarmUp(backendUrl)
        ? const Duration(seconds: 40)
        : AppConstants.networkTimeout;

/// Hard cap so the preview screen never spins for 3+ minutes on a dead host.
Duration backendResolveOverallTimeout(String backendUrl) =>
    backendNeedsWarmUp(backendUrl)
        ? const Duration(seconds: 90)
        : AppConstants.networkTimeout;

bool shouldRetryBackendRequest(DioExceptionType type) {
  return type == DioExceptionType.connectionTimeout ||
      type == DioExceptionType.connectionError ||
      type == DioExceptionType.receiveTimeout ||
      type == DioExceptionType.sendTimeout;
}
