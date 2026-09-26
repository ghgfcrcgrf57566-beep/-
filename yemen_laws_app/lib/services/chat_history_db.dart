import 'package:sqflite/sqflite.dart';

import '../data/db_helper.dart';

class ChatHistoryEntry {
  final int id;
  final String query;
  final String response;
  final String source;
  final DateTime createdAt;

  const ChatHistoryEntry({
    required this.id,
    required this.query,
    required this.response,
    required this.source,
    required this.createdAt,
  });

  factory ChatHistoryEntry.fromMap(Map<String, dynamic> map) {
    final rawDate = (map['created_at'] ?? map['searched_at'] ?? '').toString();
    return ChatHistoryEntry(
      id: (map['id'] as num?)?.toInt() ?? 0,
      query: (map['query'] ?? '').toString(),
      response: (map['response'] ?? '').toString(),
      source: (map['source'] ?? 'local_db').toString(),
      createdAt:
          DateTime.tryParse(rawDate) ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  String get sourceLabel {
    switch (source) {
      case 'gemini_ai':
        return 'Gemini AI';
      case 'local_db':
        return 'قاعدة القوانين المحلية';
      default:
        return source;
    }
  }
}

class ChatHistoryDb {
  ChatHistoryDb._internal();

  static final ChatHistoryDb instance = ChatHistoryDb._internal();

  Future<Database> get _db async => DBHelper.instance.database;

  Future<void> ensureSchema() async {
    final db = await _db;

    await db.execute("""
      CREATE TABLE IF NOT EXISTS search_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        query TEXT NOT NULL,
        response TEXT,
        source TEXT NOT NULL DEFAULT 'local_db',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        searched_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    """);

    final columns = (await db.rawQuery('PRAGMA table_info(search_history)'))
        .map((row) => row['name']?.toString())
        .whereType<String>()
        .toSet();

    if (!columns.contains('response')) {
      await db.execute('ALTER TABLE search_history ADD COLUMN response TEXT');
    }
    if (!columns.contains('source')) {
      await db.execute(
        "ALTER TABLE search_history ADD COLUMN source TEXT NOT NULL DEFAULT 'local_db'",
      );
    }
    if (!columns.contains('created_at')) {
      await db.execute('ALTER TABLE search_history ADD COLUMN created_at TEXT');
    }

    if (columns.contains('searched_at')) {
      await db.execute("""
        UPDATE search_history
        SET created_at = COALESCE(created_at, searched_at, CURRENT_TIMESTAMP)
        WHERE created_at IS NULL OR TRIM(created_at) = ''
      """);
    } else {
      await db.execute("""
        UPDATE search_history
        SET created_at = COALESCE(created_at, CURRENT_TIMESTAMP)
        WHERE created_at IS NULL OR TRIM(created_at) = ''
      """);
    }
  }

  Future<int> addSearch({
    required String query,
    required String response,
    required String source,
  }) async {
    final value = query.trim();
    if (value.isEmpty) return 0;

    await ensureSchema();
    final db = await _db;
    final now = DateTime.now().toIso8601String();

    final id = await db.insert('search_history', {
      'query': value,
      'response': response.trim(),
      'source': source,
      'created_at': now,
      'searched_at': now,
    });

    await db.rawDelete("""
      DELETE FROM search_history
      WHERE id NOT IN (
        SELECT id FROM search_history
        ORDER BY COALESCE(created_at, searched_at) DESC
        LIMIT 100
      )
    """);

    return id;
  }

  Future<List<ChatHistoryEntry>> getHistory({int limit = 50}) async {
    await ensureSchema();
    final db = await _db;
    final safeLimit = limit.clamp(1, 100);

    final rows = await db.query(
      'search_history',
      orderBy: 'COALESCE(created_at, searched_at) DESC',
      limit: safeLimit,
    );

    return rows.map(ChatHistoryEntry.fromMap).toList();
  }
}
