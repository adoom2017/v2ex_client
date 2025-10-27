import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:v2ex_client/src/providers/notifications_provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsyncValue = ref.watch(notificationsProvider(1));

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
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              CupertinoIcons.xmark,
              color: CupertinoColors.systemGrey,
              size: 16,
            ),
          ),
        ),
        middle: const Text(
          '通知',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: CupertinoColors.label,
          ),
        ),
      ),
      child: notificationsAsyncValue.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(
              child: Text(
                '暂无通知',
                style: TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
            );
          }
          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: () => ref.refresh(notificationsProvider(1).future),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final notification = notifications[index];
                    return Container(
                      color: CupertinoColors.systemBackground,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Container(
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: CupertinoColors.separator
                                .withValues(alpha: 0.3),
                            width: 0.5,
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 用户头像
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: CupertinoColors.systemBlue
                                    .withValues(alpha: 0.1),
                              ),
                              child: Center(
                                child: Text(
                                  notification.member.username.isNotEmpty
                                      ? notification.member.username[0]
                                          .toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: CupertinoColors.systemBlue,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // 通知内容
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 用户名
                                  Text(
                                    '@${notification.member.username}',
                                    style: const TextStyle(
                                      color: CupertinoColors.systemBlue,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  // 通知文本
                                  Text(
                                    notification.text.replaceAll(
                                        RegExp(r'<[^>]*>'), ''), // 移除HTML标签
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: CupertinoColors.label,
                                      height: 1.3,
                                    ),
                                  ),

                                  // payload内容
                                  if (notification.payload.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: CupertinoColors.systemGrey6,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        notification.payload,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: CupertinoColors.secondaryLabel,
                                        ),
                                      ),
                                    ),
                                  ],

                                  // 时间
                                  const SizedBox(height: 8),
                                  Text(
                                    timeago.format(
                                      DateTime.fromMillisecondsSinceEpoch(
                                          notification.created * 1000),
                                      locale: 'zh',
                                    ),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: CupertinoColors.secondaryLabel,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 删除按钮
                            GestureDetector(
                              onTap: () async {
                                // 显示iOS风格的确认对话框
                                final shouldDelete =
                                    await showCupertinoDialog<bool>(
                                  context: context,
                                  builder: (context) => CupertinoAlertDialog(
                                    title: const Text('删除通知'),
                                    content: const Text('确定要删除这条通知吗？'),
                                    actions: [
                                      CupertinoDialogAction(
                                        child: const Text('取消'),
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                      ),
                                      CupertinoDialogAction(
                                        isDestructiveAction: true,
                                        child: const Text('删除'),
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                      ),
                                    ],
                                  ),
                                );

                                if (shouldDelete == true) {
                                  try {
                                    await ref.read(deleteNotificationProvider(
                                            notification.id.toString())
                                        .future);
                                    ref.invalidate(notificationsProvider);
                                    if (context.mounted) {
                                      // 显示成功提示
                                      showCupertinoDialog(
                                        context: context,
                                        builder: (context) =>
                                            CupertinoAlertDialog(
                                          title: const Text('删除成功'),
                                          content: const Text('通知已成功删除'),
                                          actions: [
                                            CupertinoDialogAction(
                                              child: const Text('确定'),
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      String errorMessage = '删除通知失败';
                                      if (e.toString().contains('not found') ||
                                          e
                                              .toString()
                                              .contains('already deleted')) {
                                        errorMessage = '通知已被删除或不存在';
                                      } else if (e
                                          .toString()
                                          .contains('Unauthorized')) {
                                        errorMessage = '请在设置中检查访问令牌';
                                      }

                                      // 显示错误提示
                                      showCupertinoDialog(
                                        context: context,
                                        builder: (context) =>
                                            CupertinoAlertDialog(
                                          title: const Text('删除失败'),
                                          content: Text(errorMessage),
                                          actions: [
                                            CupertinoDialogAction(
                                              child: const Text('刷新'),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                                ref.invalidate(
                                                    notificationsProvider);
                                              },
                                            ),
                                            CupertinoDialogAction(
                                              child: const Text('确定'),
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: CupertinoColors.systemRed
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  CupertinoIcons.delete,
                                  color: CupertinoColors.systemRed,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: notifications.length,
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (err, stack) => Center(
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
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.label,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$err',
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
}
