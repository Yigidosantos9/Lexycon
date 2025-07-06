import 'package:flutter/material.dart';
import 'quiz_page.dart';
import 'favorites_page.dart';
import 'wrong_words_page.dart';
import 'phrases_page.dart';
import 'movie_phrases_page.dart';
import '../services/stats_service.dart';
import '../services/movie_phrases_service.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../services/question_service.dart';
import 'add_word_page.dart';
import 'add_phrases_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  int totalQuizzes = 0;
  int totalCorrect = 0;
  int totalWrong = 0;
  int totalWords = 0;

  // For tab content
  late List<Widget> _pages;
  late FavoritesPage _favoritesPage;
  late PhrasesPage _phrasesPage;
  late MoviePhrasesPage _moviePhrasesPage;
  late WrongWordsPage _wrongWordsPage;
  final GlobalKey<_HomeTabState> _homeTabKey = GlobalKey<_HomeTabState>();

  @override
  void initState() {
    super.initState();
    _loadStats();
    totalWords = QuestionService.wordOrder.length;
    _favoritesPage = FavoritesPage(favoriteWords: StatsService.getFavorites());
    _phrasesPage = PhrasesPage(phrases: StatsService.getPhrases());
    _moviePhrasesPage = MoviePhrasesPage(
      moviePhrases: MoviePhrasesService.getMoviePhrases(),
    );
    _wrongWordsPage = WrongWordsPage(
      wrongWords: StatsService.getWrongWords().toList(),
    );
    _pages = [
      _HomeTab(
        key: _homeTabKey,
        totalQuizzes: totalQuizzes,
        totalCorrect: totalCorrect,
        totalWrong: totalWrong,
        totalWords: totalWords,
        onShowAddWord: _showAddWordDialog,
        onShowAddPhrase: _showAddPhraseDialog,
        onShowAddMoviePhrase: _showAddMoviePhraseDialog,
        onQuizStatsRefresh: _loadStats,
        onRefreshRecentlyAdded: refreshRecentlyAdded,
      ),
      _favoritesPage,
      _phrasesPage,
      _moviePhrasesPage,
      _wrongWordsPage,
    ];
  }

  Future<void> _loadStats() async {
    final stats = await StatsService.getStats();
    setState(() {
      totalQuizzes = stats.total ?? 0;
      totalCorrect = stats.correct ?? 0;
      totalWrong = stats.wrong ?? 0;
      // Refresh HomeTab with new stats
      _pages[0] = _HomeTab(
        key: _homeTabKey,
        totalQuizzes: totalQuizzes,
        totalCorrect: totalCorrect,
        totalWrong: totalWrong,
        totalWords: totalWords,
        onShowAddWord: _showAddWordDialog,
        onShowAddPhrase: _showAddPhraseDialog,
        onShowAddMoviePhrase: _showAddMoviePhraseDialog,
        onQuizStatsRefresh: _loadStats,
        onRefreshRecentlyAdded: refreshRecentlyAdded,
      );
    });
  }

  void _onTabTapped(int index) async {
    if (index == 1) {
      _favoritesPage = FavoritesPage(
        favoriteWords: StatsService.getFavorites(),
      );
      _pages[1] = _favoritesPage;
    } else if (index == 2) {
      _phrasesPage = PhrasesPage(phrases: StatsService.getPhrases());
      _pages[2] = _phrasesPage;
    } else if (index == 3) {
      _moviePhrasesPage = MoviePhrasesPage(
        moviePhrases: MoviePhrasesService.getMoviePhrases(),
      );
      _pages[3] = _moviePhrasesPage;
    } else if (index == 4) {
      _wrongWordsPage = WrongWordsPage(
        wrongWords: StatsService.getWrongWords().toList(),
      );
      _pages[4] = _wrongWordsPage;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  void refreshRecentlyAdded() {
    _homeTabKey.currentState?.reloadRecent();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: _pages[_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        selectedItemColor: _selectedIndex == 0
            ? const Color(0xFF3B4FE0)
            : _selectedIndex == 1
            ? const Color(0xFFF94F8E)
            : _selectedIndex == 2
            ? const Color(0xFF8E54E9)
            : _selectedIndex == 3
            ? const Color(0xFF9C27B0)
            : const Color(0xFFFF5A5F),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.format_quote),
            label: 'Phrases',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.movie), label: 'Movies'),
          BottomNavigationBarItem(
            icon: Icon(Icons.error_outline),
            label: 'Wrongs',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? SpeedDial(
              icon: Icons.add,
              activeIcon: Icons.close,
              backgroundColor: const Color(0xFF3B4FE0),
              foregroundColor: Colors.white,
              overlayColor: Colors.black,
              overlayOpacity: 0.1,
              spacing: 12,
              spaceBetweenChildren: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              children: [
                SpeedDialChild(
                  child: const Icon(
                    Icons.text_fields,
                    color: Color(0xFF3B4FE0),
                  ),
                  backgroundColor: Colors.white,
                  label: 'Add New Word',
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                  onTap: _showAddWordDialog,
                ),
                SpeedDialChild(
                  child: const Icon(
                    Icons.format_quote,
                    color: Color(0xFF8E54E9),
                  ),
                  backgroundColor: Colors.white,
                  label: 'Add New Phrase',
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                  onTap: _showAddPhraseDialog,
                ),
                SpeedDialChild(
                  child: const Icon(Icons.movie, color: Color(0xFF9C27B0)),
                  backgroundColor: Colors.white,
                  label: 'Add Movie Phrase',
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                  onTap: _showAddMoviePhraseDialog,
                ),
              ],
            )
          : null,
    );
  }

  void _showAddWordDialog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddWordPage()),
    );
    if (result == true) {
      refreshRecentlyAdded();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Word added to favorites!')));
    }
  }

  void _showAddPhraseDialog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddPhrasesPage()),
    );
    if (result == true) {
      refreshRecentlyAdded();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Phrase added!')));
    }
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
              backgroundColor: const Color(0xFFF8F8FC),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                  minWidth: 0,
                  maxWidth: 400,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: Form(
                      key: formKey,
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3B4FE0),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Are you sure?'),
                                        content: const Text(
                                          'Quiz data (stats, wrongs, favorites) will be reset. Manually added words and phrases will be kept.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text('Reset'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await StatsService.resetQuizData();
                                      _loadStats();
                                      refreshRecentlyAdded();
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Quiz data reset!'),
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text('Reset Quiz Data'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF5A5F),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Are you sure?'),
                                        content: const Text(
                                          'All data will be reset, including manually added words and phrases.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text('Reset All'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await StatsService.resetAllData();
                                      _loadStats();
                                      refreshRecentlyAdded();
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('All data reset!'),
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text('Reset All Data'),
                                ),
                              ),
                            ],
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
      refreshRecentlyAdded();
    } else {
      setState(() {}); // To show validation errors
    }
  }
}

