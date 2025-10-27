import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:v2ex_client/src/models/topic.dart';
import 'package:timeago/timeago.dart' as timeago;

class TopicListItem extends StatelessWidget {
  const TopicListItem({required this.topic, this.onTap, super.key});

  final Topic topic;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => context.push('/t/${topic.id}'),
      child: Container(
        color: CupertinoColors.systemBackground,
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 用户头像
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CupertinoColors.systemGrey5,
                image: topic.member?.avatarNormalUrl.isNotEmpty == true
                    ? DecorationImage(
                        image: NetworkImage(topic.member!.avatarNormalUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: topic.member?.avatarNormalUrl.isEmpty != false
                  ? Center(
                      child: Text(
                        () {
                          final username =
                              topic.member?.username ?? topic.lastReplyBy;
                          return username.isNotEmpty
                              ? username[0].toUpperCase()
                              : '?';
                        }(),
                        style: const TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // 中间内容区域
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 用户名和时间行
                  Row(
                    children: [
                      Text(
                        topic.member?.username ?? topic.lastReplyBy,
                        style: const TextStyle(
                          color: CupertinoColors.label,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeago.format(
                            DateTime.fromMillisecondsSinceEpoch(
                                (topic.lastModified ?? topic.created) * 1000),
                            locale: 'zh'),
                        style: const TextStyle(
                          color: CupertinoColors.secondaryLabel,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // 标题
                  Text(
                    topic.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: CupertinoColors.label,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // 右侧节点标签和回复数量
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (topic.node?.title.isNotEmpty == true)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      topic.node!.title,
                      style: const TextStyle(
                        fontSize: 11,
                        color: CupertinoColors.secondaryLabel,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                // 回复数量
                if (topic.replies > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.chat_bubble,
                          size: 12,
                          color: CupertinoColors.systemBlue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${topic.replies}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.systemBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
