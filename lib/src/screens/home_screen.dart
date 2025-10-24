import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:v2ex_client/src/providers/topics_provider.dart';
import 'package:v2ex_client/src/widgets/topic_list_item.dart';
import 'package:v2ex_client/src/services/log_service.dart';

final selectedNodeProvider = StateProvider<String>((ref) => 'python');

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedNode = ref.watch(selectedNodeProvider);
    final topicsAsyncValue = ref.watch(topicsProvider(selectedNode));

    return Scaffold(
      appBar: AppBar(
        title: const Text('V2EX'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String node) {
              LogService.userAction('Node changed', {'from': selectedNode, 'to': node});
              ref.read(selectedNodeProvider.notifier).state = node;
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(value: 'python', child: Text('Python')),
              const PopupMenuItem(value: 'java', child: Text('Java')),
              const PopupMenuItem(value: 'javascript', child: Text('JavaScript')),
              const PopupMenuItem(value: 'android', child: Text('Android')),
              const PopupMenuItem(value: 'ios', child: Text('iOS')),
              const PopupMenuItem(value: 'flutter', child: Text('Flutter')),
              const PopupMenuItem(value: 'react', child: Text('React')),
              const PopupMenuItem(value: 'vue', child: Text('Vue')),
            ],
            child: Chip(
              label: Text(selectedNode.toUpperCase()),
              avatar: const Icon(Icons.keyboard_arrow_down),
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
              LogService.userAction('Pull to refresh triggered', {'node': selectedNode});
              return ref.refresh(topicsProvider(selectedNode).future);
            },
            child: ListView.builder(
              itemCount: topics.length,
              itemBuilder: (context, index) {
                final topic = topics[index];
                return TopicListItem(topic: topic);
              },
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
                  LogService.userAction('Retry button pressed', {'node': selectedNode});
                  ref.invalidate(topicsProvider(selectedNode));
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