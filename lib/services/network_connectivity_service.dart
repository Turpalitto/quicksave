import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Device network reachability (Wi‑Fi / mobile), not backend health.
class NetworkConnectivityService {
  NetworkConnectivityService._([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  static final NetworkConnectivityService instance =
      NetworkConnectivityService._();

  final Connectivity _connectivity;

  Future<bool> get hasConnection async {
    if (kIsWeb) return true;
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }
}
