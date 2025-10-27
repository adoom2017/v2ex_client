import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:v2ex_client/src/models/topic.dart';
import 'package:timeago/timeago.dart' as timeago;

class TopicListItem extends StatelessWidget {
  const TopicListItem({required this.topic, this.onTap, super.key});

  final Topic topic;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap ?? () => context.push('/t/${topic.id}'),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 用户头像
            CircleAvatar(
              radius: 18,
              backgroundColor: colorScheme.surfaceContainerHighest,
              backgroundImage: topic.member?.avatarNormalUrl.isNotEmpty == true
                  ? NetworkImage(topic.member!.avatarNormalUrl)
                  : null,
              child: topic.member?.avatarNormalUrl.isEmpty != false
                  ? Text(
                      (topic.member?.username ?? topic.lastReplyBy)[0]
                          .toUpperCase(),
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
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
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeago.format(DateTime.fromMillisecondsSinceEpoch(
                            (topic.lastTouched ?? topic.created) * 1000)),
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // 主题标题
                  Text(
                    topic.title,
                    style: textTheme.bodyLarge?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // 右侧信息区域
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 节点标签
                if (topic.node?.title != null && topic.node!.title.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color:
                          colorScheme.primaryContainer.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      topic.node!.title,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                  ),

                // 回复数
                if (topic.replies > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${topic.replies}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
