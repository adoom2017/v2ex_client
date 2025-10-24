import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:v2ex_client/src/api/api_client.dart';
import 'package:v2ex_client/src/models/member.dart';

final memberProvider = FutureProvider.autoDispose<Member>((ref) async {
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.getMemberProfile();

  if (response.data != null && response.data['result'] is Map<String, dynamic>) {
    return Member.fromJson(response.data['result']);
  } else {
    throw Exception('Failed to load member profile or invalid data format');
  }
});