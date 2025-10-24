import 'package:json_annotation/json_annotation.dart';
import 'package:v2ex_client/src/models/member.dart';

part 'notification.g.dart';

@JsonSerializable()
class Notification {
  final int id;
  @JsonKey(name: 'member_id')
  final int memberId;
  @JsonKey(name: 'for_member_id')
  final int forMemberId;
  final Member member;
  final int created;
  final String text;
  final String payload;
  @JsonKey(name: 'payload_rendered')
  final String payloadRendered;

  Notification({
    required this.id,
    required this.memberId,
    required this.forMemberId,
    required this.member,
    required this.created,
    required this.text,
    required this.payload,
    required this.payloadRendered,
  });

  factory Notification.fromJson(Map<String, dynamic> json) => _$NotificationFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationToJson(this);
}
