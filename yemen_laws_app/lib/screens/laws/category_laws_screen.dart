import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/models/law.dart';
import '../../data/repositories/laws_repository.dart';
import '../law_detail/law_detail_screen.dart';
import 'widgets/law_card.dart';

class CategoryLawsScreen extends StatefulWidget {
  final String category;
  const CategoryLawsScreen({super.key, required this.category});

  @override
  State<CategoryLawsScreen> createState() => _CategoryLawsScreenState();
}

class _CategoryLawsScreenState extends State<CategoryLawsScreen> {
  final _repo = LawsRepository.instance;
  final _searchController = TextEditingController();

  List<Law> _all = [];
  List<Law> _filtered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(_applyFilter);
  }

  Future<void> _load() async {
    final laws = await _repo.getLawsByCategory(widget.category);
    setState(() {
      _all = laws;
      _filtered = laws;
      _loading = false;
    });
  }

  void _applyFilter() {
    final q = _searchController.text.trim();
    setState(() {
      _filtered = q.isEmpty ? _all : _all.where((l) => l.name.contains(q)).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('تصنيف: ${widget.category}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                      hintText: 'ابحث داخل هذا التصنيف...',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${_filtered.length} من ${_all.length} قانون',
                      style: TextStyle(color: context.textSecondary, fontSize: 12.5),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final law = _filtered[index];
                      return LawCard(
                        law: law,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => LawDetailScreen(law: law)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
