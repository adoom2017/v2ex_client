import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:v2ex_client/src/api/api_client.dart';
import 'package:v2ex_client/src/models/topic.dart';
import 'package:v2ex_client/src/models/group_node.dart';
import 'package:v2ex_client/src/services/log_service.dart';
import 'package:v2ex_client/src/services/html_parser_service.dart';

class GroupTopicCache {
  final List<Topic> topics;
  final int totalCount;
  final int cachedPages;
  final DateTime lastUpdate;

  const GroupTopicCache({
    required this.topics,
    required this.totalCount,
    required this.cachedPages,
    required this.lastUpdate,
  });

  GroupTopicCache copyWith({
    List<Topic>? topics,
    int? totalCount,
    int? cachedPages,
    DateTime? lastUpdate,
  }) {
    return GroupTopicCache(
      topics: topics ?? this.topics,
      totalCount: totalCount ?? this.totalCount,
      cachedPages: cachedPages ?? this.cachedPages,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }
}

class GroupTopicResult {
  final List<Topic> topics;
  final int cachedPages;
  final int totalCount;

  const GroupTopicResult({
    required this.topics,
    required this.cachedPages,
    required this.totalCount,
  });
}

class GroupTopicService {
  final ApiClient _apiClient;
  static const int _perPage = 20;

  // 缓存数据
  final Map<String, GroupTopicCache> _cache = {};

  // 请求状态管理 - 使用Future来跟踪正在进行的请求
  final Map<String, Future<GroupTopicResult>> _pendingRequests = {};
  final Set<String> _requestingNodes = {};

  GroupTopicService(this._apiClient);

  Future<GroupTopicResult> getTopicsByGroupNode(
    GroupNode groupNode,
    int page,
  ) async {
    LogService.info('请求分组主题: ${groupNode.name}, 页码: $page');

    // 检查是否有正在进行的相同请求
    final requestKey = '${groupNode.key}_$page';
    if (_pendingRequests.containsKey(requestKey)) {
      LogService.info('等待已有请求: ${groupNode.name}, 页码: $page');
      return await _pendingRequests[requestKey]!;
    }

    // 检查缓存 - 如果缓存存在且包含所需页面的数据，直接返回
    final cache = _cache[groupNode.key];
    final endIndex = (page - 1) * _perPage + _perPage;

    if (cache != null && cache.topics.length >= endIndex) {
      LogService.info('使用缓存数据: ${groupNode.name}, 页码: $page');
      final startIndex = (page - 1) * _perPage;
      final pageTopics = cache.topics
          .sublist(startIndex, endIndex.clamp(0, cache.topics.length));

      return GroupTopicResult(
        topics: pageTopics,
        cachedPages: cache.cachedPages,
        totalCount: cache.totalCount,
      );
    }

    // 创建新的请求Future并存储
    final requestFuture = _performRequest(groupNode, page);
    _pendingRequests[requestKey] = requestFuture;

    try {
      final result = await requestFuture;
      return result;
    } finally {
      // 请求完成后清理
      _pendingRequests.remove(requestKey);
    }
  }

  Future<GroupTopicResult> _performRequest(
      GroupNode groupNode, int page) async {
    try {
      // 需要从API获取数据
      final newTopics = await _fetchGroupTopics(groupNode);

      // 更新缓存
      final cache = _cache[groupNode.key];
      final totalCachedTopics = <Topic>[...(cache?.topics ?? []), ...newTopics];

      // 按时间排序
      totalCachedTopics.sort((a, b) =>
          (b.lastTouched ?? b.created).compareTo(a.lastTouched ?? a.created));

      // 去重
      final uniqueTopics = _removeDuplicates(totalCachedTopics);

      final newCache = GroupTopicCache(
        topics: uniqueTopics,
        totalCount: uniqueTopics.length,
        cachedPages: (uniqueTopics.length / _perPage).ceil(),
        lastUpdate: DateTime.now(),
      );

      _cache[groupNode.key] = newCache;

      // 返回请求页面的数据
      final endIndex = (page - 1) * _perPage + _perPage;
      final startIndex = (page - 1) * _perPage;
      final pageTopics = uniqueTopics.sublist(
          startIndex, endIndex.clamp(0, uniqueTopics.length));

      return GroupTopicResult(
        topics: pageTopics,
        cachedPages: newCache.cachedPages,
        totalCount: newCache.totalCount,
      );
    } catch (e) {
      LogService.error('获取分组主题数据失败: ${groupNode.name}', e, StackTrace.current);
      rethrow;
    }
  }

