// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'topic.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Topic _$TopicFromJson(Map<String, dynamic> json) => Topic(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      content: json['content'] as String,
      contentRendered: json['content_rendered'] as String,
      syntax: (json['syntax'] as num?)?.toInt(),
      url: json['url'] as String,
      replies: (json['replies'] as num).toInt(),
      lastReplyBy: json['last_reply_by'] as String,
      created: (json['created'] as num).toInt(),
      lastModified: (json['last_modified'] as num?)?.toInt(),
      lastTouched: (json['last_touched'] as num?)?.toInt(),
      node: json['node'] == null
          ? null
          : Node.fromJson(json['node'] as Map<String, dynamic>),
      member: json['member'] == null
          ? null
          : Member.fromJson(json['member'] as Map<String, dynamic>),
      supplements: json['supplements'] as List<dynamic>?,
    );

Map<String, dynamic> _$TopicToJson(Topic instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'content': instance.content,
      'content_rendered': instance.contentRendered,
      'syntax': instance.syntax,
      'url': instance.url,
      'replies': instance.replies,
      'last_reply_by': instance.lastReplyBy,
      'created': instance.created,
      'last_modified': instance.lastModified,
      'last_touched': instance.lastTouched,
      'node': instance.node,
      'member': instance.member,
      'supplements': instance.supplements,
    };
