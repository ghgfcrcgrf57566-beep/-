import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/favorites_provider.dart';
import '../law_detail/widgets/section_tile.dart';
import '../article/article_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoritesProvider>().ensureLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>();
    final items = favorites.favorites;

    return Scaffold(
      appBar: AppBar(title: const Text('المفضلة')),
      body: RefreshIndicator(
        onRefresh: favorites.refresh,
        child: items.isEmpty
            ? ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bookmark_border, size: 56, color: context.textSecondary.withOpacity(0.5)),
                          const SizedBox(height: 12),
                          Text('لا توجد مواد مفضلة بعد', style: TextStyle(color: context.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final m = items[index];
                  return SectionTile(
                    icon: Icons.bookmark,
                    title: 'مادة (${m.number}) — ${m.lawName ?? ''}',
                    subtitle: m.body,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ArticleDetailScreen(maddaId: m.id)),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
