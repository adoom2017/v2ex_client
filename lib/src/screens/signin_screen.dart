import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:v2ex_client/src/services/signin_service.dart';
import 'package:v2ex_client/src/services/cookie_service.dart';
import 'package:v2ex_client/src/services/log_service.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _captchaController = TextEditingController();

  bool _isLoading = false;
  String? _onceToken;
  String _captchaImageUrl = 'https://www.v2ex.com/_captcha?once=12345';

  @override
  void initState() {
    super.initState();
    _initializeSignIn();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _captchaController.dispose();
    super.dispose();
  }

  /// 初始化登录页面，获取once token
  Future<void> _initializeSignIn() async {
    final signInService = ref.read(signInServiceProvider);
    final once = await signInService.getOnceToken();

    if (once != null) {
      setState(() {
        _onceToken = once;
        _captchaImageUrl = 'https://www.v2ex.com/_captcha?once=$once';
      });
    } else {
      _showAlert('初始化失败，请重试');
    }
  }

  void _refreshCaptcha() {
    if (_onceToken != null) {
      setState(() {
        // 使用相同的once但添加时间戳来刷新验证码
        _captchaImageUrl =
            'https://www.v2ex.com/_captcha?once=$_onceToken&t=${DateTime.now().millisecondsSinceEpoch}';
      });
    }
  }

  Future<void> _handleSignIn() async {
    // 验证输入
    if (_usernameController.text.isEmpty) {
      _showAlert('请输入用户名或邮箱');
      return;
    }

    if (_passwordController.text.isEmpty) {
      _showAlert('请输入密码');
      return;
    }

    if (_captchaController.text.isEmpty) {
      _showAlert('请输入验证码');
      return;
    }

    if (_onceToken == null) {
      _showAlert('页面未初始化，请刷新重试');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 调用登录服务
      final signInService = ref.read(signInServiceProvider);
      final result = await signInService.signIn(
        username: _usernameController.text,
        password: _passwordController.text,
        captcha: _captchaController.text,
        once: _onceToken!,
      );

      if (!mounted) return;

      if (result.success && result.cookies != null) {
        // 检查是否需要两步验证
        if (result.requires2FA) {
          LogService.info('2FA required, navigating to 2FA screen');

          // 将cookies转为字符串
          final cookieString = result.cookies!.entries
              .map((e) => '${e.key}=${e.value}')
              .join('; ');

          // 跳转到2FA验证页面
          if (mounted) {
            context.go('/2fa?cookies=${Uri.encodeComponent(cookieString)}');
          }
          return;
        }

        // 不需要2FA，直接保存Cookie并登录
        final cookieService = ref.read(cookieServiceProvider);
        final cookieString = result.cookies!.entries
            .map((e) => '${e.key}=${e.value}')
            .join('; ');

        await cookieService.saveCookies(cookieString);

        LogService.info('Sign in successful, navigating to home');

        // 显示成功提示
        if (mounted) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('登录成功'),
              content: const Text('欢迎回来！'),
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
        // 登录失败
        LogService.warning('Sign in failed: ${result.errorMessage}');
        _showAlert(result.errorMessage ?? '登录失败，请重试');

        // 刷新验证码
        _captchaController.clear();
        await _initializeSignIn();
      }
    } catch (e) {
      LogService.error('Sign in error', e, StackTrace.current);
      if (mounted) {
        _showAlert('登录出错：${e.toString()}');
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
      navigationBar: const CupertinoNavigationBar(
        middle: Text('登录'),
        backgroundColor: CupertinoColors.systemBackground,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // 用户名输入框
                _buildInputSection(
                  label: '用户名',
                  child: CupertinoTextField(
                    controller: _usernameController,
                    placeholder: '用户名或电子邮件地址',
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: CupertinoColors.systemGrey4,
                        width: 1,
                      ),
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),

                const SizedBox(height: 24),

                // 密码输入框
                _buildInputSection(
                  label: '密码',
                  child: CupertinoTextField(
                    controller: _passwordController,
                    placeholder: '密码',
                    obscureText: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: CupertinoColors.systemGrey4,
                        width: 1,
                      ),
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),

                const SizedBox(height: 24),

                // 验证码部分
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        '你是机器人吗?',
                        style: TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.label,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    // 验证码图片
                    GestureDetector(
                      onTap: _refreshCaptcha,
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey6,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: CupertinoColors.systemGrey4,
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Image.network(
                            _captchaImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      CupertinoIcons.exclamationmark_triangle,
                                      color: CupertinoColors.systemGrey,
                                      size: 24,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      '加载失败，点击重试',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: CupertinoColors.systemGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CupertinoActivityIndicator(),
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 验证码输入框
                    CupertinoTextField(
                      controller: _captchaController,
                      placeholder: '请输入上图中的验证码，点击可以更换图片',
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: CupertinoColors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: CupertinoColors.systemGrey4,
                          width: 1,
                        ),
                      ),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // 登录按钮
                CupertinoButton(
                  color: CupertinoColors.systemBlue,
                  borderRadius: BorderRadius.circular(8),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  onPressed: _isLoading ? null : _handleSignIn,
                  child: _isLoading
                      ? const CupertinoActivityIndicator(
                          color: CupertinoColors.white,
                        )
                      : const Text(
                          '登录',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputSection({
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: CupertinoColors.label,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        child,
      ],
    );
  }
}
