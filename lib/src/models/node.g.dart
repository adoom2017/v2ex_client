// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'node.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Node _$NodeFromJson(Map<String, dynamic> json) => Node(
      id: (json['id'] as num).toInt(),
      url: json['url'] as String,
      name: json['name'] as String,
      title: json['title'] as String,
      header: json['header'] as String,
      footer: json['footer'] as String,
      content: json['content'] as String?,
      topics: (json['topics'] as num).toInt(),
      avatar: json['avatar'] as String,
      created: (json['created'] as num).toInt(),
      lastModified: (json['last_modified'] as num).toInt(),
    );

Map<String, dynamic> _$NodeToJson(Node instance) => <String, dynamic>{
      'id': instance.id,
      'url': instance.url,
      'name': instance.name,
      'title': instance.title,
      'header': instance.header,
      'footer': instance.footer,
      'content': instance.content,
      'topics': instance.topics,
      'avatar': instance.avatar,
      'created': instance.created,
      'last_modified': instance.lastModified,
    };
