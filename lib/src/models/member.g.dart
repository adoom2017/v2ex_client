// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Member _$MemberFromJson(Map<String, dynamic> json) => Member(
      id: (json['id'] as num).toInt(),
      username: json['username'] as String,
      url: json['url'] as String,
      website: json['website'] as String?,
      twitter: json['twitter'] as String?,
      psn: json['psn'] as String?,
      github: json['github'] as String?,
      btc: json['btc'] as String?,
      location: json['location'] as String?,
      tagline: json['tagline'] as String?,
      bio: json['bio'] as String?,
      avatar: json['avatar'] as String,
      created: (json['created'] as num).toInt(),
      pro: (json['pro'] as num?)?.toInt(),
    );

Map<String, dynamic> _$MemberToJson(Member instance) => <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'url': instance.url,
      'website': instance.website,
      'twitter': instance.twitter,
      'psn': instance.psn,
      'github': instance.github,
      'btc': instance.btc,
      'location': instance.location,
      'tagline': instance.tagline,
      'bio': instance.bio,
      'avatar': instance.avatar,
      'created': instance.created,
      'pro': instance.pro,
    };