class _HomeTab extends StatefulWidget {
  final int totalQuizzes;
  final int totalCorrect;
  final int totalWrong;
  final int totalWords;
  final VoidCallback onShowAddWord;
  final VoidCallback onShowAddPhrase;
  final VoidCallback onShowAddMoviePhrase;
  final VoidCallback onQuizStatsRefresh;
  final VoidCallback onRefreshRecentlyAdded;

  const _HomeTab({
    required this.totalQuizzes,
    required this.totalCorrect,
    required this.totalWrong,
    required this.totalWords,
    required this.onShowAddWord,
    required this.onShowAddPhrase,
    required this.onShowAddMoviePhrase,
    required this.onQuizStatsRefresh,
    required this.onRefreshRecentlyAdded,
    Key? key,
  }) : super(key: key);

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  late Map<String, dynamic>? lastFavorite;
  late Map<String, String>? lastPhrase;
  late Map<String, String>? lastMoviePhrase;

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  void _loadRecent() {
    lastFavorite = StatsService.getFavorites().isNotEmpty
        ? StatsService.getFavorites().last
        : null;
    lastPhrase = StatsService.getPhrases().isNotEmpty
        ? StatsService.getPhrases().last
        : null;
    lastMoviePhrase = StatsService.getMoviePhrases().isNotEmpty
        ? StatsService.getMoviePhrases().last
        : null;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final statCards = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _StatCard(
          label: 'Total',
          value: '${widget.totalQuizzes}/10',
          color: Colors.blue.shade50,
          icon: Icons.bar_chart,
          iconColor: Colors.blue.shade300,
          valueColor: Colors.blue.shade700,
        ),
        _StatCard(
          label: 'Correct',
          value: widget.totalCorrect.toString(),
          color: Colors.green.shade50,
          icon: Icons.bar_chart,
          iconColor: Colors.green.shade300,
          valueColor: Colors.green.shade700,
        ),
        _StatCard(
          label: 'Wrong',
          value: widget.totalWrong.toString(),
          color: Colors.red.shade50,
          icon: Icons.bar_chart,
          iconColor: Colors.red.shade300,
          valueColor: Colors.red.shade700,
        ),
      ],
    );

    return Stack(
      children: [
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Area
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/lexy_logo.png',
                            height: 100,
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  "LEXY",
                                  style: TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2D3A7B),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  "Kelimelerin Lexy hali)",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  softWrap: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.settings_outlined,
                        color: Colors.black54,
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return Dialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              backgroundColor: const Color(0xFFF8F8FC),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight:
                                      MediaQuery.of(context).size.height * 0.7,
                                  minWidth: 0,
                                  maxWidth: 400,
                                ),
                                child: SingleChildScrollView(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 24,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Reset Data',
                                              style: TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.close,
                                                color: Colors.red,
                                                size: 22,
                                              ),
                                              padding: EdgeInsets.zero,
                                              constraints: BoxConstraints(),
                                              tooltip: 'Close',
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        const Divider(
                                          height: 1,
                                          thickness: 1,
                                          color: Color(0xFFE0E0E0),
                                        ),
                                        const SizedBox(height: 18),
                                        const Text(
                                          'What would you like to reset?',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 28),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(
                                                    0xFF3B4FE0,
                                                  ),
                                                  foregroundColor: Colors.white,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 10,
                                                      ),
                                                  textStyle: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                ),
                                                onPressed: () async {
                                                  final confirm = await showDialog<bool>(
                                                    context: context,
                                                    builder: (context) =>
                                                        AlertDialog(
                                                          title: const Text(
                                                            'Are you sure?',
                                                          ),
                                                          content: const Text(
                                                            'Quiz data (stats, wrongs, favorites) will be reset. Manually added words and phrases will be kept.',
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                    context,
                                                                    false,
                                                                  ),
                                                              child: const Text(
                                                                'Cancel',
                                                              ),
                                                            ),
                                                            ElevatedButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                    context,
                                                                    true,
                                                                  ),
                                                              child: const Text(
                                                                'Reset',
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                  );
                                                  if (confirm == true) {
                                                    await StatsService.resetQuizData();
                                                    widget.onQuizStatsRefresh();
                                                    widget
                                                        .onRefreshRecentlyAdded();
                                                    Navigator.pop(context);
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Quiz data reset!',
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                                child: const Text(
                                                  'Reset Quiz Data',
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(
                                                    0xFFFF5A5F,
                                                  ),
                                                  foregroundColor: Colors.white,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 10,
                                                      ),
                                                  textStyle: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                ),
                                                onPressed: () async {
                                                  final confirm = await showDialog<bool>(
                                                    context: context,
                                                    builder: (context) =>
                                                        AlertDialog(
                                                          title: const Text(
                                                            'Are you sure?',
                                                          ),
                                                          content: const Text(
                                                            'All data will be reset, including manually added words and phrases.',
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                    context,
                                                                    false,
                                                                  ),
                                                              child: const Text(
                                                                'Cancel',
                                                              ),
                                                            ),
                                                            ElevatedButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                    context,
                                                                    true,
                                                                  ),
                                                              child: const Text(
                                                                'Reset All',
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                  );
                                                  if (confirm == true) {
                                                    await StatsService.resetAllData();
                                                    // Update Home Page state after reset
                                                    widget.onQuizStatsRefresh();
                                                    widget
                                                        .onRefreshRecentlyAdded();
                                                    Navigator.pop(context);
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'All data reset!',
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                                child: const Text(
                                                  'Reset All Data',
                                                ),
                                              ),
                                            ),
                                          ],
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
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                statCards,
                const SizedBox(height: 32),
                _ModernButton(
                  text: "Start Quiz",
                  icon: Icons.quiz,
                  color: const Color(0xFF3B4FE0),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuizPage(
                          onFavoriteAdded: widget.onRefreshRecentlyAdded,
                        ),
                      ),
                    ).then((_) => widget.onQuizStatsRefresh());
                  },
                ),
                const SizedBox(height: 32),
                // Recently Added
                const Text(
                  'Recently Added',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3A7B),
                  ),
                ),
                const SizedBox(height: 14),
                if (lastFavorite != null)
                  _RecentCard(
                    icon: Icons.favorite,
                    color: Color(0xFFF94F8E),
                    title: lastFavorite!['word'] ?? '',
                    subtitle: lastFavorite!['meaning'] ?? '',
                    label: 'Favorite Words',
                    labelColor: Color(0xFFF94F8E),
                  ),
                if (lastPhrase != null) _buildRecentPhraseCard(lastPhrase),
                if (lastMoviePhrase != null)
                  _RecentCard(
                    icon: Icons.movie,
                    color: Color(0xFF9C27B0),
                    title: lastMoviePhrase!['phrase'] ?? '',
                    subtitle: '',
                    subtitleWidget: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lastMoviePhrase!['meaning'] ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
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
                            lastMoviePhrase!['movie'] ?? '',
                            style: TextStyle(
                              color: Colors.purple.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    label: 'Movie Phrases',
                    labelColor: Color(0xFF9C27B0),
                  ),
                if (lastFavorite == null &&
                    lastPhrase == null &&
                    lastMoviePhrase == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No recent items yet.',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void reloadRecent() {
    _loadRecent();
  }

  Widget _buildRecentPhraseCard(Map<String, String>? lastPhrase) {
    if (lastPhrase == null) return const SizedBox.shrink();
    final movieMatch = StatsService.getMoviePhrases().firstWhere(
      (mp) =>
          mp['phrase'] == lastPhrase['phrase'] &&
          mp['meaning'] == lastPhrase['meaning'],
      orElse: () => {},
    );
    final hasMovie =
        movieMatch.isNotEmpty && (movieMatch['movie']?.isNotEmpty ?? false);
    final movieName = hasMovie ? movieMatch['movie']! : null;
    if (hasMovie && movieName != null) {
      return _RecentCard(
        icon: Icons.format_quote,
        color: Color(0xFF8E54E9),
        title: lastPhrase['phrase'] ?? '',
        subtitle: '',
        subtitleWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lastPhrase['meaning'] ?? '',
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                movieName,
                style: TextStyle(
                  color: Colors.purple.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        label: 'Phrases',
        labelColor: Color(0xFF8E54E9),
      );
    } else {
      return _RecentCard(
        icon: Icons.format_quote,
        color: Color(0xFF8E54E9),
        title: lastPhrase['phrase'] ?? '',
        subtitle: lastPhrase['meaning'] ?? '',
        label: 'Phrases',
        labelColor: Color(0xFF8E54E9),
      );
    }
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final Color iconColor;
  final Color valueColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.iconColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 15, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _ModernButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ModernButton({
    required this.text,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        icon: Icon(icon, size: 26),
        label: Text(text),
        onPressed: onPressed,
      ),
    );
  }
}

class _RecentCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String label;
  final Color labelColor;
  final Widget? subtitleWidget;

  const _RecentCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.label,
    required this.labelColor,
    this.subtitleWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color, size: 28),
            radius: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF2D3A7B),
                  ),
                ),
                const SizedBox(height: 4),
                if (subtitleWidget != null)
                  subtitleWidget!
                else
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                const SizedBox(height: 4),
                Text(label, style: TextStyle(fontSize: 13, color: labelColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
