import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme.dart';
import '../../data/models/madda.dart';
import '../../data/models/article_note.dart';
import '../../data/repositories/laws_repository.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/settings_provider.dart';

class ArticleDetailScreen extends StatefulWidget {
  final int maddaId;
  /// قائمة معرّفات المواد المجاورة (لتفعيل الانتقال للمادة السابقة/التالية).
  /// إن لم تُمرَّر، لا تظهر أزرار التنقل.
  final List<int>? siblingIds;

  const ArticleDetailScreen({super.key, required this.maddaId, this.siblingIds});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  final _repo = LawsRepository.instance;
  Madda? _madda;
  ArticleNote? _note;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final madda = await _repo.getMaddaById(widget.maddaId);
    final note = await _repo.getArticleNote(widget.maddaId);
    if (!mounted) return;
    setState(() {
      _madda = madda;
      _note = note;
      _loading = false;
    });
    await context.read<FavoritesProvider>().ensureLoaded();
    // تسجيل هذه المادة في سجل "آخر ما قرأت"
    unawaited(_repo.recordReading(widget.maddaId));
  }

  void _copy() {
    final madda = _madda;
    if (madda == null) return;
    Clipboard.setData(ClipboardData(text: madda.shareText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ نص المادة')),
    );
  }

  void _share() {
    final madda = _madda;
    if (madda == null) return;
    Share.share(madda.shareText);
  }

  Future<void> _goToSibling(int offset) async {
    final ids = widget.siblingIds;
    final madda = _madda;
    if (ids == null || madda == null) return;
    final index = ids.indexOf(madda.id);
    if (index == -1) return;
    final newIndex = index + offset;
    if (newIndex < 0 || newIndex >= ids.length) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ArticleDetailScreen(maddaId: ids[newIndex], siblingIds: ids),
      ),
    );
  }

  Future<void> _editNote() async {
    final controller = TextEditingController(text: _note?.noteText ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ملاحظة شخصية على هذه المادة'),
        content: TextField(
          controller: controller,
          textAlign: TextAlign.right,
          maxLines: 5,
          decoration: const InputDecoration(hintText: 'اكتب ملاحظتك هنا...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (result == null) return;
    await _repo.saveArticleNote(widget.maddaId, result);
    final note = await _repo.getArticleNote(widget.maddaId);
    if (!mounted) return;
    setState(() => _note = note);
  }

  @override
  Widget build(BuildContext context) {
    final madda = _madda;
    final favorites = context.watch<FavoritesProvider>();
    final settings = context.watch<SettingsProvider>();
    final isFav = madda != null && favorites.isFavorite(madda.id);

    final ids = widget.siblingIds;
    final canNavigate = ids != null && madda != null && ids.contains(madda.id);
    final currentIndex = canNavigate ? ids.indexOf(madda.id) : -1;
    final hasPrev = canNavigate && currentIndex > 0;
    final hasNext = canNavigate && currentIndex < ids.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(madda == null ? '' : 'مادة (${madda.number})'),
        actions: madda == null
            ? null
            : [
                IconButton(
                  icon: Icon(isFav ? Icons.bookmark : Icons.bookmark_outline),
                  tooltip: 'إضافة للمفضلة',
                  onPressed: () => context.read<FavoritesProvider>().toggle(madda),
                ),
                IconButton(
                  icon: Icon(_note != null ? Icons.sticky_note_2 : Icons.note_add_outlined),
                  tooltip: 'ملاحظة شخصية',
                  onPressed: _editNote,
                ),
                IconButton(icon: const Icon(Icons.copy_outlined), tooltip: 'نسخ', onPressed: _copy),
                IconButton(icon: const Icon(Icons.share_outlined), tooltip: 'مشاركة', onPressed: _share),
              ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : madda == null
              ? const Center(child: Text('تعذر إيجاد المادة'))
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Breadcrumb(madda: madda),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: context.surfaceAlt,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: context.divider),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'مادة (${madda.number})',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 17 * settings.fontScale,
                                      color: context.accent,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SelectableText(
                                    madda.body,
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: 16.5 * settings.fontScale,
                                      height: 1.9,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_note != null) ...[
                              const SizedBox(height: 14),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: context.accent.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: context.accent.withOpacity(0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.sticky_note_2_outlined, size: 16, color: context.accent),
                                        const SizedBox(width: 6),
                                        Text('ملاحظتي', style: TextStyle(fontWeight: FontWeight.w700, color: context.accent, fontSize: 12.5)),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _note!.noteText,
                                      textAlign: TextAlign.right,
                                      style: TextStyle(color: context.textPrimary, fontSize: 13.5),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    _BottomToolbar(
                      settings: settings,
                      hasPrev: hasPrev,
                      hasNext: hasNext,
                      showNav: canNavigate,
                      onPrev: () => _goToSibling(-1),
                      onNext: () => _goToSibling(1),
                    ),
                  ],
                ),
    );
  }
}

class _BottomToolbar extends StatelessWidget {
  final SettingsProvider settings;
  final bool hasPrev;
  final bool hasNext;
  final bool showNav;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _BottomToolbar({
    required this.settings,
    required this.hasPrev,
    required this.hasNext,
    required this.showNav,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.surfaceAlt,
        border: Border(top: BorderSide(color: context.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (showNav)
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'المادة السابقة',
                onPressed: hasPrev ? onPrev : null,
              )
            else
              const SizedBox(width: 48),
            Row(
              children: [
                IconButton(
                  icon: const Text('A-', style: TextStyle(fontWeight: FontWeight.bold)),
                  tooltip: 'تصغير الخط',
                  onPressed: () => context.read<SettingsProvider>().decreaseFontScale(),
                ),
                Text('${(settings.fontScale * 100).round()}%', style: TextStyle(color: context.textSecondary, fontSize: 12)),
                IconButton(
                  icon: const Text('A+', style: TextStyle(fontWeight: FontWeight.bold)),
                  tooltip: 'تكبير الخط',
                  onPressed: () => context.read<SettingsProvider>().increaseFontScale(),
                ),
              ],
            ),
            if (showNav)
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'المادة التالية',
                onPressed: hasNext ? onNext : null,
              )
            else
              const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  final Madda madda;
  const _Breadcrumb({required this.madda});

  @override
  Widget build(BuildContext context) {
    final parts = [madda.lawName, madda.babLabel, madda.faslLabel]
        .where((e) => e != null && e.isNotEmpty)
        .toList();
    return Text(
      parts.join(' • '),
      textAlign: TextAlign.right,
      style: TextStyle(color: context.textSecondary, fontSize: 12.5),
    );
  }
}
