import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:v2ex_client/src/services/signin_service.dart';
import 'package:v2ex_client/src/services/cookie_service.dart';
import 'package:v2ex_client/src/services/log_service.dart';

class TwoFactorAuthScreen extends ConsumerStatefulWidget {
  final String initialCookies;

  const TwoFactorAuthScreen({
    required this.initialCookies,
    super.key,
  });

  @override
  ConsumerState<TwoFactorAuthScreen> createState() =>
      _TwoFactorAuthScreenState();
}

class _TwoFactorAuthScreenState extends ConsumerState<TwoFactorAuthScreen> {
  final _codeController = TextEditingController();

  bool _isLoading = false;
  String? _onceToken;

  @override
  void initState() {
    super.initState();
    _initialize2FA();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  /// 初始化2FA页面，获取once token
  Future<void> _initialize2FA() async {
    final signInService = ref.read(signInServiceProvider);
    final once = await signInService.get2FAOnceToken(widget.initialCookies);

    if (once != null) {
      setState(() {
        _onceToken = once;
      });
    } else {
      _showAlert('初始化失败，请重新登录');
    }
  }

  Future<void> _handleVerify() async {
    // 验证输入
    if (_codeController.text.isEmpty) {
      _showAlert('请输入两步验证码');
      return;
    }

    if (_onceToken == null) {
      _showAlert('页面未初始化，请重新登录');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 调用2FA验证服务
      final signInService = ref.read(signInServiceProvider);
      final result = await signInService.verify2FA(
        code: _codeController.text,
        once: _onceToken!,
        cookies: widget.initialCookies,
      );

      if (!mounted) return;

      if (result.success && result.cookies != null) {
        // 保存Cookie
        final cookieService = ref.read(cookieServiceProvider);
        final cookieString = result.cookies!.entries
            .map((e) => '${e.key}=${e.value}')
            .join('; ');

        await cookieService.saveCookies(cookieString);

        LogService.info('2FA verification successful, navigating to home');

        // 显示成功提示
        if (mounted) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('验证成功'),
              content: const Text('登录成功，欢迎回来！'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('确定'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    // 跳转到首页
                    context.go('/home');
                  },
                ),
              ],
            ),
          );
        }
      } else {
        // 验证失败
        LogService.warning('2FA verification failed: ${result.errorMessage}');
        _showAlert(result.errorMessage ?? '验证失败，请重试');

        // 清空验证码
        _codeController.clear();
      }
    } catch (e) {
      LogService.error('2FA verification error', e, StackTrace.current);
      if (mounted) {
        _showAlert('验证出错：${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showAlert(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('两步验证'),
        backgroundColor: CupertinoColors.systemBackground,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('取消'),
          onPressed: () => context.go('/signin'),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // 图标
                const Icon(
                  CupertinoIcons.lock_shield,
                  size: 80,
                  color: CupertinoColors.systemBlue,
                ),

                const SizedBox(height: 24),

                // 标题
                const Text(
                  '两步验证',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.label,
                  ),
                ),

                const SizedBox(height: 12),

                // 说明文字
                const Text(
                  '请输入您的两步验证码\n通常是6位数字',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.secondaryLabel,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 40),

                // 验证码输入框
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        '验证码',
                        style: TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.label,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    CupertinoTextField(
                      controller: _codeController,
                      placeholder: '请输入6位验证码',
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        letterSpacing: 8,
                        fontWeight: FontWeight.w500,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: CupertinoColors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: CupertinoColors.systemGrey4,
                          width: 1,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // 验证按钮
                CupertinoButton(
                  color: CupertinoColors.systemBlue,
                  borderRadius: BorderRadius.circular(8),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  onPressed: _isLoading ? null : _handleVerify,
                  child: _isLoading
                      ? const CupertinoActivityIndicator(
                          color: CupertinoColors.white,
                        )
                      : const Text(
                          '验证',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),

                const SizedBox(height: 20),

                // 提示信息
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '💡 提示：验证码通常来自您的验证器应用（如Google Authenticator、Authy等）',
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
        ),
      ),
    );
  }
}
