import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:v2ex_client/src/providers/group_topics_provider.dart';
import 'package:v2ex_client/src/providers/member_provider.dart';
import 'package:v2ex_client/src/widgets/topic_list_item.dart';
import 'package:v2ex_client/src/services/log_service.dart';
import 'package:v2ex_client/src/models/group_node.dart';

final selectedNodeProvider = StateProvider<String>((ref) => 'latest');

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late ScrollController _scrollController;
  bool _isLoadingMore = false;

  String? _lastNode;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore) {
        _loadMoreTopics();
      }
    }
  }

  Future<void> _loadMoreTopics() async {
    if (_isLoadingMore) return;

    _isLoadingMore = true;
    final selectedNode = ref.read(selectedNodeProvider);
    final groupNode = findGroupNodeByKey(selectedNode);
    if (groupNode != null) {
      await ref.read(groupTopicsProvider(groupNode).notifier).loadMoreTopics();
    }
    _isLoadingMore = false;
  }

  @override
  Widget build(BuildContext context) {
    final selectedNode = ref.watch(selectedNodeProvider);
    final groupNode = findGroupNodeByKey(selectedNode);
    final topicsState = groupNode != null
        ? ref.watch(groupTopicsProvider(groupNode))
        : const GroupTopicsState();
    final memberAsyncValue = ref.watch(memberProvider);

    // 处理节点变化和初始化
    if (_lastNode != selectedNode) {
      _lastNode = selectedNode;
      if (groupNode != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(groupTopicsProvider(groupNode).notifier).loadInitialTopics();
        });
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'V2EX',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 24,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: memberAsyncValue.when(
            data: (member) => CircleAvatar(
              radius: 18,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              backgroundImage: member.avatarNormalUrl.isNotEmpty
                  ? NetworkImage(member.avatarNormalUrl)
                  : null,
              child: member.avatarNormalUrl.isEmpty
                  ? Text(
                      member.username.isNotEmpty
                          ? member.username[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    )
                  : null,
            ),
            loading: () => CircleAvatar(
              radius: 18,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            error: (err, stack) => CircleAvatar(
              radius: 18,
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              child: Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.onErrorContainer,
                size: 18,
              ),
            ),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String node) {
              LogService.userAction(
                  'Node changed', {'from': selectedNode, 'to': node});
              ref.read(selectedNodeProvider.notifier).state = node;
              // 切换节点时的数据加载会在build方法中的节点变化检测处理
              // 这里不需要额外调用refresh，避免重复请求
            },
            itemBuilder: (BuildContext context) => officialNodes
                .map(
                  (groupNode) => PopupMenuItem(
                    value: groupNode.key,
                    child: Text(
                      groupNode.name,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                )
                .toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    findGroupNodeByKey(selectedNode)?.name ??
                        selectedNode.toUpperCase(),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ],
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                Icons.settings_outlined,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 22,
              ),
              onPressed: () {
                LogService.userAction('Settings button pressed');
                context.push('/settings');
              },
            ),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (topicsState.isLoading && topicsState.topics.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (topicsState.error != null && topicsState.topics.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                if (groupNode != null) {
                  await ref
                      .read(groupTopicsProvider(groupNode).notifier)
                      .refresh();
                }
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.8,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '加载失败',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text('${topicsState.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          if (groupNode != null) {
                            await ref
                                .read(groupTopicsProvider(groupNode).notifier)
                                .refresh();
                          }
                        },
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          if (topicsState.topics.isEmpty && !topicsState.isLoading) {
            return RefreshIndicator(
              onRefresh: () async {
                if (groupNode != null) {
                  await ref
                      .read(groupTopicsProvider(groupNode).notifier)
                      .refresh();
                }
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.8,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inbox_outlined, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        '暂无主题',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              if (groupNode != null) {
                await ref
                    .read(groupTopicsProvider(groupNode).notifier)
                    .refresh();
              }
            },
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.zero,
              itemCount:
                  topicsState.topics.length + (topicsState.hasMoreData ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= topicsState.topics.length) {
                  // 加载更多指示器
                  return Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    child: topicsState.isLoadingMore
                        ? CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : const SizedBox.shrink(),
                  );
                }

                final topic = topicsState.topics[index];
                return Column(
                  children: [
                    TopicListItem(
                      topic: topic,
                      onTap: () {
                        context.push('/t/${topic.id}');
                      },
                    ),
                    if (index < topicsState.topics.length - 1)
                      Divider(
                        height: 1,
                        thickness: 0.5,
                        color: Theme.of(context)
                            .colorScheme
                            .outlineVariant
                            .withValues(alpha: 0.3),
                        indent: 16,
                        endIndent: 16,
                      ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
