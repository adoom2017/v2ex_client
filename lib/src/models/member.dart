import 'package:json_annotation/json_annotation.dart';

part 'member.g.dart';

@JsonSerializable()
class Member {
  final int? id;
  final String username;
  final String? url;
  final String? website;
  final String? twitter;
  final String? psn;
  final String? github;
  final String? btc;
  final String? location;
  final String? tagline;
  final String? bio;

  // API响应中可能有分别的avatar字段（用户资料API）或单一avatar字段（topic详情API）
  @JsonKey(name: 'avatar_mini')
  final String? avatarMini;
  @JsonKey(name: 'avatar_normal')
  final String? avatarNormal;
  @JsonKey(name: 'avatar_large')
  final String? avatarLarge;

  // Topic详情API中使用的单一avatar字段
  final String? avatar;

  final int? created;
  @JsonKey(name: 'last_modified')
  final int? lastModified;
  final int? pro;

  Member({
    this.id,
    required this.username,
    this.url,
    this.website,
    this.twitter,
    this.psn,
    this.github,
    this.btc,
    this.location,
    this.tagline,
    this.bio,
    this.avatarMini,
    this.avatarNormal,
    this.avatarLarge,
    this.avatar,
    this.created,
    this.lastModified,
    this.pro,
  });

  // 便捷方法，优先使用分别的avatar字段，如果没有则使用单一avatar字段
  String get avatarNormalUrl => avatarNormal ?? avatar ?? avatarLarge ?? avatarMini ?? '';
  String get avatarLargeUrl => avatarLarge ?? avatar ?? avatarNormal ?? avatarMini ?? '';
  String get avatarMiniUrl => avatarMini ?? avatar ?? avatarNormal ?? avatarLarge ?? '';  factory Member.fromJson(Map<String, dynamic> json) => _$MemberFromJson(json);
  Map<String, dynamic> toJson() => _$MemberToJson(this);
}