  Future<List<Topic>> _fetchGroupTopics(GroupNode groupNode) async {
    LogService.info(
        '并发获取分组节点数据: ${groupNode.name}, 节点数: ${groupNode.nodes.length}');
    LogService.info('分组key: ${groupNode.key}, 节点列表: ${groupNode.nodes}');

    final List<Future<List<Topic>>> futures = [];

    for (final nodeKey in groupNode.nodes) {
      LogService.info('准备获取节点: $nodeKey');
      if (_requestingNodes.contains(nodeKey)) {
        LogService.info('节点 $nodeKey 正在请求中，跳过');
        continue; // 跳过正在请求的节点
      }

      _requestingNodes.add(nodeKey);

      futures.add(_fetchNodeTopics(nodeKey).whenComplete(() {
        _requestingNodes.remove(nodeKey);
      }));
    }

    try {
      final results = await Future.wait(futures, eagerError: false);
      final allTopics = <Topic>[];

      for (final topics in results) {
        allTopics.addAll(topics);
        LogService.info('单个节点返回数据量: ${topics.length}');
      }

      LogService.info('分组总数据量: ${allTopics.length}');
      return allTopics;
    } catch (e) {
      LogService.error('获取分组主题失败', e, StackTrace.current);
      rethrow;
    }
  }

  Future<List<Topic>> _fetchNodeTopics(String nodeKey) async {
    LogService.info('🔍 _fetchNodeTopics called with nodeKey: $nodeKey');
    try {
      List<Topic> topics = [];

      // 处理特殊节点
      if (nodeKey == NodeTypes.latestNode) {
        LogService.info('⚡ Fetching latest topics');
        final response = await _apiClient.getLatestTopics();
        if (response.data is List) {
          topics = (response.data as List)
              .map((json) => Topic.fromJson(json))
              .toList();
        }
      } else if (nodeKey == NodeTypes.hotNode) {
        LogService.info('🔥 Fetching hot topics');
        final response = await _apiClient.getHotTopics();
        if (response.data is List) {
          topics = (response.data as List)
              .map((json) => Topic.fromJson(json))
              .toList();
        }
      } else {
        // 普通节点 - 使用 HTML 解析方式
        LogService.info('📝 Fetching topics for node via HTML: $nodeKey');
        final htmlContent = await _apiClient.getNodeTopicsHtml(nodeKey, p: 1);
        topics =
            HtmlParserService.parseTopicsNode(htmlContent, nodeKey: nodeKey);
      }

      // 注意：HTML解析方式已经包含了node信息，无需再次添加
      LogService.info(
          '✅ Successfully fetched ${topics.length} topics for node: $nodeKey');
      return topics;
    } catch (e) {
      LogService.error('获取节点主题失败: $nodeKey', e, StackTrace.current);
      return []; // 单个节点失败不影响整体
    }
  }

  List<Topic> _removeDuplicates(List<Topic> topics) {
    final seen = <int>{};
    return topics.where((topic) => seen.add(topic.id)).toList();
  }

  void clearCache([String? groupKey]) {
    if (groupKey != null) {
      _cache.remove(groupKey);
    } else {
      _cache.clear();
    }
    LogService.info('清空缓存: ${groupKey ?? 'all'}');
  }

  bool hasCachedData(String groupKey, int page) {
    final cache = _cache[groupKey];
    if (cache == null) return false;

    final requiredIndex = page * _perPage;
    return cache.topics.length >= requiredIndex;
  }
}

// Riverpod provider
final groupTopicServiceProvider = Provider<GroupTopicService>((ref) {
  return GroupTopicService(ref.watch(apiClientProvider));
});
