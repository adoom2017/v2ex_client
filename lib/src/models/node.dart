import 'package:json_annotation/json_annotation.dart';

part 'node.g.dart';

@JsonSerializable()
class Node {
  final int id;
  final String url;
  final String name;
  final String title;
  final String header;
  final String footer;
  final String? content;
  final int topics;

  // API响应中使用的是avatar而不是avatarMini/Normal/Large
  final String avatar;
  final int created;
  @JsonKey(name: 'last_modified')
  final int lastModified;

  Node({
    required this.id,
    required this.url,
    required this.name,
    required this.title,
    required this.header,
    required this.footer,
    this.content,
    required this.topics,
    required this.avatar,
    required this.created,
    required this.lastModified,
  });

  // 便捷方法，保持向后兼容
  String get avatarNormal => avatar;
  String get avatarLarge => avatar;
  String get avatarMini => avatar;

  factory Node.fromJson(Map<String, dynamic> json) => _$NodeFromJson(json);
  Map<String, dynamic> toJson() => _$NodeToJson(this);
}
