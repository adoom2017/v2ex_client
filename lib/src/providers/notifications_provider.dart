import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:v2ex_client/src/api/api_client.dart';
import 'package:v2ex_client/src/models/notification.dart';

final notificationsProvider = FutureProvider.autoDispose.family<List<Notification>, int>((ref, page) async {
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.getNotifications(p: page);

  if (response.data != null && response.data['result'] is List) {
    return (response.data['result'] as List)
        .map((notificationJson) => Notification.fromJson(notificationJson))
        .toList();
  } else {
    throw Exception('Failed to load notifications or invalid data format');
  }
});

final deleteNotificationProvider = FutureProvider.autoDispose.family<void, String>((ref, notificationId) async {
  final apiClient = ref.read(apiClientProvider);
  await apiClient.deleteNotification(notificationId);
});