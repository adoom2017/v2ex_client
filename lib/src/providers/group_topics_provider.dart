import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:v2ex_client/src/models/topic.dart';
import 'package:v2ex_client/src/models/group_node.dart';
import 'package:v2ex_client/src/services/group_topic_service.dart';
import 'package:v2ex_client/src/services/log_service.dart';

class GroupTopicsState {
  final List<Topic> topics;
  final int currentPage;
  final bool hasMoreData;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int cachedPages;
  final int totalCount;

  const GroupTopicsState({
    this.topics = const [],
    this.currentPage = 0,
    this.hasMoreData = true,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.cachedPages = 0,
    this.totalCount = 0,
  });

  bool get hasError => error != null;

  GroupTopicsState copyWith({
    List<Topic>? topics,
    int? currentPage,
    bool? hasMoreData,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? cachedPages,
    int? totalCount,
  }) {
    return GroupTopicsState(
      topics: topics ?? this.topics,
      currentPage: currentPage ?? this.currentPage,
      hasMoreData: hasMoreData ?? this.hasMoreData,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      cachedPages: cachedPages ?? this.cachedPages,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

class GroupTopicsNotifier extends StateNotifier<GroupTopicsState> {
  final Ref ref;
  final GroupNode groupNode;
  late final GroupTopicService _service;

  GroupTopicsNotifier(this.ref, this.groupNode)
      : super(const GroupTopicsState()) {
    _service = ref.read(groupTopicServiceProvider);
  }

  Future<void> loadInitialTopics() async {
    if (!mounted) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _service.getTopicsByGroupNode(groupNode, 1);

      if (!mounted) return;

      // 按时间排序，最新的在前
      final sortedTopics = _sortTopicsByTime(result.topics);

      state = state.copyWith(
        topics: sortedTopics,
        currentPage: 1,
        isLoading: false,
        hasMoreData: sortedTopics.length >= 20,
        cachedPages: result.cachedPages,
        totalCount: result.totalCount,
      );

      LogService.info(
          '分组主题加载完成: ${groupNode.name}, 数量: ${sortedTopics.length}');
    } catch (e) {
      if (!mounted) return;

      LogService.error('加载分组主题失败: ${groupNode.name}', e, StackTrace.current);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMoreTopics() async {
    if (!mounted || state.isLoadingMore || !state.hasMoreData) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final nextPage = state.currentPage + 1;
      final result = await _service.getTopicsByGroupNode(groupNode, nextPage);

      if (!mounted) return;

      // 检查重复并合并
      final existingIds = state.topics.map((t) => t.id).toSet();
      final newTopics = result.topics
          .where((topic) => !existingIds.contains(topic.id))
          .toList();

      final allTopics = [...state.topics, ...newTopics];

      // 按时间排序，最新的在前
      final sortedTopics = _sortTopicsByTime(allTopics);

      state = state.copyWith(
        topics: sortedTopics,
        currentPage: nextPage,
        isLoadingMore: false,
        hasMoreData: result.topics.length >= 20,
        cachedPages: result.cachedPages,
        totalCount: result.totalCount,
      );

      LogService.info('加载更多分组主题: ${groupNode.name}, 新增: ${newTopics.length}');
    } catch (e) {
      if (!mounted) return;

      LogService.error('加载更多分组主题失败: ${groupNode.name}', e, StackTrace.current);
      state = state.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    // 清空缓存并重新加载
    _service.clearCache(groupNode.key);
    state = const GroupTopicsState();
    await loadInitialTopics();
  }

  /// 按时间排序主题，最新的在前
  List<Topic> _sortTopicsByTime(List<Topic> topics) {
    final sortedTopics = List<Topic>.from(topics);
    sortedTopics.sort((a, b) {
      // 优先使用 lastModified，如果不存在则使用 created
      final aTime = a.lastModified ?? a.created;
      final bTime = b.lastModified ?? b.created;

      // 降序排序，最新的在前
      return bTime.compareTo(aTime);
    });
    return sortedTopics;
  }
}

// Provider for group topics
final groupTopicsProvider = StateNotifierProvider.autoDispose
    .family<GroupTopicsNotifier, GroupTopicsState, GroupNode>(
  (ref, groupNode) => GroupTopicsNotifier(ref, groupNode),
);

// Helper provider to get group node by key
final groupNodeProvider = Provider.family<GroupNode?, String>((ref, key) {
  return findGroupNodeByKey(key);
});
