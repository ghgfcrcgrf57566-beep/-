/// يمثل "فصلاً" داخل باب من أبواب القانون (المستوى الأدنى من التقسيم قبل المواد).
class Fasl {
  final int id;
  final int lawId;
  final int? babId;
  final String label; // مثال: "الفصل الأول"
  final String? title; // مثال: "التسمية والتعاريف"
  final int orderNum;

  const Fasl({
    required this.id,
    required this.lawId,
    this.babId,
    required this.label,
    this.title,
    required this.orderNum,
  });

  String get displayName => title == null || title!.isEmpty ? label : '$label: $title';

  factory Fasl.fromMap(Map<String, dynamic> map) {
    return Fasl(
      id: map['id'] as int,
      lawId: map['law_id'] as int,
      babId: map['bab_id'] as int?,
      label: map['label'] as String? ?? '',
      title: map['title'] as String?,
      orderNum: (map['order_num'] as int?) ?? 0,
    );
  }
}
