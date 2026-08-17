import 'package:dio/dio.dart';
import '../logging/app_logger.dart';
import '../errors/exceptions.dart';
import 'api_client_interface.dart';

class DioApiClient implements IApiClient {
  final Dio _dio;
  String? _organizationId;

  DioApiClient(this._dio) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          AppLogger.debug('API Request: [${options.method}] ${options.uri}');

          if (_organizationId != null) {
            options.headers['x-organization-id'] = _organizationId;
          }

          if (options.data != null) {
            AppLogger.logSensitive(
              'Request Data',
              options.data is Map ? options.data : {'raw': options.data},
            );
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          AppLogger.debug(
            'API Response: [${response.statusCode}] ${response.requestOptions.uri}',
          );
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          // If it's already handled by another interceptor (like AuthInterceptor),
          // we might not want to log it as an "unhandled" error here.
          AppLogger.error(
            'API Error: [${e.response?.statusCode}] ${e.requestOptions.uri}',
            e,
            e.stackTrace,
          );
          return handler.next(e);
        },
      ),
    );
  }

  @override
  void setToken(String? token) {
    // This is now handled by AuthInterceptor reading from TokenStorage
  }

  @override
  void setOrganizationId(String? organizationId) {
    _organizationId = organizationId;
  }

  @override
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool authenticated = true,
  }) async {
    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: Options(
          headers: headers,
          extra: {'authenticated': authenticated},
        ),
      );
      return ApiResponse(
        data: response.data,
        statusCode: response.statusCode,
        statusMessage: response.statusMessage,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool authenticated = true,
  }) async {
    try {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          headers: headers,
          extra: {'authenticated': authenticated},
        ),
      );
      return ApiResponse(
        data: response.data,
        statusCode: response.statusCode,
        statusMessage: response.statusMessage,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool authenticated = true,
  }) async {
    try {
      final response = await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          headers: headers,
          extra: {'authenticated': authenticated},
        ),
      );
      return ApiResponse(
        data: response.data,
        statusCode: response.statusCode,
        statusMessage: response.statusMessage,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool authenticated = true,
  }) async {
    try {
      final response = await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          headers: headers,
          extra: {'authenticated': authenticated},
        ),
      );
      return ApiResponse(
        data: response.data,
        statusCode: response.statusCode,
        statusMessage: response.statusMessage,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<ApiResponse<T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool authenticated = true,
  }) async {
    try {
      final response = await _dio.delete<T>(
        path,
        queryParameters: queryParameters,
        options: Options(
          headers: headers,
          extra: {'authenticated': authenticated},
        ),
      );
      return ApiResponse(
        data: response.data,
        statusCode: response.statusCode,
        statusMessage: response.statusMessage,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  AppException _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError) {
      return NetworkException();
    }

    final statusCode = e.response?.statusCode;
    if (statusCode != null) {
      if (statusCode == 401) return AuthenticationException();
      if (statusCode == 403) return AuthorizationException();
      if (statusCode >= 500) return ServerException();
    }

    return UnknownException(e.message ?? 'Unknown networking error');
  }
}
