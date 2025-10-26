import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:v2ex_client/src/providers/topics_provider.dart';
import 'package:v2ex_client/src/providers/member_provider.dart';
import 'package:v2ex_client/src/widgets/topic_list_item.dart';
import 'package:v2ex_client/src/services/log_service.dart';

final selectedNodeProvider = StateProvider<String>((ref) => 'share');
final currentPageProvider = StateProvider<int>((ref) => 1);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedNode = ref.watch(selectedNodeProvider);
    final currentPage = ref.watch(currentPageProvider);
    final topicsParam = TopicsParam(nodeName: selectedNode, page: currentPage);
    final topicsAsyncValue = ref.watch(paginatedTopicsProvider(topicsParam));
    final memberAsyncValue = ref.watch(memberProvider);

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
              ref.read(currentPageProvider.notifier).state = 1; // 重置到第一页
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                  value: 'share',
                  child: Text('分享发现',
                      style: Theme.of(context).textTheme.bodyMedium)),
              PopupMenuItem(
                  value: 'python',
                  child: Text('Python',
                      style: Theme.of(context).textTheme.bodyMedium)),
              PopupMenuItem(
                  value: 'java',
                  child: Text('Java',
                      style: Theme.of(context).textTheme.bodyMedium)),
              PopupMenuItem(
                  value: 'javascript',
                  child: Text('JavaScript',
                      style: Theme.of(context).textTheme.bodyMedium)),
              PopupMenuItem(
                  value: 'android',
                  child: Text('Android',
                      style: Theme.of(context).textTheme.bodyMedium)),
              PopupMenuItem(
                  value: 'ios',
                  child: Text('iOS',
                      style: Theme.of(context).textTheme.bodyMedium)),
              PopupMenuItem(
                  value: 'flutter',
                  child: Text('Flutter',
                      style: Theme.of(context).textTheme.bodyMedium)),
              PopupMenuItem(
                  value: 'react',
                  child: Text('React',
                      style: Theme.of(context).textTheme.bodyMedium)),
              PopupMenuItem(
                  value: 'vue',
                  child: Text('Vue',
                      style: Theme.of(context).textTheme.bodyMedium)),
            ],
            child: Chip(
              label: Text(
                selectedNode.toUpperCase(),
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
      body: topicsAsyncValue.when(
        data: (topics) {
          if (topics.isEmpty) {
            return const Center(child: Text('No topics found.'));
          }
          return RefreshIndicator(
            onRefresh: () {
              LogService.userAction('Pull to refresh triggered',
                  {'node': selectedNode, 'page': currentPage});
              return ref.refresh(paginatedTopicsProvider(topicsParam).future);
            },
            child: Column(
              children: [
                // 主题列表
                Expanded(
                  child: ListView.builder(
                    itemCount: topics.length,
                    itemBuilder: (context, index) {
                      final topic = topics[index];
                      return TopicListItem(topic: topic);
                    },
                  ),
                ),
                // 分页控件
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 上一页按钮
                      ElevatedButton.icon(
                        onPressed: currentPage > 1
                            ? () {
                                LogService.userAction('Previous page', {
                                  'node': selectedNode,
                                  'from_page': currentPage,
                                  'to_page': currentPage - 1
                                });
                                ref.read(currentPageProvider.notifier).state =
                                    currentPage - 1;
                              }
                            : null,
                        icon: const Icon(Icons.arrow_back, size: 16),
                        label: Text(
                          '上一页',
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    fontSize: 13,
                                  ),
                        ),
                      ),
                      // 页码显示和跳转
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => _PageJumpDialog(
                              currentPage: currentPage,
                              onPageSelected: (page) {
                                LogService.userAction('Jump to page', {
                                  'node': selectedNode,
                                  'from_page': currentPage,
                                  'to_page': page
                                });
                                ref.read(currentPageProvider.notifier).state =
                                    page;
                              },
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '第 $currentPage 页',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_down,
                                size: 16,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // 下一页按钮
                      ElevatedButton.icon(
                        onPressed: topics.length >= 20
                            ? () {
                                // 假设每页20个主题
                                LogService.userAction('Next page', {
                                  'node': selectedNode,
                                  'from_page': currentPage,
                                  'to_page': currentPage + 1
                                });
                                ref.read(currentPageProvider.notifier).state =
                                    currentPage + 1;
                              }
                            : null,
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: Text(
                          '下一页',
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    fontSize: 13,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text('Error: $err'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  LogService.userAction('Retry button pressed',
                      {'node': selectedNode, 'page': currentPage});
                  ref.invalidate(paginatedTopicsProvider(topicsParam));
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageJumpDialog extends StatefulWidget {
  final int currentPage;
  final void Function(int page) onPageSelected;

  const _PageJumpDialog({
    required this.currentPage,
    required this.onPageSelected,
  });

  @override
  State<_PageJumpDialog> createState() => _PageJumpDialogState();
}

class _PageJumpDialogState extends State<_PageJumpDialog> {
  late TextEditingController _controller;
  late int _selectedPage;

  @override
  void initState() {
    super.initState();
    _selectedPage = widget.currentPage;
    _controller = TextEditingController(text: _selectedPage.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('跳转到页面'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('当前页面: ${widget.currentPage}'),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '页码',
              hintText: '输入页码 (1-999)',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              final page = int.tryParse(value);
              if (page != null && page > 0 && page <= 999) {
                _selectedPage = page;
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            final page = int.tryParse(_controller.text);
            if (page != null && page > 0 && page <= 999) {
              widget.onPageSelected(page);
              Navigator.of(context).pop();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('请输入有效的页码 (1-999)')),
              );
            }
          },
          child: const Text('跳转'),
        ),
      ],
    );
  }
}
