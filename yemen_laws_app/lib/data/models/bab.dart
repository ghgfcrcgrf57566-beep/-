/// يمثل هذا الصنف عنصرًا من عناصر التقسيم الأعلى للقانون:
/// "كتاب" أو "قسم" أو "باب" (كلها مخزّنة في جدول abwab نفسه ومتداخلة عبر
/// parentBabId لدعم التسلسل الهرمي: كتاب -> قسم -> باب).
class Bab {
  final int id;
  final int lawId;
  final int? parentBabId;
  final String level; // 'كتاب' | 'قسم' | 'باب'
  final String label; // مثال: "الباب الأول"
  final String? title; // مثال: "أحكام عامة"
  final int orderNum;

  const Bab({
    required this.id,
    required this.lawId,
    this.parentBabId,
    required this.level,
    required this.label,
    this.title,
    required this.orderNum,
  });

  String get displayName => title == null || title!.isEmpty ? label : '$label: $title';

  factory Bab.fromMap(Map<String, dynamic> map) {
    return Bab(
      id: map['id'] as int,
      lawId: map['law_id'] as int,
      parentBabId: map['parent_bab_id'] as int?,
      level: map['level'] as String? ?? 'باب',
      label: map['label'] as String? ?? '',
      title: map['title'] as String?,
      orderNum: (map['order_num'] as int?) ?? 0,
    );
  }
}
