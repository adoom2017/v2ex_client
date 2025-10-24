// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reply.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Reply _$ReplyFromJson(Map<String, dynamic> json) => Reply(
      id: (json['id'] as num).toInt(),
      content: json['content'] as String,
      contentRendered: json['content_rendered'] as String,
      created: (json['created'] as num).toInt(),
      member: Member.fromJson(json['member'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ReplyToJson(Reply instance) => <String, dynamic>{
      'id': instance.id,
      'content': instance.content,
      'content_rendered': instance.contentRendered,
      'created': instance.created,
      'member': instance.member,
    };
