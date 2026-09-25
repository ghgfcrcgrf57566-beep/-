import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/models/law.dart';
import '../../data/models/madda.dart';
import '../../data/repositories/laws_repository.dart';
import '../law_detail/law_detail_screen.dart';
import '../article/article_detail_screen.dart';
import '../search/search_screen.dart';
import 'widgets/law_card.dart';
import 'category_laws_screen.dart';

/// نقطة الدخول لقسم "القوانين اليمنية": يعرض عند الدخول (كما في المواصفات)
/// جميع القوانين، وتصنيفها حسب المجال، وصندوق بحث، وآخر المواد المقروءة.
class LawsHomeScreen extends StatefulWidget {
  const LawsHomeScreen({super.key});

  @override
  State<LawsHomeScreen> createState() => _LawsHomeScreenState();
}

class _LawsHomeScreenState extends State<LawsHomeScreen> {
  final _repo = LawsRepository.instance;

  List<Law> _laws = [];
  List<Map<String, dynamic>> _categories = [];
  List<Madda> _recentlyRead = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final laws = await _repo.getAllLaws();
    final categories = await _repo.getCategories();
    final recent = await _repo.getRecentlyRead(limit: 10);
    setState(() {
      _laws = laws;
      _categories = categories;
      _recentlyRead = recent;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('القوانين اليمنية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'بحث',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  if (_categories.isNotEmpty) _CategoriesRow(categories: _categories),
                  if (_recentlyRead.isNotEmpty) _RecentlyReadRow(items: _recentlyRead),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      'جميع القوانين',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: context.textPrimary,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: _laws
                          .map((law) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: LawCard(
                                  law: law,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => LawDetailScreen(law: law)),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _CategoriesRow extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  const _CategoriesRow({required this.categories});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            'تصنيف القوانين',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: context.textPrimary),
          ),
        ),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = categories[index]['category'] as String;
              final count = categories[index]['count'] as int;
              return ActionChip(
                label: Text('$cat ($count)'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => CategoryLawsScreen(category: cat)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RecentlyReadRow extends StatelessWidget {
  final List<Madda> items;
  const _RecentlyReadRow({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'آخر ما قرأت',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: context.textPrimary),
          ),
        ),
        SizedBox(
          height: 78,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final m = items[index];
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ArticleDetailScreen(maddaId: m.id)),
                ),
                child: Container(
                  width: 190,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'مادة (${m.number})',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: context.accent),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        m.lawName ?? '',
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11.5, color: context.textSecondary),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
