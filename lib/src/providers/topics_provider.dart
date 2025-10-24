import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:v2ex_client/src/api/api_client.dart';
import 'package:v2ex_client/src/models/topic.dart';

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
