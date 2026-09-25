class ArticleNote {
  final int id;
  final int maddaId;
  final String noteText;
  final String updatedAt;

  const ArticleNote({
    required this.id,
    required this.maddaId,
    required this.noteText,
    required this.updatedAt,
  });

  factory ArticleNote.fromMap(Map<String, dynamic> map) {
    return ArticleNote(
      id: map['id'] as int,
      maddaId: map['mada_id'] as int,
      noteText: map['note_text'] as String? ?? '',
      updatedAt: map['updated_at'] as String? ?? '',
    );
  }
}
