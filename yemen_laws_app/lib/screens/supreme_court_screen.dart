import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kSupremeCourtIndexUrl =
    'https://raw.githubusercontent.com/ghgfcrcgrf57566-beep/-/main/sc_books.json';

const _gold = Color(0xFFD4AF37);
const _goldLight = Color(0xFFF0D78A);
const _goldDark = Color(0xFF8A671C);
const _bg = Color(0xFF121212);
const _surface = Color(0xFF1A1A1A);

class SupremeCourtScreen extends StatefulWidget {
  const SupremeCourtScreen({super.key});

  @override
  State<SupremeCourtScreen> createState() => _SupremeCourtScreenState();
}

class _SupremeCourtScreenState extends State<SupremeCourtScreen> {
  static const _cacheKey = 'cached_sc_books_json_v2';

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 60),
      responseType: ResponseType.plain,
    ),
  );

  final _search = TextEditingController();
  List<Map<String, dynamic>> _books = [];
  List<Map<String, dynamic>> _filtered = [];
  final Set<String> _downloaded = {};
  final Map<String, double> _progress = {};
  String _query = '';
  String _source = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadIndex();
  }

  @override
  void dispose() {
    _search.dispose();
    _dio.close(force: true);
    super.dispose();
  }

  List<Map<String, dynamic>> _parse(String raw) {
    try {
      final value = jsonDecode(raw);
      if (value is! List) return [];
      return value
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  int _part(Map<String, dynamic> book) {
    final match =
        RegExp(r'(\d+)').firstMatch('${book['id'] ?? ''}');
    return match == null ? 999 : int.tryParse(match.group(1)!) ?? 999;
  }

  String _partLabel(Map<String, dynamic> book) =>
      'الجزء ${_part(book).toString().padLeft(2, '0')}';

  void _applyBooks(List<Map<String, dynamic>> books) {
    books.sort((a, b) => _part(a).compareTo(_part(b)));
    if (!mounted) return;
    setState(() {
      _books = books;
      _filtered = _filter(_query);
    });
  }

  List<Map<String, dynamic>> _filter(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return List<Map<String, dynamic>>.from(_books);
    return _books.where((book) {
      final text = [
        book['id'],
        book['title'],
        book['subtitle'],
        book['description'],
        book['file_name'],
        _partLabel(book),
      ].map((e) => '$e').join(' ').toLowerCase();
      return text.contains(q);
    }).toList();
  }

  Future<void> _loadIndex() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);

    if (cached != null) {
      final parsed = _parse(cached);
      if (parsed.isNotEmpty) {
        _applyBooks(parsed);
        _source = 'نسخة محفوظة محليًا';
      }
    }

    try {
      final response = await _dio.get<String>(kSupremeCourtIndexUrl);
      if (response.statusCode == 200 && response.data != null) {
        final parsed = _parse(response.data!);
        if (parsed.isNotEmpty) {
          await prefs.setString(_cacheKey, jsonEncode(parsed));
          _applyBooks(parsed);
          _source = 'محدّث من GitHub';
        }
      }
    } catch (_) {}

    await _refreshDownloaded();
    if (mounted) setState(() => _loading = false);
  }

  Future<Directory> _booksDir() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}/supreme_court');
    await dir.create(recursive: true);
    return dir;
  }

  String _safeFileName(String name) {
    final clean = name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '_');
    return clean.toLowerCase().endsWith('.pdf')
        ? clean
        : '$clean.pdf';
  }

  Future<File> _localFile(Map<String, dynamic> book) async {
    final dir = await _booksDir();
    final name = _safeFileName(
      '${book['file_name'] ?? book['id'] ?? 'book.pdf'}',
    );
    return File('${dir.path}/$name');
  }

  Future<void> _refreshDownloaded() async {
    final found = <String>{};
    for (final book in _books) {
      final file = await _localFile(book);
      if (await file.exists()) {
        found.add(
          _safeFileName('${book['file_name'] ?? book['id']}'),
        );
      }
    }
    if (!mounted) return;
    setState(() {
      _downloaded
        ..clear()
        ..addAll(found);
    });
  }

  void _onSearch(String value) {
    setState(() {
      _query = value;
      _filtered = _filter(value);
    });
  }

  Future<void> _download(
    Map<String, dynamic> book,
    void Function(void Function()) sheetSetState,
    BuildContext sheetContext,
  ) async {
    final file = await _localFile(book);
    if (await file.exists()) {
      Navigator.pop(sheetContext);
      _openPdf(file.path, '${book['title'] ?? ''}');
      return;
    }

    final url = '${book['download_url'] ?? ''}'.trim();
    if (url.isEmpty) {
      _showMessage('لا يوجد رابط تنزيل لهذا الكتاب.');
      return;
    }

    final id = '${book['id'] ?? book['file_name']}';
    final temp = File('${file.path}.part');

    try {
      sheetSetState(() => _progress[id] = 0);
      await _dio.download(
        url,
        temp.path,
        deleteOnError: true,
        options: Options(followRedirects: true, maxRedirects: 5),
        onReceiveProgress: (received, total) {
          if (total <= 0) return;
          final value = received / total;
          sheetSetState(() => _progress[id] = value);
          if (mounted) setState(() => _progress[id] = value);
        },
      );

      if (!await temp.exists()) throw const FileSystemException('download_failed');
      if (await file.exists()) await file.delete();
      await temp.rename(file.path);

      _downloaded.add(
        _safeFileName('${book['file_name'] ?? book['id']}'),
      );
      if (!mounted) return;
      Navigator.pop(sheetContext);
      _openPdf(file.path, '${book['title'] ?? ''}');
    } catch (_) {
      if (await temp.exists()) await temp.delete();
      _showMessage('تعذر تنزيل الملف. تأكد من الاتصال بالإنترنت.');
    }
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, textAlign: TextAlign.right),
        backgroundColor: const Color(0xFF2A2113),
      ),
    );
  }

  void _openPdf(String path, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SupremeCourtPdfViewer(
          filePath: path,
          title: title,
        ),
      ),
    );
  }

  Future<void> _showBook(Map<String, dynamic> book) async {
    final file = await _localFile(book);
    final downloaded = await file.exists();
    if (!mounted) return;

    final id = '${book['id'] ?? book['file_name']}';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: StatefulBuilder(
            builder: (context, sheetSetState) {
              final progress = _progress[id] ?? 0;
              final downloading = progress > 0 && progress < 1;

              return Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                decoration: const BoxDecoration(
                  color: Color(0xFF1B1713),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border(top: BorderSide(color: _gold)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const _GoldBadge(icon: Icons.gavel_rounded),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${book['title'] ?? 'الكتاب'}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: Color(0xFFF2E6CE),
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _partLabel(book),
                      style: const TextStyle(
                        color: _gold,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${book['description'] ?? 'لا يوجد وصف متوفر.'}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Colors.white60,
                        height: 1.6,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (downloading) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 7,
                          backgroundColor: Colors.white12,
                          color: _gold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'جاري التنزيل: ${(progress * 100).toStringAsFixed(0)}%',
                          style:
                              const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ] else
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () => _download(
                            book,
                            sheetSetState,
                            sheetContext,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _gold,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: Icon(
                            downloaded
                                ? Icons.menu_book_rounded
                                : Icons.download_rounded,
                          ),
                          label: Text(
                            downloaded
                                ? 'قراءة الكتاب'
                                : 'تنزيل وقراءة PDF',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        title: const Text(
          'أحكام المحكمة العليا',
          style: TextStyle(
            color: _goldLight,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: _gold),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: _onSearch,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'ابحث باسم الكتاب أو رقم الجزء أو الوصف...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon:
                    const Icon(Icons.search_rounded, color: _gold),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _search.clear();
                          _onSearch('');
                        },
                        icon: const Icon(
                          Icons.clear_rounded,
                          color: Colors.white54,
                        ),
                      ),
                filled: true,
                fillColor: _surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      const BorderSide(color: Colors.white10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      const BorderSide(color: Colors.white10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _gold),
                ),
              ),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 3),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_filtered.length} من أصل ${_books.length} كتاب',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  _source,
                  style:
                      const TextStyle(color: _gold, fontSize: 11.5),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: _gold),
                  )
                : _filtered.isEmpty
                    ? const _EmptyState()
                    : RefreshIndicator(
                        color: _gold,
                        onRefresh: _loadIndex,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                            16,
                            8,
                            16,
                            24,
                          ),
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            final book = _filtered[index];
                            final key = _safeFileName(
                              '${book['file_name'] ?? book['id']}',
                            );
                            return Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 10),
                              child: _BookCard(
                                book: book,
                                downloaded:
                                    _downloaded.contains(key),
                                partLabel: _partLabel(book),
                                onTap: () => _showBook(book),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final Map<String, dynamic> book;
  final bool downloaded;
  final String partLabel;
  final VoidCallback onTap;

  const _BookCard({
    required this.book,
    required this.downloaded,
    required this.partLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color:
              downloaded ? _gold.withValues(alpha: 0.55) : Colors.white10,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const _GoldBadge(icon: Icons.picture_as_pdf_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${book['title'] ?? 'الكتاب'}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      partLabel,
                      style: const TextStyle(
                        color: _gold,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                    Text(
                      '${book['subtitle'] ?? ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                downloaded
                    ? Icons.check_circle_rounded
                    : Icons.download_for_offline_outlined,
                color:
                    downloaded ? _goldLight : Colors.white38,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoldBadge extends StatelessWidget {
  final IconData icon;

  const _GoldBadge({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: const LinearGradient(
          colors: [_goldLight, _goldDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(icon, color: Colors.black87, size: 28),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, color: _gold, size: 54),
          SizedBox(height: 12),
          Text(
            'لا توجد نتائج مطابقة',
            style:
                TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class SupremeCourtPdfViewer extends StatelessWidget {
  final String filePath;
  final String title;

  const SupremeCourtPdfViewer({
    super.key,
    required this.filePath,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        title: Text(
          title,
          overflow: TextOverflow.ellipsis,
          style:
              const TextStyle(color: Colors.white, fontSize: 15),
        ),
        iconTheme: const IconThemeData(color: _gold),
      ),
      body: PDFView(
        filePath: filePath,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
        backgroundColor: _bg,
      ),
    );
  }
}
