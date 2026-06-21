import 'package:shared_preferences/shared_preferences.dart';

/// Stores last N Instagram URLs entered by the user.
class RecentLinksService {
  RecentLinksService._();
  static final RecentLinksService instance = RecentLinksService._();

  static const _key = 'recent_instagram_links';
  static const _max = 10;

  Future<List<String>> getLinks() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  Future<void> addLink(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_key) ?? [];
    final next = [url, ...current.where((u) => u != url)].take(_max).toList();
    await prefs.setStringList(_key, next);
  }
}
