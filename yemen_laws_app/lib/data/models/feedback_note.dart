class FeedbackNote {
  final int id;
  final String body;
  final String createdAt;
  final bool sent;

  const FeedbackNote({
    required this.id,
    required this.body,
    required this.createdAt,
    required this.sent,
  });

  factory FeedbackNote.fromMap(Map<String, dynamic> map) {
    return FeedbackNote(
      id: map['id'] as int,
      body: map['body'] as String? ?? '',
      createdAt: map['created_at'] as String? ?? '',
      sent: (map['sent'] as int? ?? 0) == 1,
    );
  }
}
