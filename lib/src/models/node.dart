import 'package:json_annotation/json_annotation.dart';

part 'node.g.dart';

@JsonSerializable()
class Node {
  final int id;
  final String url;
  final String name;
  final String title;
  final String? header;
  final String? footer;
  final String? content;
  final int topics;

  // 处理不同API中的avatar字段格式
  final String? avatar;
  @JsonKey(name: 'avatar_mini')
  final String? avatarMini;
  @JsonKey(name: 'avatar_normal')
  final String? avatarNormal;
  @JsonKey(name: 'avatar_large')
  final String? avatarLarge;

  // 最新主题API中的额外字段
  @JsonKey(name: 'title_alternative')
  final String? titleAlternative;
  final int? stars;
  final List<dynamic>? aliases;
  final bool? root;
  @JsonKey(name: 'parent_node_name')
  final String? parentNodeName;

  final int? created;
  @JsonKey(name: 'last_modified')
  final int? lastModified;

  Node({
    required this.id,
    required this.url,
    required this.name,
    required this.title,
    this.header,
    this.footer,
    this.content,
    required this.topics,
    this.avatar,
    this.avatarMini,
    this.avatarNormal,
    this.avatarLarge,
    this.titleAlternative,
    this.stars,
    this.aliases,
    this.root,
    this.parentNodeName,
    this.created,
    this.lastModified,
  });

  // 便捷方法，优先使用特定的avatar字段，回退到通用avatar
  String get avatarNormalUrl => avatarNormal ?? avatar ?? '';
  String get avatarLargeUrl => avatarLarge ?? avatar ?? '';
  String get avatarMiniUrl => avatarMini ?? avatar ?? '';

  factory Node.fromJson(Map<String, dynamic> json) => _$NodeFromJson(json);
  Map<String, dynamic> toJson() => _$NodeToJson(this);
}
