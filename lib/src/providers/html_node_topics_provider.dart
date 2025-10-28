import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:v2ex_client/src/api/api_client.dart';
import 'package:v2ex_client/src/models/topic.dart';
import 'package:v2ex_client/src/services/html_parser_service.dart';
import 'package:v2ex_client/src/services/log_service.dart';

/// HTML节点主题参数
class HtmlNodeTopicsParam {
  final String nodeKey;
  final int page;

  const HtmlNodeTopicsParam({
    required this.nodeKey,
    this.page = 1,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HtmlNodeTopicsParam &&
          runtimeType == other.runtimeType &&
          nodeKey == other.nodeKey &&
          page == other.page;

  @override
  int get hashCode => Object.hash(nodeKey, page);
}

/// 通用HTML节点主题Provider
/// 使用 https://www.v2ex.com/go/:nodekey?p=1 接口
/// 通过HTML解析获取主题列表
final htmlNodeTopicsProvider = FutureProvider.autoDispose
    .family<List<Topic>, HtmlNodeTopicsParam>((ref, param) async {
  try {
    LogService.info('Fetching HTML node topics', {
      'nodeKey': param.nodeKey,
      'page': param.page,
    });

    // 使用 ApiClient 获取 HTML
    final apiClient = ref.read(apiClientProvider);
    final htmlContent = await apiClient.getNodeTopicsHtml(
      param.nodeKey,
      p: param.page,
    );

    // 解析HTML
    final topics = HtmlParserService.parseTopicsNode(
      htmlContent,
      nodeKey: param.nodeKey,
    );

    LogService.info('Successfully fetched ${topics.length} topics from HTML', {
      'nodeKey': param.nodeKey,
      'page': param.page,
    });

    return topics;
  } catch (e, stackTrace) {
    LogService.error('Error fetching HTML node topics', e, stackTrace);
    rethrow;
  }
});
