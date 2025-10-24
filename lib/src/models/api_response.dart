import 'package:json_annotation/json_annotation.dart';

part 'api_response.g.dart';

@JsonSerializable()
class TopicsApiResponse {
  final bool success;
  final String message;
  final List<dynamic> result;
  final Pagination? pagination;

  TopicsApiResponse({
    required this.success,
    required this.message,
    required this.result,
    this.pagination,
  });

  factory TopicsApiResponse.fromJson(Map<String, dynamic> json) => _$TopicsApiResponseFromJson(json);
  Map<String, dynamic> toJson() => _$TopicsApiResponseToJson(this);
}

@JsonSerializable()
class TopicDetailApiResponse {
  final bool success;
  final String message;
  final Map<String, dynamic> result;

  TopicDetailApiResponse({
    required this.success,
    required this.message,
    required this.result,
  });

  factory TopicDetailApiResponse.fromJson(Map<String, dynamic> json) => _$TopicDetailApiResponseFromJson(json);
  Map<String, dynamic> toJson() => _$TopicDetailApiResponseToJson(this);
}

@JsonSerializable()
class RepliesApiResponse {
  final bool success;
  final String message;
  final List<dynamic> result;
  final Pagination? pagination;

  RepliesApiResponse({
    required this.success,
    required this.message,
    required this.result,
    this.pagination,
  });

  factory RepliesApiResponse.fromJson(Map<String, dynamic> json) => _$RepliesApiResponseFromJson(json);
  Map<String, dynamic> toJson() => _$RepliesApiResponseToJson(this);
}

@JsonSerializable()
class Pagination {
  @JsonKey(name: 'per_page')
  final int perPage;
  final int total;
  final int pages;

  Pagination({
    required this.perPage,
    required this.total,
    required this.pages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) => _$PaginationFromJson(json);
  Map<String, dynamic> toJson() => _$PaginationToJson(this);
}