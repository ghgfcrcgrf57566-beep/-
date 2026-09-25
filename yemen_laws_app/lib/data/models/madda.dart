/// يمثل "مادة" قانونية واحدة (وحدة المحتوى الأساسية في التطبيق).
class Madda {
  final int id;
  final int lawId;
  final int? faslId;
  final int? babId;
  final String number;
  final String body;
  final int orderNum;

  // حقول إضافية تُملأ عند الحاجة لعرض السياق (اسم القانون / الباب / الفصل)
  final String? lawName;
  final String? babLabel;
  final String? faslLabel;

  const Madda({
    required this.id,
    required this.lawId,
    this.faslId,
    this.babId,
    required this.number,
    required this.body,
    required this.orderNum,
    this.lawName,
    this.babLabel,
    this.faslLabel,
  });

  String get title => 'مادة ($number)';

  /// النص الكامل الجاهز للنسخ أو المشاركة، مع الإشارة إلى مصدره.
  String get shareText {
    final buffer = StringBuffer();
    buffer.writeln('مادة ($number)');
    buffer.writeln(body);
    if (lawName != null) {
      buffer.writeln();
      buffer.write('المصدر: $lawName');
      if (babLabel != null) buffer.write(' - $babLabel');
      if (faslLabel != null) buffer.write(' - $faslLabel');
    }
    return buffer.toString();
  }

  factory Madda.fromMap(Map<String, dynamic> map) {
    return Madda(
      id: map['id'] as int,
      lawId: map['law_id'] as int,
      faslId: map['fasl_id'] as int?,
      babId: map['bab_id'] as int?,
      number: map['number'] as String? ?? '',
      body: map['body'] as String? ?? '',
      orderNum: (map['order_num'] as int?) ?? 0,
      lawName: map['law_name'] as String?,
      babLabel: map['bab_label'] as String?,
      faslLabel: map['fasl_label'] as String?,
    );
  }
}
