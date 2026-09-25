class Law {
  final int id;
  final String name;
  final String? shortName;
  final String? category;
  final int orderNum;
  final int articlesCount;

  const Law({
    required this.id,
    required this.name,
    this.shortName,
    this.category,
    required this.orderNum,
    required this.articlesCount,
  });

  factory Law.fromMap(Map<String, dynamic> map) {
    return Law(
      id: map['id'] as int,
      name: map['name'] as String,
      shortName: map['short_name'] as String?,
      category: map['category'] as String?,
      orderNum: (map['order_num'] as int?) ?? 0,
      articlesCount: (map['articles_count'] as int?) ?? 0,
    );
  }
}
