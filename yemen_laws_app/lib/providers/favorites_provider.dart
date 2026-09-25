import 'package:flutter/foundation.dart';
import '../data/models/madda.dart';
import '../data/repositories/laws_repository.dart';

/// يدير حالة المفضلة عبر التطبيق ويُنبّه الواجهات عند أي تغيير
/// (إضافة/إزالة مادة) حتى تتحدث الأيقونات والقوائم فورًا.
class FavoritesProvider extends ChangeNotifier {
  final LawsRepository _repo = LawsRepository.instance;

  final Set<int> _favoriteIds = {};
  List<Madda> _favorites = [];
  bool _loaded = false;

  List<Madda> get favorites => _favorites;
  bool isFavorite(int maddaId) => _favoriteIds.contains(maddaId);

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    await refresh();
  }

  Future<void> refresh() async {
    _favorites = await _repo.getFavorites();
    _favoriteIds
      ..clear()
      ..addAll(_favorites.map((m) => m.id));
    _loaded = true;
    notifyListeners();
  }

  Future<void> toggle(Madda madda) async {
    if (_favoriteIds.contains(madda.id)) {
      await _repo.removeFavorite(madda.id);
    } else {
      await _repo.addFavorite(madda.id);
    }
    await refresh();
  }
}
