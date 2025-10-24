import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:v2ex_client/src/providers/topic_provider.dart';
import 'package:v2ex_client/src/services/log_service.dart';
import 'package:timeago/timeago.dart' as timeago;

// State provider for current replies page
final currentRepliesPageProvider = StateProvider.autoDispose.family<int, String>((ref, topicId) => 1);

class TopicDetailScreen extends ConsumerWidget {
  const TopicDetailScreen({required this.topicId, super.key});
  final String topicId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicAsyncValue = ref.watch(topicDetailProvider(topicId));
    final currentRepliesPage = ref.watch(currentRepliesPageProvider(topicId));
    final repliesParam = TopicRepliesParam(topicId: topicId, page: currentRepliesPage);
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Replies (${topic.replies})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Page $currentRepliesPage',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Replies pagination controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: currentRepliesPage > 1 ? () {
                          LogService.userAction('Previous replies page - topic: $topicId, from: $currentRepliesPage, to: ${currentRepliesPage - 1}');
                          ref.read(currentRepliesPageProvider(topicId).notifier).state = currentRepliesPage - 1;
                        } : null,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Previous'),
                      ),
                      GestureDetector(
                        onTap: () => _showRepliesPageJumpDialog(context, ref, topicId, currentRepliesPage),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).colorScheme.outline),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('Page $currentRepliesPage'),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          LogService.userAction('Next replies page - topic: $topicId, from: $currentRepliesPage, to: ${currentRepliesPage + 1}');
                          ref.read(currentRepliesPageProvider(topicId).notifier).state = currentRepliesPage + 1;
                        },
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Next'),
                      ),
                    ],
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

void _showRepliesPageJumpDialog(BuildContext context, WidgetRef ref, String topicId, int currentPage) {
  showDialog(
    context: context,
    builder: (context) => _RepliesPageJumpDialog(
      topicId: topicId,
      currentPage: currentPage,
      onPageJump: (page) {
        LogService.userAction('Jump to replies page - topic: $topicId, from: $currentPage, to: $page');
        ref.read(currentRepliesPageProvider(topicId).notifier).state = page;
      },
    ),
  );
}

class _RepliesPageJumpDialog extends StatefulWidget {
  const _RepliesPageJumpDialog({
    required this.topicId,
    required this.currentPage,
    required this.onPageJump,
  });

  final String topicId;
  final int currentPage;
  final Function(int) onPageJump;

  @override
  State<_RepliesPageJumpDialog> createState() => _RepliesPageJumpDialogState();
}

class _RepliesPageJumpDialogState extends State<_RepliesPageJumpDialog> {
  late TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentPage.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _jumpToPage() {
    final input = _controller.text.trim();
    final page = int.tryParse(input);

    if (page == null || page < 1) {
      setState(() {
        _errorText = 'Please enter a valid page number (1 or greater)';
      });
      return;
    }

    widget.onPageJump(page);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Jump to Replies Page'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Current page: ${widget.currentPage}'),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Page number',
              errorText: _errorText,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _jumpToPage(),
            onChanged: (_) {
              if (_errorText != null) {
                setState(() {
                  _errorText = null;
                });
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _jumpToPage,
          child: const Text('Jump'),
        ),
      ],
    );
  }
}
