import 'package:json_annotation/json_annotation.dart';
import 'package:v2ex_client/src/models/member.dart';
import 'package:v2ex_client/src/models/node.dart';

part 'topic.g.dart';

@JsonSerializable()
class Topic {
  final int id;
  final String title;
  final String content;
  @JsonKey(name: 'content_rendered')
  final String contentRendered;
  final int syntax;
  final String url;
  final int replies;
  @JsonKey(name: 'last_reply_by')
  final String lastReplyBy;
  final int created;
  @JsonKey(name: 'last_modified')
  final int lastModified;
  @JsonKey(name: 'last_touched')
  final int lastTouched;

  // 这些字段在主题列表中可能不存在，只在主题详情中存在
  final Node? node;
  final Member? member;

  // 主题详情中的补充信息
  final List<dynamic>? supplements;

  Topic({
    required this.id,
    required this.title,
    required this.content,
    required this.contentRendered,
    required this.syntax,
    required this.url,
    required this.replies,
    required this.lastReplyBy,
    required this.created,
    required this.lastModified,
    required this.lastTouched,
    this.node,
    this.member,
    this.supplements,
  });

  factory Topic.fromJson(Map<String, dynamic> json) => _$TopicFromJson(json);
  Map<String, dynamic> toJson() => _$TopicToJson(this);
}
