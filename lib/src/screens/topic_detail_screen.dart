import 'package:flutter/cupertino.dart';
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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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
      _showUserRepliesDialog(
          context, ref, widget.topicId, username, repliesState.replies);
    } else if (url.startsWith('/t/')) {
      // V2EX 话题链接
      final topicId = url.substring('/t/'.length);
      context.push('/t/$topicId');
    } else if (url.startsWith('/go/')) {
      // V2EX 节点链接
      LogService.info('Node link clicked', {'nodeUrl': url});
      _showCupertinoSnackBar(context, '节点链接: $url');
    } else if (url.startsWith('http://') || url.startsWith('https://')) {
      // 外部链接
      _launchURL(url);
    } else if (url.startsWith('/')) {
      // 其他V2EX内部链接
      LogService.info('Internal V2EX link clicked', {'url': url});
      _showCupertinoSnackBar(context, 'V2EX链接: $url');
    } else {
      // 相对链接或其他链接
      LogService.info('Other link clicked', {'url': url});
      _showCupertinoSnackBar(context, '链接: $url');
    }
  }

  // iOS风格的消息提示
  void _showCupertinoSnackBar(BuildContext context, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  // 启动外部链接
  Future<void> _launchURL(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          _showCupertinoSnackBar(context, '无法打开链接: $url');
        }
      }
    } catch (e) {
      LogService.error(
          'Failed to launch URL', {'url': url, 'error': e.toString()});
      if (mounted) {
        _showCupertinoSnackBar(context, '打开链接失败: $url');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final topicAsyncValue = ref.watch(topicDetailProvider(widget.topicId));
    final repliesState = ref.watch(infiniteRepliesProvider(widget.topicId));

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('主题详情'),
        backgroundColor: CupertinoColors.systemBackground,
      ),
      child: topicAsyncValue.when(
        data: (topic) {
          // 如果replies状态还未初始化，则进行初始化
          if (!repliesState.isInitialized && !repliesState.isLoading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ref
                    .read(infiniteRepliesProvider(widget.topicId).notifier)
                    .loadInitialReplies(topic.replies);
              }
            });
          }

          return CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: () async {
                  ref.invalidate(topicDetailProvider(widget.topicId));
                  ref
                      .read(infiniteRepliesProvider(widget.topicId).notifier)
                      .refresh(topic.replies);
                },
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Topic header
                    Row(
                      children: [
                        // 用户头像
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: CupertinoColors.systemGrey5,
                          ),
                          child: ClipOval(
                            child: topic.member?.avatarNormalUrl.isNotEmpty ==
                                    true
                                ? Image.network(
                                    topic.member!.avatarNormalUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: CupertinoColors.systemGrey5,
                                        child: Icon(
                                          CupertinoIcons.person,
                                          color: CupertinoColors.systemGrey,
                                          size: 20,
                                        ),
                                      );
                                    },
                                  )
                                : Icon(
                                    CupertinoIcons.person,
                                    color: CupertinoColors.systemGrey,
                                    size: 20,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                topic.member?.username ?? 'Unknown User',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: CupertinoColors.label,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                timeago.format(
                                    DateTime.fromMillisecondsSinceEpoch(
                                        topic.created * 1000)),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: CupertinoColors.secondaryLabel,
                                ),
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
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.label,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Topic content
                    if (topic.contentRendered.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: CupertinoColors.separator,
                            width: 0.5,
                          ),
                        ),
                        child: Html(
                          data: topic.contentRendered,
                          style: {
                            "body": Style(
                              margin: Margins.zero,
                              padding: HtmlPaddings.zero,
                              fontSize: FontSize(16),
                              color: CupertinoColors.label,
                            ),
                            "p": Style(
                              margin: Margins.only(bottom: 8),
                              fontSize: FontSize(16),
                              color: CupertinoColors.label,
                            ),
                            "h1": Style(
                              fontSize: FontSize(24),
                              fontWeight: FontWeight.bold,
                              margin: Margins.only(top: 16, bottom: 8),
                              color: CupertinoColors.label,
                            ),
                            "h2": Style(
                              fontSize: FontSize(20),
                              fontWeight: FontWeight.bold,
                              margin: Margins.only(top: 12, bottom: 6),
                              color: CupertinoColors.label,
                            ),
                            "h3": Style(
                              fontSize: FontSize(18),
                              fontWeight: FontWeight.bold,
                              margin: Margins.only(top: 10, bottom: 4),
                              color: CupertinoColors.label,
                            ),
                            "code": Style(
                              backgroundColor: CupertinoColors.systemGrey6,
                              fontFamily: 'monospace',
                              padding: HtmlPaddings.symmetric(
                                  horizontal: 4, vertical: 2),
                            ),
                            "pre": Style(
                              backgroundColor: CupertinoColors.systemGrey6,
                              padding: HtmlPaddings.all(8),
                              margin: Margins.symmetric(vertical: 4),
                              fontFamily: 'monospace',
                            ),
                            "a": Style(
                              color: CupertinoColors.systemBlue,
                              textDecoration: TextDecoration.underline,
                            ),
                          },
                          onLinkTap: (url, attributes, element) =>
                              _handleLinkTap(url, context),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Replies section header
                    Row(
                      children: [
                        const Icon(
                          CupertinoIcons.chat_bubble_2,
                          color: CupertinoColors.systemBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '回复 (${topic.replies})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.label,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Replies list
                    if (repliesState.hasError)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: CupertinoColors.separator,
                            width: 0.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              CupertinoIcons.exclamationmark_triangle,
                              color: CupertinoColors.systemRed,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '加载回复失败',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: CupertinoColors.label,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              repliesState.errorMessage,
                              style: const TextStyle(
                                fontSize: 14,
                                color: CupertinoColors.secondaryLabel,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            CupertinoButton(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 8),
                              color: CupertinoColors.systemBlue,
                              onPressed: () => ref
                                  .read(infiniteRepliesProvider(widget.topicId)
                                      .notifier)
                                  .loadMoreReplies(),
                              child: const Text('重试'),
                            ),
                          ],
                        ),
                      )
                    else
                      ...repliesState.replies
                          .map<Widget>((reply) => _buildReplyItem(reply))
                          .toList(),

                    // Loading more indicator
                    if (repliesState.isLoading)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: CupertinoActivityIndicator(),
                        ),
                      ),

                    // Load more button or end message
                    if (!repliesState.isLoading && repliesState.hasMoreData)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: CupertinoButton(
                            color: CupertinoColors.systemBlue,
                            onPressed: () => ref
                                .read(infiniteRepliesProvider(widget.topicId)
                                    .notifier)
                                .loadMoreReplies(),
                            child: const Text('加载更多'),
                          ),
                        ),
                      )
                    else if (!repliesState.hasMoreData &&
                        repliesState.replies.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            '已加载全部回复',
                            style: TextStyle(
                              color: CupertinoColors.secondaryLabel,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                  ]),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CupertinoActivityIndicator(),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.exclamationmark_triangle,
                color: CupertinoColors.systemRed,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                '加载失败',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.label,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Error: $err',
                style: const TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.secondaryLabel,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReplyItem(dynamic reply) {
    final repliesState = ref.watch(infiniteRepliesProvider(widget.topicId));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.separator,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reply header
          Row(
            children: [
              // 回复者头像
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CupertinoColors.systemGrey5,
                ),
                child: ClipOval(
                  child: reply.member.avatarNormalUrl.isNotEmpty
                      ? Image.network(
                          reply.member.avatarNormalUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: CupertinoColors.systemGrey5,
                              child: Icon(
                                CupertinoIcons.person,
                                color: CupertinoColors.systemGrey,
                                size: 16,
                              ),
                            );
                          },
                        )
                      : Icon(
                          CupertinoIcons.person,
                          color: CupertinoColors.systemGrey,
                          size: 16,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => _handleLinkTap(
                          '/member/${reply.member.username}', context),
                      child: Text(
                        reply.member.username,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.systemBlue,
                        ),
                      ),
                    ),
                    Text(
                      timeago.format(DateTime.fromMillisecondsSinceEpoch(
                          reply.created * 1000)),
                      style: const TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ],
                ),
              ),
              // Reply number
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey5,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '#${repliesState.replies.indexOf(reply) + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.secondaryLabel,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Reply content
          Html(
            data: reply.contentRendered,
            style: {
              "body": Style(
                margin: Margins.zero,
                padding: HtmlPaddings.zero,
                fontSize: FontSize(15),
                color: CupertinoColors.label,
              ),
              "p": Style(
                margin: Margins.only(bottom: 6),
                fontSize: FontSize(15),
                color: CupertinoColors.label,
              ),
              "code": Style(
                backgroundColor: CupertinoColors.systemGrey6,
                fontFamily: 'monospace',
                padding: HtmlPaddings.symmetric(horizontal: 4, vertical: 2),
              ),
              "pre": Style(
                backgroundColor: CupertinoColors.systemGrey6,
                padding: HtmlPaddings.all(8),
                margin: Margins.symmetric(vertical: 4),
                fontFamily: 'monospace',
              ),
              "a": Style(
                color: CupertinoColors.systemBlue,
                textDecoration: TextDecoration.underline,
              ),
            },
            onLinkTap: (url, attributes, element) =>
                _handleLinkTap(url, context),
          ),
        ],
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

  showCupertinoModalPopup(
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
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: Text('@$username'),
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 回复数量
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '共 ${userReplies.length} 条回复',
                style: const TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
            ),

            // 回复列表
            Expanded(
              child: userReplies.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.chat_bubble_2,
                            size: 48,
                            color: CupertinoColors.systemGrey,
                          ),
                          SizedBox(height: 8),
                          Text(
                            '该用户在此话题下暂无回复',
                            style: TextStyle(
                              fontSize: 16,
                              color: CupertinoColors.secondaryLabel,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: userReplies.length,
                      itemBuilder: (context, index) {
                        final reply = userReplies[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: CupertinoColors.separator,
                              width: 0.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 时间戳
                              Row(
                                children: [
                                  const Icon(
                                    CupertinoIcons.clock,
                                    size: 16,
                                    color: CupertinoColors.secondaryLabel,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    timeago.format(
                                        DateTime.fromMillisecondsSinceEpoch(
                                            reply.created * 1000)),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: CupertinoColors.secondaryLabel,
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
                                    fontSize: FontSize(15),
                                    color: CupertinoColors.label,
                                  ),
                                  "p": Style(
                                    margin: Margins.only(bottom: 4),
                                    fontSize: FontSize(15),
                                  ),
                                  "code": Style(
                                    backgroundColor:
                                        CupertinoColors.systemGrey6,
                                    fontFamily: 'monospace',
                                    padding: HtmlPaddings.symmetric(
                                        horizontal: 4, vertical: 2),
                                  ),
                                  "pre": Style(
                                    backgroundColor:
                                        CupertinoColors.systemGrey6,
                                    padding: HtmlPaddings.all(8),
                                    margin: Margins.symmetric(vertical: 4),
                                  ),
                                  "a": Style(
                                    color: CupertinoColors.systemBlue,
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
          ],
        ),
      ),
    );
  }
}
