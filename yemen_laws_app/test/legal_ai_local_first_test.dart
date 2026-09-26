import 'package:flutter_test/flutter_test.dart';
import 'package:yemen_law/data/models/madda.dart';
import 'package:yemen_law/services/chat_history_db.dart';
import 'package:yemen_law/services/legal_ai_service.dart';

void main() {
  test('parses legal assistant history entries', () {
    final entry = ChatHistoryEntry.fromMap({
      'id': 7,
      'query': 'ما شروط العقد؟',
      'response': 'المادة (10)...',
      'source': 'local_db',
      'created_at': '2026-09-26T20:00:00.000Z',
    });

    expect(entry.id, 7);
    expect(entry.query, 'ما شروط العقد؟');
    expect(entry.response, contains('المادة'));
    expect(entry.sourceLabel, 'قاعدة القوانين المحلية');
  });

  test('local legal source keeps article and law metadata', () {
    final source = LegalAiSource.fromMadda(
      const Madda(
        id: 11,
        lawId: 2,
        number: '15',
        body: 'نص المادة',
        orderNum: 15,
        lawName: 'القانون المدني',
        babLabel: 'العقود',
      ),
    );

    expect(source.articleId, 11);
    expect(source.lawName, 'القانون المدني');
    expect(source.articleNumber, '15');
    expect(source.reference, contains('القانون المدني'));
  });
}
