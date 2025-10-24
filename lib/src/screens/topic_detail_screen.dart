import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:v2ex_client/src/providers/topic_provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class TopicDetailScreen extends ConsumerWidget {
  const TopicDetailScreen({required this.topicId, super.key});
  final String topicId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicAsyncValue = ref.watch(topicDetailProvider(topicId));
    final repliesParam = TopicRepliesParam(topicId: topicId, page: 1);
    final repliesAsyncValue = ref.watch(topicRepliesProvider(repliesParam));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Topic Details'),
      ),
      body: topicAsyncValue.when(
        data: (topic) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(topicDetailProvider(topicId));
              ref.invalidate(topicRepliesProvider(repliesParam));
              await Future.wait([
                ref.refresh(topicDetailProvider(topicId).future),
                ref.refresh(topicRepliesProvider(repliesParam).future),
              ]);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Topic header
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: topic.member?.avatarNormal != null
                          ? NetworkImage(topic.member!.avatarNormal)
                          : null,
                        child: topic.member?.avatarNormal == null
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
                              timeago.format(DateTime.fromMillisecondsSinceEpoch(topic.created * 1000)),
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
                  if (topic.content.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(topic.content),
                    ),
                  const SizedBox(height: 24),
                  // Replies section
                  Text(
                    'Replies (${topic.replies})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  repliesAsyncValue.when(
                    data: (replies) {
                      if (replies.isEmpty) {
                        return const Text('No replies yet.');
                      }
                      return Column(
                        children: replies.map((reply) =>
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
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
                                      backgroundImage: NetworkImage(reply.member.avatarNormal),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      reply.member.username,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      timeago.format(DateTime.fromMillisecondsSinceEpoch(reply.created * 1000)),
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(reply.content),
                              ],
                            ),
                          ),
                        ).toList(),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Text('Error loading replies: $err'),
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
