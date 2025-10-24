import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:v2ex_client/src/services/token_service.dart';
import 'package:v2ex_client/src/services/log_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _tokenController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    LogService.userAction('Loading saved token from storage');
    final token = await ref.read(tokenServiceProvider).getToken();
    if (token != null) {
      _tokenController.text = token;
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokenService = ref.watch(tokenServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          TextField(
            controller: _tokenController,
            decoration: const InputDecoration(
              labelText: 'Personal Access Token',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final token = _tokenController.text.trim();
              LogService.userAction('Attempting to save token', {'tokenLength': token.length});

              if (token.isNotEmpty) {
                try {
                  await tokenService.setToken(token);
                  LogService.userAction('Token saved successfully');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Token saved successfully!')),
                    );
                  }
                } catch (e, stackTrace) {
                  LogService.error('❌ Failed to save token in UI', e, stackTrace);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to save token. Please try again.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } else {
                LogService.warning('⚠️ User attempted to save empty token');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid token.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              }
            },
            child: const Text('Save Token'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () async {
              LogService.userAction('Attempting to remove token');
              try {
                await tokenService.deleteToken();
                _tokenController.clear();
                LogService.userAction('Token removed successfully');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Token removed.')),
                  );
                }
              } catch (e, stackTrace) {
                LogService.error('❌ Failed to remove token in UI', e, stackTrace);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to remove token. Please try again.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remove Token'),
          ),
        ],
      ),
    );
  }
}