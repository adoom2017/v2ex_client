import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import 'package:v2ex_client/src/models/topic.dart';
import 'package:v2ex_client/src/models/member.dart';
import 'package:v2ex_client/src/models/node.dart' as v2ex;
import 'package:v2ex_client/src/services/log_service.dart';

/// HTML解析服务，用于解析V2EX页面
class HtmlParserService {
  /// 解析主题列表页面的 TopicsNode 区域
  static List<Topic> parseTopicsNode(String htmlContent, {String? nodeKey}) {
    try {
      final document = html_parser.parse(htmlContent);
      final topicsNode = document.getElementById('TopicsNode');

      if (topicsNode == null) {
        LogService.warning('TopicsNode not found in HTML');
        return [];
      }

      // 尝试从页面中提取节点信息
      String? extractedNodeKey = nodeKey;
      String? nodeTitle;

      if (extractedNodeKey == null) {
        // 从 JavaScript 变量中提取
        final scriptMatch =
            RegExp(r'var nodeName = "([^"]+)"').firstMatch(htmlContent);
        if (scriptMatch != null) {
          extractedNodeKey = scriptMatch.group(1);
        }
      }

      // 提取节点标题
      final titleMatch =
          RegExp(r'<title>V2EX › ([^<]+)</title>').firstMatch(htmlContent);
      if (titleMatch != null) {
        nodeTitle = titleMatch.group(1);
      }

      final topics = <Topic>[];

      // 查找所有的 cell（不需要 item class）
      final cellItems = topicsNode.querySelectorAll('.cell');

      LogService.info('Found ${cellItems.length} cell items in TopicsNode');

      for (final cell in cellItems) {
        try {
          final topic = _parseTopicCell(
            cell,
            nodeKey: extractedNodeKey,
            nodeTitle: nodeTitle,
          );
          if (topic != null) {
            topics.add(topic);
          }
        } catch (e) {
          LogService.error('Failed to parse topic cell', e, StackTrace.current);
        }
      }

      LogService.info('Parsed ${topics.length} topics from HTML');
      return topics;
    } catch (e, stackTrace) {
      LogService.error('Failed to parse topics node', e, stackTrace);
      return [];
    }
  }

  /// 解析单个主题 cell
  static Topic? _parseTopicCell(
    Element cell, {
    String? nodeKey,
    String? nodeTitle,
  }) {
    try {
      // 提取主题ID和标题
      final titleElement = cell.querySelector('.item_title a.topic-link');
      if (titleElement == null) return null;

      final href = titleElement.attributes['href'] ?? '';
      final titleMatch = RegExp(r'/t/(\d+)').firstMatch(href);
      if (titleMatch == null) return null;

      final topicId = titleMatch.group(1)!;
      final title = titleElement.text.trim();

      // 提取用户信息
      final avatarElement = cell.querySelector('img.avatar');
      final usernameElement = cell.querySelector('.topic_info strong a');

      Member? member;
      if (avatarElement != null && usernameElement != null) {
        final avatarSrc = avatarElement.attributes['src'] ?? '';
        final username = usernameElement.text.trim();

        // 提取用户ID
        final userIdStr = avatarElement.attributes['data-uid'] ?? '';
        final userId = userIdStr.isNotEmpty ? int.tryParse(userIdStr) : null;

        member = Member(
          id: userId,
          username: username,
          avatar: avatarSrc.startsWith('//') ? 'https:$avatarSrc' : avatarSrc,
          avatarMini:
              avatarSrc.startsWith('//') ? 'https:$avatarSrc' : avatarSrc,
          avatarNormal:
              avatarSrc.startsWith('//') ? 'https:$avatarSrc' : avatarSrc,
          avatarLarge:
              avatarSrc.startsWith('//') ? 'https:$avatarSrc' : avatarSrc,
        );
      }

      // 提取节点信息（优先使用参数传入的节点信息）
      final node = v2ex.Node(
        id: 0,
        url: nodeKey != null ? '/go/$nodeKey' : '/go/unknown',
        name: nodeKey ?? 'unknown',
        title: nodeTitle ?? nodeKey ?? '未知节点',
        topics: 0,
      );

      // 提取回复数
      final replyElement = cell.querySelector('.count_livid, .count_orange');
      final replies = replyElement != null
          ? int.tryParse(replyElement.text.trim()) ?? 0
          : 0;

      // 提取时间信息
      final timeElement = cell.querySelector('.topic_info span[title]');
      int created = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (timeElement != null) {
        // 优先使用 title 属性中的绝对时间
        final timeTitle = timeElement.attributes['title'];
        if (timeTitle != null && timeTitle.isNotEmpty) {
          created = _parseAbsoluteTime(timeTitle);
        } else {
          // 回退到相对时间
          final timeText = timeElement.text.trim();
          created = _parseRelativeTime(timeText);
        }
      }

      // 提取最后回复者
      String? lastReplyBy;
      final lastReplyMatch = RegExp(r'最后回复来自.*?<strong><a[^>]*>([^<]+)</a>')
          .firstMatch(cell.outerHtml);
      if (lastReplyMatch != null) {
        lastReplyBy = lastReplyMatch.group(1);
      }

      return Topic(
        id: int.parse(topicId),
        url: '/t/$topicId',
        title: title,
        content: '',
        contentRendered: '',
        created: created,
        lastModified: created,
        replies: replies,
        member: member,
        node: node,
        lastReplyBy: lastReplyBy ?? '',
      );
    } catch (e) {
      LogService.error('Failed to parse topic cell', e, StackTrace.current);
      return null;
    }
  }

