import 'package:json_annotation/json_annotation.dart';
import 'package:v2ex_client/src/models/member.dart';

part 'reply.g.dart';

@JsonSerializable()
class Reply {
  final int id;
  final String content;
  @JsonKey(name: 'content_rendered')
  final String contentRendered;
  final int created;
  final Member member;

  Reply({
    required this.id,
    required this.content,
    required this.contentRendered,
    required this.created,
    required this.member,
  });

  factory Reply.fromJson(Map<String, dynamic> json) => _$ReplyFromJson(json);
  Map<String, dynamic> toJson() => _$ReplyToJson(this);
}
