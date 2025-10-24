import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:v2ex_client/src/services/token_service.dart';
import 'package:v2ex_client/src/services/log_service.dart';

class ApiClient {
  final Dio _dio;
  final TokenService _tokenService;

  ApiClient(this._dio, this._tokenService) {
    _dio.options.baseUrl = 'https://www.v2ex.com/api/v2/';
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            LogService.warning('⚠️ No token available for request');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (error, handler) {
          LogService.apiError(
            error.requestOptions.method,
            '${error.requestOptions.baseUrl}${error.requestOptions.path}',
            error,
            error.stackTrace,
          );

          if (error.response?.statusCode == 401) {
            LogService.tokenOperation('Token invalidated due to 401 response');
            _tokenService.deleteToken();
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<Response> getTopics(String nodeName, {int p = 1}) async {
    try {
      final response = await _dio.get('nodes/$nodeName/topics', queryParameters: {'p': p});
      return response;
    } on DioException catch (e, stackTrace) {
      LogService.error('❌ Failed to fetch topics for node: $nodeName', e, stackTrace);

      if (e.type == DioExceptionType.connectionTimeout) {
        final errorMsg = 'Connection timeout. Please check your internet connection.';
        throw Exception(errorMsg);
      } else if (e.type == DioExceptionType.receiveTimeout) {
        final errorMsg = 'Request timeout. Please try again.';
        throw Exception(errorMsg);
      } else if (e.response?.statusCode == 404) {
        final errorMsg = 'Node "$nodeName" not found.';
        throw Exception(errorMsg);
      } else if (e.response?.statusCode == 401) {
        final errorMsg = 'Unauthorized. Please check your Personal Access Token.';
        throw Exception(errorMsg);
      } else if (e.response?.statusCode == 429) {
        final errorMsg = 'Rate limit exceeded. Please try again later.';
        throw Exception(errorMsg);
      }

      final errorMsg = 'Failed to load topics: ${e.message}';
      LogService.error('❌ Failed to fetch topics for node: $nodeName', e, stackTrace);
      throw Exception(errorMsg);
    }
  }

  Future<Response> getMemberProfile() async {
    try {
      final response = await _dio.get('member');
      return response;
    } on DioException catch (e, stackTrace) {
      if (e.response?.statusCode == 401) {
        final errorMsg = 'Unauthorized. Please set your Personal Access Token in Settings.';
        throw Exception(errorMsg);
      }

      final errorMsg = 'Failed to load member profile: ${e.message}';
      LogService.error('❌ Failed to fetch member profile', e, stackTrace);
      throw Exception(errorMsg);
    }
  }

  Future<Response> getNotifications({int p = 1}) async {
    try {
      final response = await _dio.get('notifications', queryParameters: {'p': p});
      return response;
    } on DioException catch (e, stackTrace) {
      if (e.response?.statusCode == 401) {
        final errorMsg = 'Unauthorized. Please set your Personal Access Token in Settings.';
        throw Exception(errorMsg);
      }

      final errorMsg = 'Failed to load notifications: ${e.message}';
      LogService.error('❌ Failed to fetch notifications', e, stackTrace);
      throw Exception(errorMsg);
    }
  }

  Future<Response> deleteNotification(String id) async {
    try {
      final response = await _dio.delete('notifications/$id');
      return response;
    } on DioException catch (e, stackTrace) {
      if (e.response?.statusCode == 401) {
        final errorMsg = 'Unauthorized. Please set your Personal Access Token in Settings.';
        throw Exception(errorMsg);
      }

      if (e.response?.statusCode == 404) {
        final errorMsg = 'Notification not found or already deleted.';
        throw Exception(errorMsg);
      }

      final errorMsg = 'Failed to delete notification: ${e.message}';
      LogService.error('❌ Failed to delete notification: $id', e, stackTrace);
      throw Exception(errorMsg);
    }
  }

  Future<Response> getTopicDetails(String topicId) async {
    try {
      final response = await _dio.get('topics/$topicId');
      return response;
    } on DioException catch (e, stackTrace) {
      if (e.response?.statusCode == 404) {
        final errorMsg = 'Topic not found.';
        throw Exception(errorMsg);
      }

      final errorMsg = 'Failed to load topic details: ${e.message}';
      LogService.error('❌ Failed to fetch topic details: $topicId', e, stackTrace);
      throw Exception(errorMsg);
    }
  }

  Future<Response> getTopicReplies(String topicId, {int page = 1, int size = 20}) async {
    try {
      final response = await _dio.get('topics/$topicId/replies', queryParameters: {
        'page': page,
        'size': size,
      });
      return response;
    } on DioException catch (e, stackTrace) {
      LogService.error('❌ Failed to fetch topic replies: $topicId, page: $page', e, stackTrace);
      throw Exception('Failed to load topic replies: ${e.message}');
    }
  }
}

final dioProvider = Provider<Dio>((ref) {
  return Dio();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(Dio(), ref.watch(tokenServiceProvider));
});
