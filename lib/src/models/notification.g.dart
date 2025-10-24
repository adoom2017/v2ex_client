// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Notification _$NotificationFromJson(Map<String, dynamic> json) => Notification(
      id: (json['id'] as num).toInt(),
      member: Member.fromJson(json['member'] as Map<String, dynamic>),
      created: (json['created'] as num).toInt(),
      action: json['action'] as String,
      text: json['text'] as String,
      payload: json['payload'] as String,
      payloadRendered: json['payloadRendered'] as String,
    );

Map<String, dynamic> _$NotificationToJson(Notification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'member': instance.member,
      'created': instance.created,
      'action': instance.action,
      'text': instance.text,
      'payload': instance.payload,
      'payloadRendered': instance.payloadRendered,
    };
