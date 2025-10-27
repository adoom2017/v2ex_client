import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:v2ex_client/src/providers/topics_provider.dart';
import 'package:v2ex_client/src/providers/member_provider.dart';
import 'package:v2ex_client/src/widgets/topic_list_item.dart';
import 'package:v2ex_client/src/services/log_service.dart';

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
    await ref
        .read(infiniteTopicsProvider(selectedNode).notifier)
        .loadMoreTopics();
    _isLoadingMore = false;
  }

  @override
  Widget build(BuildContext context) {
    final selectedNode = ref.watch(selectedNodeProvider);
    final topicsState = ref.watch(infiniteTopicsProvider(selectedNode));
    final memberAsyncValue = ref.watch(memberProvider);

    // 处理节点变化和初始化
    if (_lastNode != selectedNode) {
      _lastNode = selectedNode;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(infiniteTopicsProvider(selectedNode).notifier)
            .loadInitialTopics();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'V2EX',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
        ),
        leading: memberAsyncValue.when(
          data: (member) => Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundImage: member.avatarNormalUrl.isNotEmpty
                  ? NetworkImage(member.avatarNormalUrl)
                  : null,
              child: member.avatarNormalUrl.isEmpty
                  ? Text(member.username.isNotEmpty
                      ? member.username[0].toUpperCase()
                      : '?')
                  : null,
            ),
          ),
          loading: () => const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircleAvatar(
              child: Icon(Icons.person),
            ),
          ),
          error: (err, stack) => const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircleAvatar(
              child: Icon(Icons.error),
            ),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String node) {
              LogService.userAction(
                  'Node changed', {'from': selectedNode, 'to': node});
              ref.read(selectedNodeProvider.notifier).state = node;
              // 切换节点时重新加载数据
              ref.read(infiniteTopicsProvider(node).notifier).refresh();
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                  value: 'latest',
                  child: Text('最新',
                      style: Theme.of(context).textTheme.bodyMedium)),
              PopupMenuItem(
                  value: 'hot',
                  child: Text('最热',
                      style: Theme.of(context).textTheme.bodyMedium)),
              PopupMenuItem(
                  value: 'share',
                  child: Text('分享发现',
                      style: Theme.of(context).textTheme.bodyMedium)),
            ],
            child: Chip(
              label: Text(
                selectedNode == 'latest'
                    ? '最新'
                    : selectedNode == 'hot'
                        ? '最热'
                        : selectedNode == 'share'
                            ? '分享发现'
                            : selectedNode.toUpperCase(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
              ),
              avatar: const Icon(Icons.keyboard_arrow_down, size: 18),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              LogService.userAction('Settings button pressed');
              context.push('/settings');
            },
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
                await ref
                    .read(infiniteTopicsProvider(selectedNode).notifier)
                    .refresh();
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
                          await ref
                              .read(
                                  infiniteTopicsProvider(selectedNode).notifier)
                              .refresh();
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
                await ref
                    .read(infiniteTopicsProvider(selectedNode).notifier)
                    .refresh();
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
              await ref
                  .read(infiniteTopicsProvider(selectedNode).notifier)
                  .refresh();
            },
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.all(8),
              itemCount:
                  topicsState.topics.length + (topicsState.hasMoreData ? 1 : 0),
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                if (index >= topicsState.topics.length) {
                  // 加载更多指示器
                  return Container(
                    padding: const EdgeInsets.all(16),
                    alignment: Alignment.center,
                    child: topicsState.isLoadingMore
                        ? const CircularProgressIndicator()
                        : const SizedBox.shrink(),
                  );
                }

                final topic = topicsState.topics[index];
                return TopicListItem(
                  topic: topic,
                  onTap: () {
                    context.push('/t/${topic.id}');
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
