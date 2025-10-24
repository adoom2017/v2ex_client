import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:v2ex_client/src/api/api_client.dart';
import 'package:v2ex_client/src/models/topic.dart';
import 'package:v2ex_client/src/models/reply.dart';
import 'package:v2ex_client/src/models/api_response.dart';

class TopicRepliesParam {
  final String topicId;
  final int page;

  const TopicRepliesParam({
    required this.topicId,
    this.page = 1,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TopicRepliesParam &&
          runtimeType == other.runtimeType &&
          topicId == other.topicId &&
          page == other.page;

  @override
  int get hashCode => topicId.hashCode ^ page.hashCode;

  @override
  String toString() => 'TopicRepliesParam(topicId: $topicId, page: $page)';
}

final topicDetailProvider = FutureProvider.autoDispose.family<Topic, String>((ref, topicId) async {
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.getTopicDetails(topicId);

  if (response.data != null && response.data['result'] is Map<String, dynamic>) {
    return Topic.fromJson(response.data['result']);
  } else {
    throw Exception('Failed to load topic details or invalid data format');
  }
});

final topicRepliesProvider = FutureProvider.autoDispose.family<List<Reply>, TopicRepliesParam>((ref, param) async {
  final apiClient = ref.read(apiClientProvider);

  final response = await apiClient.getTopicReplies(param.topicId, p: param.page);

  if (response.data != null) {
    final repliesResponse = RepliesApiResponse.fromJson(response.data);
    if (repliesResponse.success) {
      // 即使result为空也是正常情况，返回空列表而不是抛出异常
      return repliesResponse.result
          .map((replyJson) => Reply.fromJson(replyJson))
          .toList();
    }
  }

  throw Exception('Failed to load replies or invalid data format');
});