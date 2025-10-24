import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:v2ex_client/src/api/api_client.dart';
import 'package:v2ex_client/src/models/topic.dart';

class TopicsParam {
  final String nodeName;
  final int page;

  const TopicsParam({
    required this.nodeName,
    this.page = 1,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TopicsParam &&
          runtimeType == other.runtimeType &&
          nodeName == other.nodeName &&
          page == other.page;

  @override
  int get hashCode => nodeName.hashCode ^ page.hashCode;

  @override
  String toString() => 'TopicsParam(nodeName: $nodeName, page: $page)';
}

// 保持原有的 provider 用于向后兼容
final topicsProvider = FutureProvider.autoDispose.family<List<Topic>, String>((ref, nodeName) async {
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.getTopics(nodeName);

  if (response.data != null && response.data['result'] is List) {
    return (response.data['result'] as List)
        .map((topicJson) => Topic.fromJson(topicJson))
        .toList();
  } else {
    throw Exception('Failed to load topics or invalid data format');
  }
});

// 新的分页 provider - 会并发获取完整的主题信息包括member.avatar
final paginatedTopicsProvider = FutureProvider.autoDispose.family<List<Topic>, TopicsParam>((ref, param) async {
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.getTopics(param.nodeName, p: param.page);

  if (response.data != null && response.data['result'] is List) {
    final basicTopics = (response.data['result'] as List)
        .map((topicJson) => Topic.fromJson(topicJson))
        .toList();

    // 并发获取所有主题的详细信息以补充member.avatar数据
    final List<Future<Topic>> detailFutures = basicTopics.map((basicTopic) async {
      try {
        final detailResponse = await apiClient.getTopicDetails(basicTopic.id.toString());
        if (detailResponse.data != null && detailResponse.data['result'] is Map) {
          return Topic.fromJson(detailResponse.data['result']);
        } else {
          // 如果获取详情失败，使用基本信息
          return basicTopic;
        }
      } catch (e) {
        // 如果获取详情失败，使用基本信息
        return basicTopic;
      }
    }).toList();

    // 等待所有并发请求完成
    final enrichedTopics = await Future.wait(detailFutures);
    return enrichedTopics;
  } else {
    throw Exception('Failed to load topics or invalid data format');
  }
});
