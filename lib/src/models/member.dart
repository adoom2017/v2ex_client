import 'package:json_annotation/json_annotation.dart';

part 'member.g.dart';

@JsonSerializable()
class Member {
  final int id;
  final String username;
  final String url;
  final String? website;
  final String? twitter;
  final String? psn;
  final String? github;
  final String? btc;
  final String? location;
  final String? tagline;
  final String? bio;

  // API响应中使用的是avatar而不是avatarMini/Normal/Large
  final String avatar;
  final int created;
  final int? pro;

  Member({
    required this.id,
    required this.username,
    required this.url,
    this.website,
    this.twitter,
    this.psn,
    this.github,
    this.btc,
    this.location,
    this.tagline,
    this.bio,
    required this.avatar,
    required this.created,
    this.pro,
  });

  // 便捷方法，保持向后兼容
  String get avatarNormal => avatar;
  String get avatarLarge => avatar;
  String get avatarMini => avatar;

  factory Member.fromJson(Map<String, dynamic> json) => _$MemberFromJson(json);
  Map<String, dynamic> toJson() => _$MemberToJson(this);
}
