// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Notification _$NotificationFromJson(Map<String, dynamic> json) => Notification(
      id: (json['id'] as num).toInt(),
      memberId: (json['member_id'] as num).toInt(),
      forMemberId: (json['for_member_id'] as num).toInt(),
      member: Member.fromJson(json['member'] as Map<String, dynamic>),
      created: (json['created'] as num).toInt(),
      text: json['text'] as String,
      payload: json['payload'] as String,
      payloadRendered: json['payload_rendered'] as String,
    );

Map<String, dynamic> _$NotificationToJson(Notification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'member_id': instance.memberId,
      'for_member_id': instance.forMemberId,
      'member': instance.member,
      'created': instance.created,
      'text': instance.text,
      'payload': instance.payload,
      'payload_rendered': instance.payloadRendered,
    };
