import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:language_app/pages/add_phrases_page.dart';
import '../services/stats_service.dart';
import '../services/movie_phrases_service.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'phrase_info_page.dart';

class MoviePhrasesPage extends StatefulWidget {
  final List<Map<String, String>> moviePhrases;
  final Function()? onMoviePhraseAdded;
  const MoviePhrasesPage({
    super.key,
    required this.moviePhrases,
    this.onMoviePhraseAdded,
  });

  @override
  State<MoviePhrasesPage> createState() => _MoviePhrasesPageState();
}

class _MoviePhrasesPageState extends State<MoviePhrasesPage> {
  late FlutterTts flutterTts;
  TextEditingController searchController = TextEditingController();
  final ValueNotifier<List<Map<String, String>>> _filteredPhrasesNotifier =
      ValueNotifier<List<Map<String, String>>>([]);
  late List<Map<String, String>> _allPhrases;
  late Set<String> _favoritedPhrases;

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();
    flutterTts.setLanguage("en-US");
    flutterTts.setPitch(1.0);
    _loadData();
    _updateFilteredList();
    searchController.addListener(_updateFilteredList);
  }

  @override
  void didUpdateWidget(MoviePhrasesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.moviePhrases != oldWidget.moviePhrases) {
      _loadData();
      _updateFilteredList();
    }
  }

  void _loadData() {
    _allPhrases = MoviePhrasesService.getMoviePhrases();
    _favoritedPhrases = StatsService.getPhrases()
        .map((p) => p['phrase']!.toLowerCase())
        .toSet();
  }

  void _updateFilteredList() {
    final query = searchController.text.trim().toLowerCase();
    _filteredPhrasesNotifier.value = _allPhrases
        .where(
          (p) =>
              (p['phrase']!.toLowerCase().contains(query)) ||
              (p['movie']!.toLowerCase().contains(query)),
        )
        .toList();
  }

  @override
  void dispose() {
    searchController.removeListener(_updateFilteredList);
    searchController.dispose();
    _filteredPhrasesNotifier.dispose();
    super.dispose();
  }

  void _togglePhrase(Map<String, String> phrase) async {
    final phraseText = phrase['phrase']!;
    final meaningText = phrase['meaning']!;
    final movieText = phrase['movie']!;
    final isFavorited = _favoritedPhrases.contains(phraseText.toLowerCase());

    if (isFavorited) {
      // It's already a favorite, so remove it from the general Phrases list
      var generalPhrases = StatsService.getPhrases();
      generalPhrases.removeWhere(
        (p) => p['phrase'] == phraseText && p['meaning'] == meaningText,
      );
      StatsService.savePhrases(generalPhrases);

      // Also remove the extra info (movie title) from SharedPreferences
      final prefsKey = 'phraseinfo_${phraseText}_${meaningText}';
      await StatsService.prefs.remove(prefsKey);
    } else {
      // It's not a favorite, so add it to the general Phrases list
      StatsService.addPhrase(phraseText, meaningText);

      // Also save the movie title as extra info in SharedPreferences
      final prefsKey = 'phraseinfo_${phraseText}_${meaningText}';
      // format is [sentence, movie, imagePath]
      await StatsService.prefs.setStringList(prefsKey, ['', movieText, '']);
    }

    // Reload the favorited status and update the UI
    _loadData();
    _updateFilteredList();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFavorited
              ? '"$phraseText" removed from Phrases.'
              : '"$phraseText" added to Phrases!',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void speak(String text) async {
    await flutterTts.stop();
    await flutterTts.speak(text);
  }

  void _showAddMoviePhraseDialog() {
    final phraseController = TextEditingController();
    final meaningController = TextEditingController();
    final movieController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 8,
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Add New Movie Phrase',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: phraseController,
                          autofocus: true,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.short_text),
                            labelText: 'Phrase',
                            border: OutlineInputBorder(),
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (val) =>
                              (val == null || val.trim().isEmpty)
                              ? 'Please enter a phrase'
                              : null,
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: meaningController,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.translate),
                            labelText: 'Meaning',
                            border: OutlineInputBorder(),
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (val) =>
                              (val == null || val.trim().isEmpty)
                              ? 'Please enter a meaning'
                              : null,
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: movieController,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.movie),
                            labelText: 'Movie (e.g., Star Wars (1977))',
                            border: OutlineInputBorder(),
                          ),
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submitAddMoviePhrase(
                            formKey,
                            phraseController,
                            meaningController,
                            movieController,
                            setState,
                          ),
                          validator: (val) =>
                              (val == null || val.trim().isEmpty)
                              ? 'Please enter a movie'
                              : null,
                        ),
                        const SizedBox(height: 28),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF9C27B0),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: () => _submitAddMoviePhrase(
                            formKey,
                            phraseController,
                            meaningController,
                            movieController,
                            setState,
                          ),
                          child: const Text('Add'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _submitAddMoviePhrase(
    GlobalKey<FormState> formKey,
    TextEditingController phraseController,
    TextEditingController meaningController,
    TextEditingController movieController,
    void Function(void Function()) setState,
  ) {
    if (formKey.currentState?.validate() ?? false) {
      final phrase = phraseController.text.trim();
      final meaning = meaningController.text.trim();
      final movie = movieController.text.trim();
      MoviePhrasesService.addMoviePhrase(phrase, meaning, movie);
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Movie phrase added!')));
      _loadData();
      _updateFilteredList();
    } else {
      setState(() {}); // To show validation errors
    }
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
            backgroundColor: const Color(0xFF9C27B0),
            foregroundColor: Colors.white,
            centerTitle: true,
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: const Color(0xFF9C27B0),
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.light,
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Movie Phrases',
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
                    colors: [Color(0xFF9C27B0), Color(0xFFE040FB)],
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
                        hintText: 'Search movie phrases...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF9C27B0),
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
          ValueListenableBuilder<List<Map<String, String>>>(
            valueListenable: _filteredPhrasesNotifier,
            builder: (context, filteredPhrases, _) {
              if (filteredPhrases.isEmpty) {
                return SliverToBoxAdapter(
                  child: Container(
                    height: 300,
                    alignment: Alignment.center,
                    child: const Text(
                      'No phrases found.',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final phrase = filteredPhrases[index];
                    final isAdded = _favoritedPhrases.contains(
                      phrase['phrase']!.toLowerCase(),
                    );
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isAdded
                              ? const Color(0xFF9C27B0)
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        leading: Icon(
                          Icons.movie,
                          color: const Color(0xFF9C27B0),
                        ),
                        title: Text(
                          phrase['phrase']!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 17,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              phrase['meaning']!,
                              style: const TextStyle(fontSize: 15),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                phrase['movie']!,
                                style: TextStyle(
                                  color: Colors.purple.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.volume_up,
                                color: const Color(0xFF3B4FE0),
                              ),
                              onPressed: () => speak(phrase['phrase']!),
                            ),
                            IconButton(
                              icon: Icon(
                                isAdded
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: const Color(0xFF9C27B0),
                              ),
                              tooltip: isAdded
                                  ? 'Remove from Phrases'
                                  : 'Add to Phrases',
                              onPressed: () => _togglePhrase(phrase),
                            ),
                          ],
                        ),
                      ),
                    );
                  }, childCount: filteredPhrases.length),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF9C27B0),
        foregroundColor: Colors.white,
        mini: true,
        onPressed: _showAddMoviePhraseDialog,
        child: const Icon(Icons.add, size: 20),
        tooltip: 'Add New Movie Phrase',
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