  /// 解析绝对时间（如 "2025-10-28 15:07:33 +08:00"）
  static int _parseAbsoluteTime(String timeText) {
    try {
      // 匹配格式: "2025-10-28 15:07:33 +08:00"
      final match = RegExp(r'(\d{4})-(\d{2})-(\d{2})\s+(\d{2}):(\d{2}):(\d{2})')
          .firstMatch(timeText);

      if (match != null) {
        final dateTime = DateTime(
          int.parse(match.group(1)!),
          int.parse(match.group(2)!),
          int.parse(match.group(3)!),
          int.parse(match.group(4)!),
          int.parse(match.group(5)!),
          int.parse(match.group(6)!),
        );
        return dateTime.millisecondsSinceEpoch ~/ 1000;
      }
    } catch (e) {
      LogService.warning('Failed to parse absolute time: $timeText');
    }

    // 无法解析，返回当前时间
    return DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }

  /// 解析相对时间（如 "2小时前"、"1天前"）
  static int _parseRelativeTime(String timeText) {
    final now = DateTime.now();

    try {
      // 匹配 "X分钟前"
      var match = RegExp(r'(\d+)\s*分钟前').firstMatch(timeText);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        return now
                .subtract(Duration(minutes: minutes))
                .millisecondsSinceEpoch ~/
            1000;
      }

      // 匹配 "X小时前"
      match = RegExp(r'(\d+)\s*小时前').firstMatch(timeText);
      if (match != null) {
        final hours = int.parse(match.group(1)!);
        return now.subtract(Duration(hours: hours)).millisecondsSinceEpoch ~/
            1000;
      }

      // 匹配 "X天前"
      match = RegExp(r'(\d+)\s*天前').firstMatch(timeText);
      if (match != null) {
        final days = int.parse(match.group(1)!);
        return now.subtract(Duration(days: days)).millisecondsSinceEpoch ~/
            1000;
      }

      // 匹配绝对时间格式 "2024-01-01 12:00:00"
      match = RegExp(r'(\d{4})-(\d{2})-(\d{2})\s+(\d{2}):(\d{2}):(\d{2})')
          .firstMatch(timeText);
      if (match != null) {
        final dateTime = DateTime(
          int.parse(match.group(1)!),
          int.parse(match.group(2)!),
          int.parse(match.group(3)!),
          int.parse(match.group(4)!),
          int.parse(match.group(5)!),
          int.parse(match.group(6)!),
        );
        return dateTime.millisecondsSinceEpoch ~/ 1000;
      }
    } catch (e) {
      LogService.warning('Failed to parse time: $timeText');
    }

    // 无法解析，返回当前时间
    return now.millisecondsSinceEpoch ~/ 1000;
  }
}
