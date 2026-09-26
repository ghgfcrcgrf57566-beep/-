import 'dart:convert';
import 'package:http/http.dart' as http;

class LegalAiSource {
  final int articleId;
  final String lawName;
  final String articleNumber;
  final String articleText;
  final String? chapter;
  final double? score;
  const LegalAiSource({required this.articleId, required this.lawName, required this.articleNumber, required this.articleText, this.chapter, this.score});
  factory LegalAiSource.fromJson(Map<String, dynamic> j) => LegalAiSource(
    articleId: (j['article_id'] as num?)?.toInt() ?? 0,
    lawName: (j['law_name'] ?? '').toString(),
    articleNumber: (j['article_number'] ?? '').toString(),
    articleText: (j['article_text'] ?? '').toString(),
    chapter: j['chapter']?.toString(),
    score: (j['score'] as num?)?.toDouble(),
  );
}
class LegalAiResult {
  final String answer;
  final List<LegalAiSource> sources;
  const LegalAiResult({required this.answer, required this.sources});
}
class LegalAiService {
  LegalAiService._();
  static final instance = LegalAiService._();
  static const baseUrl = String.fromEnvironment('LEGAL_AI_BASE_URL', defaultValue: 'https://yemen-laws-ai.example.workers.dev');

  Future<LegalAiResult> ask({required String question, String? conversationId, List<Map<String,String>> history = const []}) async {
    final q = question.trim();
    if (q.isEmpty) throw const LegalAiException('يرجى كتابة السؤال أولاً.');
    if (q.length > 1200) throw const LegalAiException('السؤال طويل جداً. اختصره إلى 1200 حرف كحد أقصى.');
    try {
      final r = await http.post(Uri.parse('$baseUrl/api/legal/ask'),
        headers: {'Content-Type':'application/json','Accept':'application/json','X-App-Version':'1.0.0'},
        body: jsonEncode({'question':q, if (conversationId != null) 'conversation_id':conversationId, if (history.isNotEmpty) 'history':history}),
      ).timeout(const Duration(seconds:45));
      Map<String,dynamic> body={};
      try { body=jsonDecode(r.body) as Map<String,dynamic>; } catch (_) {}
      if (r.statusCode != 200) throw LegalAiException((body['error'] ?? _status(r.statusCode)).toString());
      return LegalAiResult(
        answer:(body['answer'] ?? '').toString(),
        sources:((body['sources'] as List?) ?? const []).whereType<Map>().map((e)=>LegalAiSource.fromJson(Map<String,dynamic>.from(e))).toList(),
      );
    } on LegalAiException { rethrow; } catch (_) {
      throw const LegalAiException('تعذر الاتصال بخدمة المساعد. تحقق من اتصال الإنترنت وحاول مرة أخرى.');
    }
  }
  String _status(int s) => s==429 ? 'تم تجاوز حد الاستخدام مؤقتاً. حاول لاحقاً.' : s>=500 ? 'خادم المساعد غير متاح حالياً.' : 'حدث خطأ أثناء معالجة السؤال.';
}
class LegalAiException implements Exception {
  final String message;
  const LegalAiException(this.message);
  @override String toString()=>message;
}
