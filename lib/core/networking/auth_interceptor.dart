import 'package:dio/dio.dart';
import '../security/token_storage.dart';
import '../logging/app_logger.dart';

class AuthInterceptor extends Interceptor {
  final TokenStorage _tokenStorage;
  final Dio _dio;
  bool _isRefreshing = false;
  final _failedRequests = <Map<String, dynamic>>[];

  AuthInterceptor(this._tokenStorage, this._dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra['authenticated'] != false) {
      final token = await _tokenStorage.readAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 && err.requestOptions.extra['authenticated'] != false) {
      if (!_isRefreshing) {
        _isRefreshing = true;

        try {
          final refreshToken = await _tokenStorage.readRefreshToken();
          if (refreshToken == null) {
             _isRefreshing = false;
             return handler.next(err);
          }

          AppLogger.info('Token expired. Attempting refresh...');

          // Perform refresh request
          final response = await _dio.post(
            '/auth/refresh',
            data: {'refreshToken': refreshToken},
            options: Options(extra: {'authenticated': false}),
          );

          if (response.statusCode == 200) {
            final newAccessToken = response.data['accessToken'];
            final newRefreshToken = response.data['refreshToken'];

            await _tokenStorage.saveAccessToken(newAccessToken);
            await _tokenStorage.saveRefreshToken(newRefreshToken);

            _isRefreshing = false;

            // Retry failed requests
            for (var request in _failedRequests) {
              final options = request['options'] as RequestOptions;
              options.headers['Authorization'] = 'Bearer $newAccessToken';
              // Note: This is simplified; real implementation would use a proper retry mechanism
            }
            _failedRequests.clear();

            // Retry current request
            final options = err.requestOptions;
            options.headers['Authorization'] = 'Bearer $newAccessToken';

            final retryResponse = await _dio.fetch(options);
            return handler.resolve(retryResponse);
          }
        } catch (e) {
          AppLogger.error('Token refresh failed', e);
          await _tokenStorage.clearTokens();
          // Trigger logout in AuthProvider if needed
        } finally {
          _isRefreshing = false;
        }
      } else {
        // If already refreshing, wait and retry or handle as failure
        // For simplicity, we just pass the error
      }
    }
    return handler.next(err);
  }
}
