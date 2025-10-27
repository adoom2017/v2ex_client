import 'package:dio/dio.dart';
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
final topicsProvider = FutureProvider.autoDispose
    .family<List<Topic>, String>((ref, nodeName) async {
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

// 新的分页 provider - 快速返回基本topic列表，不等待头像加载
final paginatedTopicsProvider = FutureProvider.autoDispose
    .family<List<Topic>, TopicsParam>((ref, param) async {
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.getTopics(param.nodeName, p: param.page);

  if (response.data != null && response.data['result'] is List) {
    final basicTopics = (response.data['result'] as List)
        .map((topicJson) => Topic.fromJson(topicJson))
        .toList();

    // 立即返回基本topic列表，头像将异步加载
    return basicTopics;
  } else {
    throw Exception('Failed to load topics or invalid data format');
  }
});

// 无限滚动Topics的状态
class InfiniteTopicsState {
  final List<Topic> topics;
  final int currentPage;
  final bool hasMoreData;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  const InfiniteTopicsState({
    this.topics = const [],
    this.currentPage = 1,
    this.hasMoreData = true,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  bool get hasError => error != null;

  InfiniteTopicsState copyWith({
    List<Topic>? topics,
    int? currentPage,
    bool? hasMoreData,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
  }) {
    return InfiniteTopicsState(
      topics: topics ?? this.topics,
      currentPage: currentPage ?? this.currentPage,
      hasMoreData: hasMoreData ?? this.hasMoreData,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
    );
  }
}

// 无限滚动Topics的StateNotifier
class InfiniteTopicsNotifier extends StateNotifier<InfiniteTopicsState> {
  final Ref ref;
  final String nodeName;

  InfiniteTopicsNotifier(this.ref, this.nodeName)
      : super(const InfiniteTopicsState()) {
    loadInitialTopics();
  }

  Future<void> loadInitialTopics() async {
    if (!mounted) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiClient = ref.read(apiClientProvider);
      late final Response response;

      if (nodeName == 'latest') {
        // 使用最新主题 API
        response = await apiClient.getLatestTopics();
      } else {
        // 使用普通的节点主题 API
        response = await apiClient.getTopics(nodeName, p: 1);
      }

      List<dynamic> topicList;
      if (nodeName == 'latest') {
        // 最新主题 API 直接返回数组
        topicList = response.data as List;
      } else {
        // 节点主题 API 返回 {result: [...]}
        topicList = response.data['result'] as List;
      }

      final topics =
          topicList.map((topicJson) => Topic.fromJson(topicJson)).toList();

      if (!mounted) return;

      state = state.copyWith(
        topics: topics,
        currentPage: 1,
        isLoading: false,
        hasMoreData: nodeName != 'latest' && topics.length >= 20, // 最新主题不支持分页
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMoreTopics() async {
    if (!mounted || state.isLoadingMore || !state.hasMoreData) return;

    // 最新主题不支持分页，直接返回
    if (nodeName == 'latest') return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.currentPage + 1;
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.getTopics(nodeName, p: nextPage);

      if (response.data != null && response.data['result'] is List) {
        final newTopics = (response.data['result'] as List)
            .map((topicJson) => Topic.fromJson(topicJson))
            .toList();

        if (!mounted) return;

        // 检查重复的主题ID以避免重复添加
        final existingIds = state.topics.map((t) => t.id).toSet();
        final uniqueNewTopics = newTopics
            .where((topic) => !existingIds.contains(topic.id))
            .toList();

        final allTopics = [...state.topics, ...uniqueNewTopics];

        state = state.copyWith(
          topics: allTopics,
          currentPage: nextPage,
          isLoadingMore: false,
          hasMoreData: newTopics.length >= 20, // 如果少于20个说明没有更多了
        );
      }
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    state = const InfiniteTopicsState();
    await loadInitialTopics();
  }
}

// 无限滚动Topics的provider
final infiniteTopicsProvider = StateNotifierProvider.autoDispose
    .family<InfiniteTopicsNotifier, InfiniteTopicsState, String>(
  (ref, nodeName) => InfiniteTopicsNotifier(ref, nodeName),
);
