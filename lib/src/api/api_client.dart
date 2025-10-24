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

    LogService.info('🔧 ApiClient initialized with base URL: ${_dio.options.baseUrl}');

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          LogService.apiRequest(
            options.method,
            '${options.baseUrl}${options.path}',
            options.queryParameters.isNotEmpty ? options.queryParameters : null,
          );

          final token = await _tokenService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            LogService.debug('🔑 Token added to request headers');
          } else {
            LogService.warning('⚠️ No token available for request');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          LogService.apiResponse(
            response.requestOptions.method,
            '${response.requestOptions.baseUrl}${response.requestOptions.path}',
            response.statusCode ?? 0,
          );
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
    LogService.info('📝 Fetching topics for node: $nodeName (page: $p)');
    try {
      final response = await _dio.get('nodes/$nodeName/topics', queryParameters: {'p': p});
      LogService.info('✅ Successfully fetched topics for node: $nodeName');
      return response;
    } on DioException catch (e, stackTrace) {
      LogService.error('❌ Failed to fetch topics for node: $nodeName', e, stackTrace);

      if (e.type == DioExceptionType.connectionTimeout) {
        final errorMsg = 'Connection timeout. Please check your internet connection.';
        LogService.error('🌐 Connection timeout for node: $nodeName');
        throw Exception(errorMsg);
      } else if (e.type == DioExceptionType.receiveTimeout) {
        final errorMsg = 'Request timeout. Please try again.';
        LogService.error('⏱️ Receive timeout for node: $nodeName');
        throw Exception(errorMsg);
      } else if (e.response?.statusCode == 404) {
        final errorMsg = 'Node "$nodeName" not found.';
        LogService.error('🚫 Node not found: $nodeName');
        throw Exception(errorMsg);
      } else if (e.response?.statusCode == 401) {
        final errorMsg = 'Unauthorized. Please check your Personal Access Token.';
        LogService.error('🔒 Unauthorized access for node: $nodeName');
        throw Exception(errorMsg);
      } else if (e.response?.statusCode == 429) {
        final errorMsg = 'Rate limit exceeded. Please try again later.';
        LogService.error('🚫 Rate limit exceeded for node: $nodeName');
        throw Exception(errorMsg);
      }

      final errorMsg = 'Failed to load topics: ${e.message}';
      LogService.error('💥 Unexpected error for node: $nodeName - ${e.message}');
      throw Exception(errorMsg);
    }
  }

  Future<Response> getMemberProfile() async {
    LogService.info('👤 Fetching member profile');
    try {
      final response = await _dio.get('member');
      LogService.info('✅ Successfully fetched member profile');
      return response;
    } on DioException catch (e, stackTrace) {
      LogService.error('❌ Failed to fetch member profile', e, stackTrace);

      if (e.response?.statusCode == 401) {
        final errorMsg = 'Unauthorized. Please set your Personal Access Token in Settings.';
        LogService.error('🔒 Unauthorized access to member profile');
        throw Exception(errorMsg);
      }

      final errorMsg = 'Failed to load profile: ${e.message}';
      LogService.error('💥 Unexpected error fetching profile - ${e.message}');
      throw Exception(errorMsg);
    }
  }

  Future<Response> getNotifications({int p = 1}) async {
    LogService.info('🔔 Fetching notifications (page: $p)');
    try {
      final response = await _dio.get('notifications', queryParameters: {'p': p});
      LogService.info('✅ Successfully fetched notifications');
      return response;
    } on DioException catch (e, stackTrace) {
      LogService.error('❌ Failed to fetch notifications', e, stackTrace);

      if (e.response?.statusCode == 401) {
        final errorMsg = 'Unauthorized. Please set your Personal Access Token in Settings.';
        LogService.error('🔒 Unauthorized access to notifications');
        throw Exception(errorMsg);
      }

      final errorMsg = 'Failed to load notifications: ${e.message}';
      LogService.error('💥 Unexpected error fetching notifications - ${e.message}');
      throw Exception(errorMsg);
    }
  }

  Future<Response> deleteNotification(String id) async {
    LogService.info('🗑️ Deleting notification: $id');
    try {
      final response = await _dio.delete('notifications/$id');
      LogService.info('✅ Successfully deleted notification: $id');
      return response;
    } on DioException catch (e, stackTrace) {
      LogService.error('❌ Failed to delete notification: $id', e, stackTrace);

      if (e.response?.statusCode == 401) {
        final errorMsg = 'Unauthorized. Please set your Personal Access Token in Settings.';
        LogService.error('🔒 Unauthorized access to delete notification: $id');
        throw Exception(errorMsg);
      }

      final errorMsg = 'Failed to delete notification: ${e.message}';
      LogService.error('💥 Unexpected error deleting notification: $id - ${e.message}');
      throw Exception(errorMsg);
    }
  }

  Future<Response> getTopicDetails(String topicId) async {
    LogService.info('📖 Fetching topic details: $topicId');
    try {
      final response = await _dio.get('topics/$topicId');
      LogService.info('✅ Successfully fetched topic details: $topicId');
      return response;
    } on DioException catch (e, stackTrace) {
      LogService.error('❌ Failed to fetch topic details: $topicId', e, stackTrace);

      if (e.response?.statusCode == 404) {
        final errorMsg = 'Topic not found.';
        LogService.error('🚫 Topic not found: $topicId');
        throw Exception(errorMsg);
      }

      final errorMsg = 'Failed to load topic details: ${e.message}';
      LogService.error('💥 Unexpected error fetching topic: $topicId - ${e.message}');
      throw Exception(errorMsg);
    }
  }

  Future<Response> getTopicReplies(String topicId, {int p = 1}) async {
    LogService.info('💬 Fetching topic replies: $topicId (page: $p)');
    try {
      final response = await _dio.get('topics/$topicId/replies', queryParameters: {'p': p});
      LogService.info('✅ Successfully fetched topic replies: $topicId');
      return response;
    } on DioException catch (e, stackTrace) {
      LogService.error('❌ Failed to fetch topic replies: $topicId', e, stackTrace);

      if (e.response?.statusCode == 404) {
        final errorMsg = 'Topic not found.';
        LogService.error('🚫 Topic not found for replies: $topicId');
        throw Exception(errorMsg);
      }

      final errorMsg = 'Failed to load replies: ${e.message}';
      LogService.error('💥 Unexpected error fetching replies: $topicId - ${e.message}');
      throw Exception(errorMsg);
    }
  }
}

final dioProvider = Provider<Dio>((ref) {
  return Dio();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(dioProvider), ref.watch(tokenServiceProvider));
});
