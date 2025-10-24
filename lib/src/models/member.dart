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

  // API响应中分别使用avatar_mini, avatar_normal, avatar_large
  @JsonKey(name: 'avatar_mini')
  final String? avatarMini;
  @JsonKey(name: 'avatar_normal')
  final String? avatarNormal;
  @JsonKey(name: 'avatar_large')
  final String? avatarLarge;

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
    this.created,
    this.lastModified,
    this.pro,
  });

  // 便捷方法，保持向后兼容，同时处理通知API中只有username的情况
  String get avatarNormalUrl => avatarNormal ?? avatarLarge ?? avatarMini ?? '';
  String get avatarLargeUrl => avatarLarge ?? avatarNormal ?? avatarMini ?? '';
  String get avatarMiniUrl => avatarMini ?? avatarNormal ?? avatarLarge ?? '';

  factory Member.fromJson(Map<String, dynamic> json) => _$MemberFromJson(json);
  Map<String, dynamic> toJson() => _$MemberToJson(this);
}
