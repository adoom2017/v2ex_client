// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TopicsApiResponse _$TopicsApiResponseFromJson(Map<String, dynamic> json) =>
    TopicsApiResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      result: json['result'] as List<dynamic>,
      pagination: json['pagination'] == null
          ? null
          : Pagination.fromJson(json['pagination'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TopicsApiResponseToJson(TopicsApiResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'result': instance.result,
      'pagination': instance.pagination,
    };

TopicDetailApiResponse _$TopicDetailApiResponseFromJson(
        Map<String, dynamic> json) =>
    TopicDetailApiResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      result: json['result'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$TopicDetailApiResponseToJson(
        TopicDetailApiResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'result': instance.result,
    };

RepliesApiResponse _$RepliesApiResponseFromJson(Map<String, dynamic> json) =>
    RepliesApiResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      result: json['result'] as List<dynamic>,
      pagination: json['pagination'] == null
          ? null
          : Pagination.fromJson(json['pagination'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RepliesApiResponseToJson(RepliesApiResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'result': instance.result,
      'pagination': instance.pagination,
    };

Pagination _$PaginationFromJson(Map<String, dynamic> json) => Pagination(
      perPage: (json['per_page'] as num).toInt(),
      total: (json['total'] as num).toInt(),
      pages: (json['pages'] as num).toInt(),
    );

Map<String, dynamic> _$PaginationToJson(Pagination instance) =>
    <String, dynamic>{
      'per_page': instance.perPage,
      'total': instance.total,
      'pages': instance.pages,
    };
