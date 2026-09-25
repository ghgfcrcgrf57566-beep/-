import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/models/law.dart';
import '../../data/models/fasl.dart';
import '../../data/models/madda.dart';
import '../../data/repositories/laws_repository.dart';
import '../law_detail/widgets/section_tile.dart';
import 'article_detail_screen.dart';

class ArticleListScreen extends StatefulWidget {
  final Law law;
  final Fasl fasl;

  const ArticleListScreen({super.key, required this.law, required this.fasl});

  @override
  State<ArticleListScreen> createState() => _ArticleListScreenState();
}

class _ArticleListScreenState extends State<ArticleListScreen> {
  final _repo = LawsRepository.instance;
  List<Madda> _mawad = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final mawad = await _repo.getMawadByFasl(widget.fasl.id);
    setState(() {
      _mawad = mawad;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.fasl.displayName, maxLines: 2, overflow: TextOverflow.ellipsis)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _mawad.isEmpty
              ? Center(child: Text('لا توجد مواد', style: TextStyle(color: context.textSecondary)))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  itemCount: _mawad.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final m = _mawad[index];
                    return SectionTile(
                      icon: Icons.description_outlined,
                      title: 'مادة (${m.number})',
                      subtitle: m.body,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ArticleDetailScreen(
                            maddaId: m.id,
                            siblingIds: _mawad.map((e) => e.id).toList(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
