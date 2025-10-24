import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:v2ex_client/src/models/topic.dart';
import 'package:timeago/timeago.dart' as timeago;

class TopicListItem extends StatelessWidget {
  const TopicListItem({required this.topic, super.key});

  final Topic topic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return InkWell(
      onTap: () => context.push('/t/${topic.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundImage: topic.member?.avatarNormalUrl.isNotEmpty == true
                ? NetworkImage(topic.member!.avatarNormalUrl)
                : null,
              child: topic.member?.avatarNormalUrl.isNotEmpty != true
                ? (topic.member?.username.isNotEmpty == true
                    ? Text(topic.member!.username[0].toUpperCase())
                    : const Icon(Icons.person))
                : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topic.title,
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        topic.member?.username ?? topic.lastReplyBy,
                        style: textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• ${timeago.format(DateTime.fromMillisecondsSinceEpoch(topic.lastTouched * 1000))}',
                        style: textTheme.bodySmall,
                      ),
                      const Spacer(),
                      if (topic.replies > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${topic.replies}',
                            style: textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
