import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:v2ex_client/src/models/group_node.dart';
import 'package:v2ex_client/src/screens/home_screen.dart';
import 'package:v2ex_client/src/services/log_service.dart';

/// iOS 风格的节点选择侧边抽屉
class NodeSelectorDrawer extends ConsumerWidget {
  const NodeSelectorDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedNode = ref.watch(selectedNodeProvider);

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        color: CupertinoColors.black.withValues(alpha: 0.0),
        child: Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {}, // 阻止点击抽屉本身时关闭
            child: Container(
              width: 280,
              height: double.infinity,
              decoration: const BoxDecoration(
                color: CupertinoColors.systemBackground,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题栏
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: CupertinoColors.separator,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '选择节点',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: CupertinoColors.label,
                            ),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => Navigator.of(context).pop(),
                            minimumSize: Size(32, 32),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemGrey6,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                CupertinoIcons.xmark,
                                size: 16,
                                color: CupertinoColors.secondaryLabel,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 节点列表
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: officialNodes.length,
                        separatorBuilder: (context, index) => Container(
                          height: 0.5,
                          color: CupertinoColors.separator,
                          margin: const EdgeInsets.only(left: 56),
                        ),
                        itemBuilder: (context, index) {
                          final groupNode = officialNodes[index];
                          final isSelected = groupNode.key == selectedNode;

                          return CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              LogService.userAction(
                                'Node changed',
                                {'from': selectedNode, 'to': groupNode.key},
                              );
                              ref.read(selectedNodeProvider.notifier).state =
                                  groupNode.key;
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  // 图标
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? CupertinoColors.systemBlue
                                              .withValues(alpha: 0.15)
                                          : CupertinoColors.systemGrey6,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _getNodeIcon(groupNode.key),
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: isSelected
                                              ? CupertinoColors.systemBlue
                                              : CupertinoColors.secondaryLabel,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // 节点名称
                                  Expanded(
                                    child: Text(
                                      groupNode.name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                        color: isSelected
                                            ? CupertinoColors.systemBlue
                                            : CupertinoColors.label,
                                      ),
                                    ),
                                  ),
                                  // 选中标记
                                  if (isSelected)
                                    const Icon(
                                      CupertinoIcons.checkmark_alt,
                                      size: 20,
                                      color: CupertinoColors.systemBlue,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 根据节点 key 返回对应的图标
  String _getNodeIcon(String key) {
    switch (key) {
      case 'latest':
        return '🆕';
      case 'hot':
        return '🔥';
      case 'tech':
        return '💻';
      case 'creative':
        return '🎨';
      case 'play':
        return '🎮';
      case 'apple':
        return '🍎';
      case 'jobs':
        return '💼';
      case 'deals':
        return '💰';
      case 'city':
        return '🏙️';
      case 'qna':
        return '❓';
      case 'programmer':
        return '👨‍💻';
      default:
        return '📌';
    }
  }
}

/// 显示节点选择抽屉的辅助方法
void showNodeSelectorDrawer(BuildContext context) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: true,
      barrierColor: CupertinoColors.black.withValues(alpha: 0.0),
      pageBuilder: (context, animation, secondaryAnimation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
          ),
          child: const NodeSelectorDrawer(),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
    ),
  );
}
