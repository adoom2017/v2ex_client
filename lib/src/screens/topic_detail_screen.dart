import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:v2ex_client/src/providers/topic_provider.dart';
import 'package:v2ex_client/src/services/log_service.dart';
import 'package:v2ex_client/src/models/reply.dart';
import 'package:timeago/timeago.dart' as timeago;

// State provider for managing infinite scroll replies
final infiniteRepliesProvider = StateNotifierProvider.autoDispose
    .family<InfiniteRepliesNotifier, InfiniteRepliesState, String>(
  (ref, topicId) => InfiniteRepliesNotifier(ref, topicId),
);

// State class for infinite replies
class InfiniteRepliesState {
  final List replies;
  final int currentPage;
  final bool hasMoreData;
  final bool isLoading;
  final String? error;
  final int totalRepliesCount; // 总回复数
  final bool isInitialized; // 是否已经初始化过

  const InfiniteRepliesState({
    this.replies = const [],
    this.currentPage = 1,
    this.hasMoreData = true,
    this.isLoading = false,
    this.error,
    this.totalRepliesCount = 0,
    this.isInitialized = false,
  });

  bool get hasError => error != null;
  String get errorMessage => error ?? '';

  InfiniteRepliesState copyWith({
    List? replies,
    int? currentPage,
    bool? hasMoreData,
    bool? isLoading,
    String? error,
    int? totalRepliesCount,
    bool? isInitialized,
  }) {
    return InfiniteRepliesState(
      replies: replies ?? this.replies,
      currentPage: currentPage ?? this.currentPage,
      hasMoreData: hasMoreData ?? this.hasMoreData,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      totalRepliesCount: totalRepliesCount ?? this.totalRepliesCount,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

// StateNotifier for managing infinite replies
class InfiniteRepliesNotifier extends StateNotifier<InfiniteRepliesState> {
  final Ref ref;
  final String topicId;

  InfiniteRepliesNotifier(this.ref, this.topicId)
      : super(const InfiniteRepliesState()) {
    loadInitialReplies();
  }

  Future<void> loadInitialReplies([int? totalRepliesCount]) async {
    if (!mounted) return; // 检查是否已经销毁

    state = state.copyWith(isLoading: true, error: null);
    try {
      final repliesParam = TopicRepliesParam(topicId: topicId, page: 1);
      final repliesResponse = await ref
          .read(topicRepliesWithPaginationProvider(repliesParam).future);

      final replies = repliesResponse.result
          .map((replyJson) => Reply.fromJson(replyJson))
          .toList();

      // 使用pagination信息进行准确判断
      bool hasMore = false;
      int totalCount = 0;

      if (repliesResponse.pagination != null) {
        final pagination = repliesResponse.pagination!;
        totalCount = pagination.total;
        // 当前页 < 总页数 表示还有更多页
        hasMore = 1 < pagination.pages;
      } else {
        // 如果没有分页信息，使用传入的总回复数或旧逻辑
        totalCount = totalRepliesCount ?? 0;
        if (replies.isEmpty) {
          hasMore = false;
        } else if (totalRepliesCount != null && totalRepliesCount > 0) {
          hasMore = replies.length < totalRepliesCount;
        } else {
          hasMore = replies.length >= 20;
        }
      }

      if (!mounted) return; // 再次检查是否已经销毁

      state = state.copyWith(
        replies: replies,
        currentPage: 1,
        isLoading: false,
        hasMoreData: hasMore,
        totalRepliesCount: totalCount,
        isInitialized: true, // 标记为已初始化
      );
    } catch (e) {
      if (!mounted) return; // 检查是否已经销毁

      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        isInitialized: true, // 即使出错也标记为已初始化，避免重复尝试
      );
    }
  }

  Future<void> loadMoreReplies() async {
    if (!mounted || state.isLoading || !state.hasMoreData) return;

    state = state.copyWith(isLoading: true);
    try {
      final nextPage = state.currentPage + 1;
      final repliesParam = TopicRepliesParam(topicId: topicId, page: nextPage);
      final repliesResponse = await ref
          .read(topicRepliesWithPaginationProvider(repliesParam).future);

      final newReplies = repliesResponse.result
          .map((replyJson) => Reply.fromJson(replyJson))
          .toList();

      final allReplies = [...state.replies, ...newReplies];

      // 使用pagination信息进行准确判断
      bool hasMore = false;

      if (repliesResponse.pagination != null) {
        final pagination = repliesResponse.pagination!;
        // 当前页 < 总页数 表示还有更多页
        hasMore = nextPage < pagination.pages;
      } else {
        // 如果没有分页信息，使用旧逻辑
        if (newReplies.isEmpty) {
          hasMore = false;
        } else if (state.totalRepliesCount > 0) {
          hasMore = allReplies.length < state.totalRepliesCount;
        } else {
          hasMore = newReplies.length >= 20;
        }
      }

      state = state.copyWith(
        replies: allReplies,
        currentPage: nextPage,
        isLoading: false,
        hasMoreData: hasMore,
      );
      LogService.userAction('Load more replies', {
        'topicId': topicId,
        'page': nextPage,
        'newRepliesCount': newReplies.length,
        'totalLoadedReplies': allReplies.length,
        'totalExpectedReplies': state.totalRepliesCount,
        'hasMoreData': hasMore,
        'pagination': repliesResponse.pagination?.toJson(),
      });
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh([int? totalRepliesCount]) async {
    state = const InfiniteRepliesState();
    await loadInitialReplies(totalRepliesCount);
  }
}

class TopicDetailScreen extends ConsumerStatefulWidget {
  const TopicDetailScreen({required this.topicId, super.key});
  final String topicId;

  @override
  ConsumerState<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends ConsumerState<TopicDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false; // 防止重复触发加载

  // 通用链接处理函数
  void _handleLinkTap(String? url, BuildContext context) {
    if (url == null || url.isEmpty) return;

    LogService.userAction('Link clicked', {
      'url': url,
      'topicId': widget.topicId,
    });

    if (url.startsWith('/member/')) {
      // V2EX 用户链接
      final username = url.substring('/member/'.length);
      final repliesState = ref.read(infiniteRepliesProvider(widget.topicId));
      _showUserRepliesDialog(context, ref, widget.topicId, username, repliesState.replies);
    } else if (url.startsWith('/t/')) {
      // V2EX 话题链接
      final topicId = url.substring('/t/'.length);
      context.push('/t/$topicId');
    } else if (url.startsWith('/go/')) {
      // V2EX 节点链接 - 暂时记录日志，后续可以实现节点页面
      LogService.info('Node link clicked', {'nodeUrl': url});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('节点链接: $url')),
      );
    } else if (url.startsWith('http://') || url.startsWith('https://')) {
      // 外部链接
      _launchURL(url);
    } else if (url.startsWith('/')) {
      // 其他V2EX内部链接
      LogService.info('Internal V2EX link clicked', {'url': url});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('V2EX链接: $url')),
      );
    } else {
      // 相对链接或其他链接
      LogService.info('Other link clicked', {'url': url});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('链接: $url')),
      );
    }
  }

  // 启动外部链接
  Future<void> _launchURL(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('无法打开链接: $url')),
          );
        }
      }
    } catch (e) {
      LogService.error('Failed to launch URL', {'url': url, 'error': e.toString()});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('打开链接失败: $url')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // 注意：不在这里初始化replies加载，在build方法中根据topic数据初始化
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMore) return; // 如果正在加载，直接返回

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final repliesState = ref.read(infiniteRepliesProvider(widget.topicId));

      // 检查是否应该加载更多
      if (!repliesState.isLoading && repliesState.hasMoreData) {
        _isLoadingMore = true;
        ref
            .read(infiniteRepliesProvider(widget.topicId).notifier)
            .loadMoreReplies()
            .then((_) {
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final topicAsyncValue = ref.watch(topicDetailProvider(widget.topicId));
    final repliesState = ref.watch(infiniteRepliesProvider(widget.topicId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Topic Details'),
      ),
      body: topicAsyncValue.when(
        data: (topic) {
          // 如果replies状态还未初始化，则进行初始化
          // 使用 isInitialized 标记来避免重复初始化，特别是当topic没有回复时
          if (!repliesState.isInitialized && !repliesState.isLoading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // 只在mounted状态下执行，避免重复调用
              if (mounted) {
                ref
                    .read(infiniteRepliesProvider(widget.topicId).notifier)
                    .loadInitialReplies(topic.replies);
              }
            });
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(topicDetailProvider(widget.topicId));
              ref
                  .read(infiniteRepliesProvider(widget.topicId).notifier)
                  .refresh(topic.replies);
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Topic header
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage:
                            topic.member?.avatarNormalUrl.isNotEmpty == true
                                ? NetworkImage(topic.member!.avatarNormalUrl)
                                : null,
                        child: topic.member?.avatarNormalUrl.isEmpty != false
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              topic.member?.username ?? 'Unknown User',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              timeago.format(
                                  DateTime.fromMillisecondsSinceEpoch(
                                      topic.created * 1000)),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Topic title
                  Text(
                    topic.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  // Topic content
                  if (topic.contentRendered.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Html(
                        data: topic.contentRendered,
                        style: {
                          "body": Style(
                            margin: Margins.zero,
                            padding: HtmlPaddings.zero,
                            fontSize: FontSize(Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.fontSize ??
                                14),
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                          "p": Style(
                            margin: Margins.only(bottom: 8),
                            fontSize: FontSize(Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.fontSize ??
                                14),
                          ),
                          "h1": Style(
                            fontSize: FontSize(Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.fontSize ??
                                24),
                            fontWeight: FontWeight.bold,
                            margin: Margins.only(top: 16, bottom: 8),
                          ),
                          "h2": Style(
                            fontSize: FontSize(Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.fontSize ??
                                20),
                            fontWeight: FontWeight.bold,
                            margin: Margins.only(top: 12, bottom: 6),
                          ),
                          "h3": Style(
                            fontSize: FontSize(Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.fontSize ??
                                18),
                            fontWeight: FontWeight.bold,
                            margin: Margins.only(top: 10, bottom: 4),
                          ),
                          "code": Style(
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            fontFamily: 'monospace',
                            padding: HtmlPaddings.symmetric(
                                horizontal: 4, vertical: 2),
                          ),
                          "pre": Style(
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            padding: HtmlPaddings.all(12),
                            margin: Margins.symmetric(vertical: 8),
                          ),
                          "a": Style(
                            color: Theme.of(context).colorScheme.primary,
                            textDecoration: TextDecoration.underline,
                          ),
                        },
                        onLinkTap: (url, attributes, element) {
                          _handleLinkTap(url, context);
                        },
                      ),
                    ),
                  const SizedBox(height: 24),
                  // Replies section
                  Text(
                    'Replies (${topic.replies})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  // Infinite scroll replies list
                  if (repliesState.isLoading && repliesState.replies.isEmpty)
                    const Center(child: CircularProgressIndicator())
                  else if (repliesState.hasError &&
                      repliesState.replies.isEmpty)
                    Text('Error loading replies: ${repliesState.errorMessage}')
                  else if (repliesState.replies.isEmpty)
                    const Text('No replies yet.')
                  else
                    Column(
                      children: [
                        ...repliesState.replies.map(
                          (reply) => Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withValues(alpha: 0.3),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundImage: reply
                                              .member.avatarNormalUrl.isNotEmpty
                                          ? NetworkImage(
                                              reply.member.avatarNormalUrl)
                                          : null,
                                      child:
                                          reply.member.avatarNormalUrl.isEmpty
                                              ? Text(reply.member.username[0]
                                                  .toUpperCase())
                                              : null,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              reply.member.username,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            timeago.format(DateTime
                                                .fromMillisecondsSinceEpoch(
                                                    reply.created * 1000)),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Html(
                                  data: reply.contentRendered,
                                  style: {
                                    "body": Style(
                                      margin: Margins.zero,
                                      padding: HtmlPaddings.zero,
                                      fontSize: FontSize(Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.fontSize ??
                                          14),
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color,
                                    ),
                                    "p": Style(
                                      margin: Margins.only(bottom: 4),
                                      fontSize: FontSize(Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.fontSize ??
                                          14),
                                    ),
                                    "code": Style(
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      fontFamily: 'monospace',
                                      padding: HtmlPaddings.symmetric(
                                          horizontal: 4, vertical: 2),
                                    ),
                                    "pre": Style(
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      padding: HtmlPaddings.all(8),
                                      margin: Margins.symmetric(vertical: 4),
                                    ),
                                    "a": Style(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      textDecoration: TextDecoration.underline,
                                    ),
                                  },
                                  onLinkTap: (url, attributes, element) {
                                    _handleLinkTap(url, context);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Loading indicator for next page
                        if (repliesState.isLoading &&
                            repliesState.replies.isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        // End of replies indicator
                        if (!repliesState.hasMoreData &&
                            !repliesState.isLoading &&
                            repliesState.replies.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '已加载全部回复',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                  ),
                                  if (repliesState.totalRepliesCount > 0)
                                    Text(
                                      '共 ${repliesState.totalRepliesCount} 条回复',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        // Error indicator for loading more
                        if (repliesState.hasError &&
                            repliesState.replies.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: Column(
                                children: [
                                  Text(
                                      'Error loading more replies: ${repliesState.errorMessage}'),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () => ref
                                        .read(infiniteRepliesProvider(
                                                widget.topicId)
                                            .notifier)
                                        .loadMoreReplies(),
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

void _showUserRepliesDialog(BuildContext context, WidgetRef ref, String topicId,
    String username, List replies) {
  // 过滤出该用户的所有回复
  final userReplies =
      replies.where((reply) => reply.member.username == username).toList();

  LogService.userAction('Show user replies dialog', {
    'username': username,
    'topicId': topicId,
    'repliesCount': userReplies.length,
  });

  showDialog(
    context: context,
    builder: (context) => _UserRepliesDialog(
      username: username,
      userReplies: userReplies,
      topicId: topicId,
    ),
  );
}

class _UserRepliesDialog extends StatelessWidget {
  const _UserRepliesDialog({
    required this.username,
    required this.userReplies,
    required this.topicId,
  });

  final String username;
  final List userReplies;
  final String topicId;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                Icon(
                  Icons.person,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '@$username',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            // 回复数量
            Text(
              '共 ${userReplies.length} 条回复',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),

            // 回复列表
            Expanded(
              child: userReplies.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.comment_outlined,
                            size: 48,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '该用户在此话题下暂无回复',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: userReplies.length,
                      itemBuilder: (context, index) {
                        final reply = userReplies[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withValues(alpha: 0.3),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 时间戳
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    size: 16,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    timeago.format(
                                        DateTime.fromMillisecondsSinceEpoch(
                                            reply.created * 1000)),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // 回复内容
                              Html(
                                data: reply.contentRendered,
                                style: {
                                  "body": Style(
                                    margin: Margins.zero,
                                    padding: HtmlPaddings.zero,
                                    fontSize: FontSize(Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.fontSize ??
                                        14),
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color,
                                  ),
                                  "p": Style(
                                    margin: Margins.only(bottom: 4),
                                    fontSize: FontSize(Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.fontSize ??
                                        14),
                                  ),
                                  "code": Style(
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    fontFamily: 'monospace',
                                    padding: HtmlPaddings.symmetric(
                                        horizontal: 4, vertical: 2),
                                  ),
                                  "pre": Style(
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    padding: HtmlPaddings.all(8),
                                    margin: Margins.symmetric(vertical: 4),
                                  ),
                                  "a": Style(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    textDecoration: TextDecoration.underline,
                                  ),
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // 底部按钮
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('关闭'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
