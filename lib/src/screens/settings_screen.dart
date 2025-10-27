import 'package:flutter/cupertino.dart';
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

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemBackground,
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.separator,
            width: 0.0,
          ),
        ),
        middle: Text(
          '设置',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: CupertinoColors.label,
          ),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Token输入区域
            Container(
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Personal Access Token',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.label,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '请输入您的V2EX Personal Access Token',
                    style: TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    controller: _tokenController,
                    placeholder: '输入您的访问令牌',
                    obscureText: true,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: CupertinoColors.separator,
                        width: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 保存按钮
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                onPressed: () async {
                  final token = _tokenController.text.trim();
                  LogService.userAction('Attempting to save token',
                      {'tokenLength': token.length});

                  if (token.isNotEmpty) {
                    try {
                      await tokenService.setToken(token);
                      LogService.userAction('Token saved successfully');
                      if (context.mounted) {
                        // 显示成功提示
                        showCupertinoDialog(
                          context: context,
                          builder: (context) => CupertinoAlertDialog(
                            title: const Text('保存成功'),
                            content: const Text('访问令牌已成功保存！'),
                            actions: [
                              CupertinoDialogAction(
                                child: const Text('确定'),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                        );
                      }
                    } catch (e, stackTrace) {
                      LogService.error(
                          '❌ Failed to save token in UI', e, stackTrace);
                      if (context.mounted) {
                        // 显示错误提示
                        showCupertinoDialog(
                          context: context,
                          builder: (context) => CupertinoAlertDialog(
                            title: const Text('保存失败'),
                            content: const Text('保存访问令牌失败，请重试。'),
                            actions: [
                              CupertinoDialogAction(
                                child: const Text('确定'),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                        );
                      }
                    }
                  } else {
                    LogService.warning('⚠️ User attempted to save empty token');
                    if (context.mounted) {
                      // 显示输入提示
                      showCupertinoDialog(
                        context: context,
                        builder: (context) => CupertinoAlertDialog(
                          title: const Text('输入错误'),
                          content: const Text('请输入有效的访问令牌。'),
                          actions: [
                            CupertinoDialogAction(
                              child: const Text('确定'),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      );
                    }
                  }
                },
                child: const Text(
                  '保存令牌',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 删除按钮
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                onPressed: () async {
                  // 显示确认对话框
                  final shouldDelete = await showCupertinoDialog<bool>(
                    context: context,
                    builder: (context) => CupertinoAlertDialog(
                      title: const Text('删除令牌'),
                      content: const Text('确定要删除已保存的访问令牌吗？'),
                      actions: [
                        CupertinoDialogAction(
                          child: const Text('取消'),
                          onPressed: () => Navigator.of(context).pop(false),
                        ),
                        CupertinoDialogAction(
                          isDestructiveAction: true,
                          child: const Text('删除'),
                          onPressed: () => Navigator.of(context).pop(true),
                        ),
                      ],
                    ),
                  );

                  if (shouldDelete == true) {
                    LogService.userAction('Attempting to remove token');
                    try {
                      await tokenService.deleteToken();
                      _tokenController.clear();
                      LogService.userAction('Token removed successfully');
                      if (context.mounted) {
                        // 显示删除成功提示
                        showCupertinoDialog(
                          context: context,
                          builder: (context) => CupertinoAlertDialog(
                            title: const Text('删除成功'),
                            content: const Text('访问令牌已删除。'),
                            actions: [
                              CupertinoDialogAction(
                                child: const Text('确定'),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                        );
                      }
                    } catch (e, stackTrace) {
                      LogService.error(
                          '❌ Failed to remove token in UI', e, stackTrace);
                      if (context.mounted) {
                        // 显示删除失败提示
                        showCupertinoDialog(
                          context: context,
                          builder: (context) => CupertinoAlertDialog(
                            title: const Text('删除失败'),
                            content: const Text('删除访问令牌失败，请重试。'),
                            actions: [
                              CupertinoDialogAction(
                                child: const Text('确定'),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                        );
                      }
                    }
                  }
                },
                child: const Text(
                  '删除令牌',
                  style: TextStyle(
                    color: CupertinoColors.systemRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 说明文字
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '提示：Personal Access Token可以在V2EX网站的设置页面获取。设置Token后，您就可以接收和管理通知了。',
                style: TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.secondaryLabel,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
