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
              width: 300,
              height: double.infinity,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGroupedBackground,
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(-5, 0),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // 标题栏
                    Container(
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 16,
                        top: 20,
                        bottom: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '选择节点',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: CupertinoColors.label,
                              letterSpacing: -0.5,
                            ),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: CupertinoColors.tertiarySystemFill,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(
                                CupertinoIcons.xmark,
                                size: 18,
                                color: CupertinoColors.secondaryLabel,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 节点列表
                    Expanded(
                      child: CupertinoScrollbar(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: officialNodes.length,
                          itemBuilder: (context, index) {
                            final groupNode = officialNodes[index];
                            final isSelected = groupNode.key == selectedNode;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  LogService.userAction(
                                    'Node changed',
                                    {'from': selectedNode, 'to': groupNode.key},
                                  );
                                  ref
                                      .read(selectedNodeProvider.notifier)
                                      .state = groupNode.key;
                                  Navigator.of(context).pop();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? CupertinoColors.systemBlue
                                        : CupertinoColors.systemBackground,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      if (!isSelected)
                                        BoxShadow(
                                          color: CupertinoColors.black
                                              .withValues(alpha: 0.03),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      // 图标
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? CupertinoColors.white
                                                  .withValues(alpha: 0.25)
                                              : CupertinoColors.systemGrey6,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Center(
                                          child: Text(
                                            _getNodeIcon(groupNode.key),
                                            style:
                                                const TextStyle(fontSize: 20),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      // 节点名称
                                      Expanded(
                                        child: Text(
                                          groupNode.name,
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                            color: isSelected
                                                ? CupertinoColors.white
                                                : CupertinoColors.label,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                      ),
                                      // 选中标记
                                      if (isSelected)
                                        const Icon(
                                          CupertinoIcons
                                              .checkmark_alt_circle_fill,
                                          size: 22,
                                          color: CupertinoColors.white,
                                        )
                                      else
                                        const Icon(
                                          CupertinoIcons.chevron_right,
                                          size: 18,
                                          color: CupertinoColors.tertiaryLabel,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
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
