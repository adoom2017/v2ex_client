import 'package:json_annotation/json_annotation.dart';
import 'package:v2ex_client/src/models/member.dart';

part 'notification.g.dart';

@JsonSerializable()
class Notification {
  final int id;
  final Member member;
  final int created;
  final String action;
  final String text;
  final String payload;
  final String payloadRendered;

  Notification({
    required this.id,
    required this.member,
    required this.created,
    required this.action,
    required this.text,
    required this.payload,
    required this.payloadRendered,
  });

  factory Notification.fromJson(Map<String, dynamic> json) => _$NotificationFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationToJson(this);
}
