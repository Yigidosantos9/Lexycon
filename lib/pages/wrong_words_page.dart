import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/word_lookup_service.dart';
import 'package:flutter/services.dart';
import '../services/stats_service.dart';

class WrongWordsPage extends StatefulWidget {
  final List<String> wrongWords;

  const WrongWordsPage({super.key, required this.wrongWords});

  @override
  State<WrongWordsPage> createState() => _WrongWordsPageState();
}

class _WrongWordsPageState extends State<WrongWordsPage> {
  late FlutterTts flutterTts;
  TextEditingController searchController = TextEditingController();
  late Set<String> _favoriteWordsSet;
  late List<String> _wrongWordsSorted;
  final ValueNotifier<List<String>> _filteredWordsNotifier =
      ValueNotifier<List<String>>([]);

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();
    flutterTts.setLanguage("en-US");
    flutterTts.setPitch(1.0);
    _loadAndSortData();
    _updateFilteredList();
    searchController.addListener(_updateFilteredList);
  }

  @override
  void didUpdateWidget(WrongWordsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.wrongWords != oldWidget.wrongWords) {
      _loadAndSortData();
      _updateFilteredList();
    }
  }

  void _loadAndSortData() {
    final favorites = StatsService.getFavorites();
    _favoriteWordsSet = favorites
        .map((f) => f['word']?.toString() ?? '')
        .toSet();
    final wrongs = List<String>.from(widget.wrongWords);
    wrongs.sort((a, b) {
      final aFav = _favoriteWordsSet.contains(a);
      final bFav = _favoriteWordsSet.contains(b);
      if (aFav && !bFav) return -1;
      if (!aFav && bFav) return 1;
      return a.compareTo(b);
    });
    _wrongWordsSorted = wrongs;
  }

  void _updateFilteredList() {
    final query = searchController.text.trim().toLowerCase();
    _filteredWordsNotifier.value = _wrongWordsSorted
        .where((w) => w.toLowerCase().contains(query))
        .toList();
  }

  void _toggleFavorite(String word) {
    final info = WordLookupService.getInfo(word);
    final isFav = _favoriteWordsSet.contains(word);
    if (isFav) {
      final manualList = StatsService.getManualFavorites();
      final quizList = StatsService.getQuizFavorites();
      manualList.removeWhere((f) => f['word'] == word);
      quizList.removeWhere((f) => f['word'] == word);
      StatsService.saveManualFavorites(manualList);
      StatsService.saveFavorites(quizList);
    } else {
      StatsService.addFavorite(word, info.meaning, manual: false);
    }
    // No setState! Reload data and update notifier.
    _loadAndSortData();
    _updateFilteredList();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFav
              ? '"$word" favorilerden çıkarıldı.'
              : '"$word" favorilere eklendi!',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    searchController.removeListener(_updateFilteredList);
    searchController.dispose();
    _filteredWordsNotifier.dispose();
    super.dispose();
  }

  void speak(String word) async {
    await flutterTts.stop();
    await flutterTts.speak(word);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 80.0,
            floating: true,
            pinned: false,
            snap: true,
            backgroundColor: const Color(0xFFFF5A5F),
            foregroundColor: Colors.white,
            centerTitle: true,
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: Color(0xFFFF5A5F),
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.light,
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Wrong Answers',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 16),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFF5A5F), Color(0xFFFF8A80)],
                  ),
                ),
              ),
            ),
          ),
          SliverPersistentHeader(
            delegate: _FilterHeaderDelegate(
              height: 80,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search wrong answers...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFFFF5A5F),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            pinned: true,
          ),
          ValueListenableBuilder<List<String>>(
            valueListenable: _filteredWordsNotifier,
            builder: (context, filteredWrongs, _) {
              if (filteredWrongs.isEmpty) {
                return SliverToBoxAdapter(
                  child: Container(
                    height: 300,
                    alignment: Alignment.center,
                    child: const Text(
                      'No wrong answers found.',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final word = filteredWrongs[index];
                    final meaning = WordLookupService.getInfo(word).meaning;
                    final isFav = _favoriteWordsSet.contains(word);
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      color: isFav ? const Color(0xFFFFE4EC) : Colors.white,
                      child: ListTile(
                        title: Text(
                          word,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isFav ? const Color(0xFFF94F8E) : null,
                          ),
                        ),
                        subtitle: Text('Meaning: $meaning'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.volume_up),
                              onPressed: () => speak(word),
                            ),
                            IconButton(
                              icon: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                color: isFav
                                    ? const Color(0xFFF94F8E)
                                    : const Color(0xFF3B4FE0),
                              ),
                              tooltip: isFav
                                  ? 'Remove from Favorites'
                                  : 'Add to Favorites',
                              onPressed: () => _toggleFavorite(word),
                            ),
                          ],
                        ),
                      ),
                    );
                  }, childCount: filteredWrongs.length),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _FilterHeaderDelegate({required this.child, required this.height});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: Colors.white,
      child: child,
      elevation: shrinkOffset > 0 ? 4 : 0,
    );
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
