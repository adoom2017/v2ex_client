class GroupNode {
  final String key;
  final String name;
  final List<String> nodes;
  final String? nodesTitle;

  const GroupNode({
    required this.key,
    required this.name,
    required this.nodes,
    this.nodesTitle,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupNode &&
          runtimeType == other.runtimeType &&
          key == other.key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'GroupNode(key: $key, name: $name)';
}

// 节点类型常量
class NodeTypes {
  static const String nodesMy = "my_nodes";
  static const String latestNode = "latest";
  static const String hotNode = "hot";
  static const String myNodesTitle =
      "分享发现 · 分享创造 · 问与答 · 酷工作 · 程序员 · 职场话题 · Solana · 投资 · 奇思妙想 · 硬件 · 游戏开发";
}

// 我的节点列表
final List<String> myNodeKeys = [
  "share",
  "create",
  "qna",
  "jobs",
  "programmer",
  "career",
  "solana",
  "invest",
  "ideas",
  "hardware",
  "gamedev",
];

// 官方节点分组
final List<GroupNode> officialNodes = [
  GroupNode(
    key: "tech",
    name: "技术",
    nodes: [
      "programmer",
      "python",
      "idev",
      "android",
      "linux",
      "nodejs",
      "cloud",
      "bb",
    ],
    nodesTitle: "程序员 · Python · iDev · Android · Linux · Node.js · 云计算 · 宽带症候群",
  ),
  GroupNode(
    key: "creative",
    name: "创意",
    nodes: [
      "create",
      "design",
      "ideas",
    ],
    nodesTitle: "分享创造 · 设计 · 奇思妙想",
  ),
  GroupNode(
    key: "play",
    name: "好玩",
    nodes: [
      "share",
      "crypto",
      "games",
      "movie",
      "tv",
      "music",
      "travel",
      "android",
      "afterdark",
    ],
    nodesTitle: "分享发现 · 加密货币 · 游戏 · 电影 · 剧集 · 音乐 · 旅行 · Android · 天黑以后",
  ),
  GroupNode(
    key: "apple",
    name: "Apple",
    nodes: [
      "macos",
      "iphone",
      "ipad",
      "macmini",
      "mbp",
      "imac",
      "watch",
      "apple",
    ],
    nodesTitle:
        "macOS · iPhone · iPad · Mac mini · MacBook Pro · iMac ·  WATCH · Apple",
  ),
  GroupNode(
    key: "jobs",
    name: "酷工作",
    nodes: [
      "jobs",
      "cv",
      "career",
      "meet",
      "outsourcing",
    ],
    nodesTitle: "酷工作 · 求职 · 职场话题 · 创业组队 · 外包",
  ),
  GroupNode(
    key: "deals",
    name: "交易",
    nodes: [
      "all4all",
      "exchange",
      "free",
      "dn",
      "tuan",
    ],
    nodesTitle: "二手交易 · 物物交换 · 免费赠送 · 域名 · 团购",
  ),
  GroupNode(
    key: "city",
    name: "城市",
    nodes: [
      "beijing",
      "shanghai",
      "shenzhen",
      "guangzhou",
      "hangzhou",
      "chengdu",
      "singapore",
      "nyc",
      "la",
    ],
    nodesTitle:
        "北京 · 上海 · 深圳 · 广州 · 杭州 · 成都 · Singapore · New York · Los Angeles",
  ),
  GroupNode(
    key: "qna",
    name: "问与答",
    nodes: [
      "qna",
    ],
    nodesTitle: "问与答",
  ),
  GroupNode(
    key: NodeTypes.hotNode,
    name: "最热",
    nodes: [
      NodeTypes.hotNode,
    ],
    nodesTitle: "hot",
  ),
  GroupNode(
    key: NodeTypes.latestNode,
    name: "最新",
    nodes: [
      NodeTypes.latestNode,
    ],
    nodesTitle: "latest",
  ),
  GroupNode(
    key: NodeTypes.nodesMy,
    name: "*我的*",
    nodes: myNodeKeys,
    nodesTitle: NodeTypes.myNodesTitle,
  ),
  GroupNode(
    key: "r2",
    name: "R2",
    nodes: [
      "share",
      "create",
      "qna",
      "jobs",
      "programmer",
      "career",
      "invest",
      "ideas",
      "hardware",
    ],
    nodesTitle: "分享发现 · 分享创造 · 问与答 · 酷工作 · 程序员 · 职场话题 · 投资 · 奇思妙想 · 硬件",
  ),
  GroupNode(
    key: "vxna",
    name: "VXNA",
    nodes: [
      "vxna",
      "rss",
      "planet",
      "blogger",
      "webmaster",
    ],
    nodesTitle: "VXNA · RSS · Planet · Blogger · 站长",
  ),
];

// 根据key查找GroupNode的工具函数
GroupNode? findGroupNodeByKey(String key) {
  return officialNodes.where((node) => node.key == key).firstOrNull;
}
