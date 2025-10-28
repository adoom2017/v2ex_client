import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:v2ex_client/src/providers/group_topics_provider.dart';
import 'package:v2ex_client/src/providers/member_provider.dart';
import 'package:v2ex_client/src/widgets/topic_list_item.dart';
import 'package:v2ex_client/src/services/log_service.dart';
import 'package:v2ex_client/src/models/group_node.dart';
import 'package:v2ex_client/src/screens/notifications_screen.dart';
import 'package:v2ex_client/src/widgets/node_selector_drawer.dart';

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

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemBackground,
        border: const Border(
          bottom: BorderSide(
            color: CupertinoColors.separator,
            width: 0.0,
          ),
        ),
        middle: const Text(
          'V2EX',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: CupertinoColors.label,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: memberAsyncValue.when(
            data: (member) => Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CupertinoColors.systemBlue.withValues(alpha: 0.1),
                image: member.avatarNormalUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(member.avatarNormalUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: member.avatarNormalUrl.isEmpty
                  ? Center(
                      child: Text(
                        member.username.isNotEmpty
                            ? member.username[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: CupertinoColors.systemBlue,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : null,
            ),
            loading: () => Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: CupertinoColors.systemGrey5,
              ),
              child: const Center(
                child: CupertinoActivityIndicator(radius: 8),
              ),
            ),
            error: (err, stack) => Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: CupertinoColors.systemRed,
              ),
              child: const Icon(
                CupertinoIcons.exclamationmark,
                color: CupertinoColors.white,
                size: 16,
              ),
            ),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                LogService.userAction('Node selector tapped');
                showNodeSelectorDrawer(context);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: CupertinoColors.systemBlue.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      findGroupNodeByKey(selectedNode)?.name ??
                          selectedNode.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: CupertinoColors.systemBlue,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      CupertinoIcons.chevron_down,
                      size: 14,
                      color: CupertinoColors.systemBlue,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                LogService.userAction('Notifications button pressed');
                showCupertinoModalPopup(
                  context: context,
                  builder: (BuildContext context) =>
                      const NotificationsScreen(),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.bell,
                  color: CupertinoColors.systemGrey,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                LogService.userAction('Settings button pressed');
                context.push('/settings');
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.settings,
                  color: CupertinoColors.systemGrey,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
      child: Builder(
        builder: (context) {
          // 其他节点使用原有的逻辑
          if (topicsState.isLoading && topicsState.topics.isEmpty) {
            return const Center(child: CupertinoActivityIndicator());
          }

          if (topicsState.error != null && topicsState.topics.isEmpty) {
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                CupertinoSliverRefreshControl(
                  onRefresh: () async {
                    if (groupNode != null) {
                      await ref
                          .read(groupTopicsProvider(groupNode).notifier)
                          .refresh();
                    }
                  },
                ),
                SliverFillRemaining(
                  child: Container(
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          CupertinoIcons.exclamationmark_circle,
                          size: 64,
                          color: CupertinoColors.systemRed,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '加载失败',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.label,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${topicsState.error}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                        const SizedBox(height: 16),
                        CupertinoButton.filled(
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
              ],
            );
          }

          if (topicsState.topics.isEmpty && !topicsState.isLoading) {
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                CupertinoSliverRefreshControl(
                  onRefresh: () async {
                    if (groupNode != null) {
                      await ref
                          .read(groupTopicsProvider(groupNode).notifier)
                          .refresh();
                    }
                  },
                ),
                SliverFillRemaining(
                  child: Container(
                    alignment: Alignment.center,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.tray,
                          size: 64,
                          color: CupertinoColors.systemGrey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          '暂无主题',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.label,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '下拉刷新试试',
                          style: TextStyle(
                            fontSize: 14,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: () async {
                  if (groupNode != null) {
                    await ref
                        .read(groupTopicsProvider(groupNode).notifier)
                        .refresh();
                  }
                },
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index < topicsState.topics.length) {
                      final topic = topicsState.topics[index];
                      return Column(
                        children: [
                          TopicListItem(topic: topic),
                          if (index < topicsState.topics.length - 1)
                            Container(
                              height: 0.5,
                              color: CupertinoColors.separator,
                              margin: const EdgeInsets.only(left: 16),
                            ),
                        ],
                      );
                    } else if (topicsState.hasMoreData) {
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        alignment: Alignment.center,
                        child: const CupertinoActivityIndicator(),
                      );
                    } else {
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        alignment: Alignment.center,
                        child: const Text(
                          '没有更多了',
                          style: TextStyle(
                            color: CupertinoColors.secondaryLabel,
                            fontSize: 14,
                          ),
                        ),
                      );
                    }
                  },
                  childCount: topicsState.topics.length + 1,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
