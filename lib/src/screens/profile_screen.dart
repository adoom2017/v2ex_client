import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:v2ex_client/src/providers/member_provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsyncValue = ref.watch(memberProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: memberAsyncValue.when(
        data: (member) {
          return RefreshIndicator(
            onRefresh: () => ref.refresh(memberProvider.future),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: member.avatarLargeUrl.isNotEmpty
                            ? NetworkImage(member.avatarLargeUrl)
                            : null,
                        child: member.avatarLargeUrl.isEmpty
                            ? Text(member.username.isNotEmpty ? member.username[0].toUpperCase() : '?')
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member.username,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            if (member.tagline?.isNotEmpty == true)
                              Text(
                                member.tagline!,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            if (member.created != null)
                              Text(
                                'Joined ${timeago.format(DateTime.fromMillisecondsSinceEpoch(member.created! * 1000))}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (member.bio?.isNotEmpty == true) ...[
                    Text(
                      'Bio',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(member.bio!),
                    const SizedBox(height: 16),
                  ],
                  if (member.location?.isNotEmpty == true) ...[
                    ListTile(
                      leading: const Icon(Icons.location_on),
                      title: Text(member.location!),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                  if (member.website?.isNotEmpty == true) ...[
                    ListTile(
                      leading: const Icon(Icons.language),
                      title: Text(member.website!),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                  if (member.github?.isNotEmpty == true) ...[
                    ListTile(
                      leading: const Icon(Icons.code),
                      title: Text('GitHub: ${member.github!}'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                  if (member.twitter?.isNotEmpty == true) ...[
                    ListTile(
                      leading: const Icon(Icons.alternate_email),
                      title: Text('Twitter: ${member.twitter!}'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
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
