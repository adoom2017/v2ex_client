import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:v2ex_client/src/screens/home_screen.dart';
import 'package:v2ex_client/src/screens/settings_screen.dart';
import 'package:v2ex_client/src/screens/topic_detail_screen.dart';
import 'package:v2ex_client/src/screens/signin_screen.dart';
import 'package:v2ex_client/src/screens/two_factor_auth_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/t/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TopicDetailScreen(topicId: id);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/signin',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/2fa',
        builder: (context, state) {
          final cookies = state.uri.queryParameters['cookies'] ?? '';
          return TwoFactorAuthScreen(initialCookies: cookies);
        },
      ),
    ],
  );
});
