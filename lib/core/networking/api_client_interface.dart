/// Interface for the core API client.
abstract class IApiClient {
  /// Sets the authorization token for subsequent requests.
  void setToken(String? token);

  /// Sets the organization context for subsequent requests.
  void setOrganizationId(String? organizationId);

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool authenticated = true,
  });

  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool authenticated = true,
  });

  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool authenticated = true,
  });

  Future<ApiResponse<T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool authenticated = true,
  });
}

class ApiResponse<T> {
  final T? data;
  final int? statusCode;
  final String? statusMessage;

  ApiResponse({this.data, this.statusCode, this.statusMessage});

  bool get isSuccess =>
      statusCode != null && statusCode! >= 200 && statusCode! < 300;
}
