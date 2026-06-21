import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/validators.dart';
import '../../../downloader/data/instagram_resolver.dart';
import '../../../downloader/domain/resolve_result.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/web_library_repository.dart';

sealed class WebResolveState {
  const WebResolveState();
}

class WebResolveIdle extends WebResolveState {
  const WebResolveIdle();
}

class WebResolveLoading extends WebResolveState {
  const WebResolveLoading();
}

class WebResolveReady extends WebResolveState {
  final ResolveResult result;
  final String sourceUrl;
  const WebResolveReady({required this.result, required this.sourceUrl});
}

class WebResolveError extends WebResolveState {
  final Failure failure;
  const WebResolveError(this.failure);
}

class WebResolveNotifier extends StateNotifier<WebResolveState> {
  WebResolveNotifier(this._ref) : super(const WebResolveIdle());

  final Ref _ref;

  Future<void> resolve(String rawUrl) async {
    final prepared = Validators.prepareUrl(rawUrl.trim());
    if (prepared == null) {
      state = const WebResolveError(InvalidUrlFailure());
      return;
    }

    state = const WebResolveLoading();
    try {
      final settings = _ref.read(settingsProvider);
      final result = await InstagramResolver.instance.resolve(
        instagramUrl: prepared,
        backendUrl: settings.effectiveBackendUrl,
      );
      state = WebResolveReady(result: result, sourceUrl: prepared);
    } on AppException catch (e) {
      state = WebResolveError(mapExceptionToFailure(e));
    } catch (_) {
      state = const WebResolveError(ServerFailure());
    }
  }

  void reset() => state = const WebResolveIdle();
}

final webResolveProvider =
    StateNotifierProvider<WebResolveNotifier, WebResolveState>(
      WebResolveNotifier.new,
    );

final webLibraryProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  return WebLibraryRepository.instance.getAll();
});
