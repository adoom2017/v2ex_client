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
  final int? syntax;
  final String url;
  final int replies;
  @JsonKey(name: 'last_reply_by')
  final String lastReplyBy;
  final int created;
  @JsonKey(name: 'last_modified')
  final int? lastModified;
  @JsonKey(name: 'last_touched')
  final int? lastTouched;

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
    this.syntax,
    required this.url,
    required this.replies,
    required this.lastReplyBy,
    required this.created,
    this.lastModified,
    this.lastTouched,
    this.node,
    this.member,
    this.supplements,
  });

  factory Topic.fromJson(Map<String, dynamic> json) => _$TopicFromJson(json);
  Map<String, dynamic> toJson() => _$TopicToJson(this);

  Topic copyWith({
    int? id,
    String? title,
    String? content,
    String? contentRendered,
    int? syntax,
    String? url,
    int? replies,
    String? lastReplyBy,
    int? created,
    int? lastModified,
    int? lastTouched,
    Node? node,
    Member? member,
    List<dynamic>? supplements,
  }) {
    return Topic(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      contentRendered: contentRendered ?? this.contentRendered,
      syntax: syntax ?? this.syntax,
      url: url ?? this.url,
      replies: replies ?? this.replies,
      lastReplyBy: lastReplyBy ?? this.lastReplyBy,
      created: created ?? this.created,
      lastModified: lastModified ?? this.lastModified,
      lastTouched: lastTouched ?? this.lastTouched,
      node: node ?? this.node,
      member: member ?? this.member,
      supplements: supplements ?? this.supplements,
    );
  }
}
