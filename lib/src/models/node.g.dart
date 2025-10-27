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
      header: json['header'] as String?,
      footer: json['footer'] as String?,
      content: json['content'] as String?,
      topics: (json['topics'] as num).toInt(),
      avatar: json['avatar'] as String?,
      avatarMini: json['avatar_mini'] as String?,
      avatarNormal: json['avatar_normal'] as String?,
      avatarLarge: json['avatar_large'] as String?,
      titleAlternative: json['title_alternative'] as String?,
      stars: (json['stars'] as num?)?.toInt(),
      aliases: json['aliases'] as List<dynamic>?,
      root: json['root'] as bool?,
      parentNodeName: json['parent_node_name'] as String?,
      created: (json['created'] as num?)?.toInt(),
      lastModified: (json['last_modified'] as num?)?.toInt(),
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
      'avatar_mini': instance.avatarMini,
      'avatar_normal': instance.avatarNormal,
      'avatar_large': instance.avatarLarge,
      'title_alternative': instance.titleAlternative,
      'stars': instance.stars,
      'aliases': instance.aliases,
      'root': instance.root,
      'parent_node_name': instance.parentNodeName,
      'created': instance.created,
      'last_modified': instance.lastModified,
    };
