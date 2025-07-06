// pages/quiz_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:language_app/services/stats_service.dart';
import 'result_page.dart';
import 'favorites_page.dart';
import '../services/question_service.dart';

class QuizPage extends StatefulWidget {
  final VoidCallback? onFavoriteAdded;
  const QuizPage({super.key, this.onFavoriteAdded});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  List<Map<String, dynamic>> questions = [];
  int currentIndex = 0;
  int score = 0;
  List<Map<String, dynamic>> wrongAnswers = [];
  List<Map<String, String>> favoriteWords = [];
  late FlutterTts flutterTts;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
    flutterTts = FlutterTts();
    flutterTts.setLanguage("en-US");
    flutterTts.setPitch(1.0);
  }

  Future<void> _loadQuestions() async {
    final loaded = await QuestionService.getNextQuizQuestions(10);
    // this is for testing if "You have completed all the words!" works, if you want to check uncomment that line and comment the line above.
    // final loaded = <Map<String, dynamic>>[];
    setState(() {
      questions = loaded;
      isLoading = false;
    });
    if (loaded.isEmpty) {
      Future.delayed(Duration.zero, () {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.emoji_events,
                    color: Color(0xFF3B4FE0),
                    size: 56,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    "Congratulations!",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3A7B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "You have completed all the words in the quiz!\nKeep practicing to improve your English 🎉",
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B4FE0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 32,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop(); // QuizPage'den çık
                    },
                    child: const Text("Back to Home"),
                  ),
                ],
              ),
            ),
          ),
        );
      });
    }
  }

  void speak(String text) async {
    await flutterTts.stop();
    await flutterTts.speak(text);
  }

  void checkAnswer(String selected) {
    final current = questions[currentIndex];
    bool isCorrect = selected == current['correct'];

    setState(() {
      if (isCorrect) {
        score++;
      } else {
        wrongAnswers.add(current);
      }

      if (currentIndex < questions.length - 1) {
        currentIndex++;
      } else {
        QuestionService.advanceQuizIndex(questions.length);
        StatsService.incrementQuiz(correct: score, wrong: wrongAnswers.length);
        // Merge and save favorites
        final existingFavorites = StatsService.getFavorites();
        final mergedFavorites = [...existingFavorites];
        for (final fav in favoriteWords) {
          if (!mergedFavorites.any(
            (e) => e['word'] == fav['word'] && e['meaning'] == fav['meaning'],
          )) {
            mergedFavorites.add(fav);
          }
        }
        StatsService.saveFavorites(mergedFavorites);
        // Merge and save wrong answers
        final existingWrongs = StatsService.getWrongWords();
        final newWrongs = wrongAnswers.map((e) => e['word'] as String).toSet();
        final mergedWrongs = existingWrongs.union(newWrongs);
        StatsService.saveWrongWords(mergedWrongs);
        if (widget.onFavoriteAdded != null) widget.onFavoriteAdded!();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultPage(
              score: score,
              total: questions.length,
              wrongAnswers: wrongAnswers,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || questions.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final current = questions[currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${currentIndex + 1}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Show Progress',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (context) {
                  return DraggableScrollableSheet(
                    expand: false,
                    initialChildSize: 0.7,
                    minChildSize: 0.3,
                    maxChildSize: 0.95,
                    builder: (context, scrollController) {
                      return SingleChildScrollView(
                        controller: scrollController,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Quiz Progress',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...List.generate(currentIndex + 1, (i) {
                                final q = questions[i];
                                final alreadyFav = favoriteWords.any(
                                  (f) => f['word'] == q['word'],
                                );
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      q['word'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(q['correct']),
                                    leading: IconButton(
                                      icon: const Icon(
                                        Icons.volume_up,
                                        color: Colors.indigo,
                                      ),
                                      onPressed: () => speak(q['word']),
                                    ),
                                    trailing: IconButton(
                                      icon: alreadyFav
                                          ? const Icon(
                                              Icons.favorite,
                                              color: Color(0xFFF94F8E),
                                            )
                                          : const Icon(
                                              Icons.favorite_border,
                                              color: Color(0xFF3B4FE0),
                                            ),
                                      onPressed: () {
                                        setState(() {
                                          if (alreadyFav) {
                                            favoriteWords.removeWhere(
                                              (f) => f['word'] == q['word'],
                                            );
                                            // Remove from StatsService favorites
                                            final manualList =
                                                StatsService.getManualFavorites();
                                            final quizList =
                                                StatsService.getQuizFavorites();
                                            manualList.removeWhere(
                                              (f) => f['word'] == q['word'],
                                            );
                                            quizList.removeWhere(
                                              (f) => f['word'] == q['word'],
                                            );
                                            StatsService.saveManualFavorites(
                                              manualList,
                                            );
                                            StatsService.saveFavorites(
                                              quizList,
                                            );
                                          } else {
                                            favoriteWords.add({
                                              'word': q['word'],
                                              'meaning': q['correct'],
                                              'manual': '0',
                                            });
                                            StatsService.addFavorite(
                                              q['word'],
                                              q['correct'],
                                              manual: false,
                                            );
                                          }
                                        });
                                        if (widget.onFavoriteAdded != null)
                                          widget.onFavoriteAdded!();
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              alreadyFav
                                                  ? '“${q['word']}” favorilerden çıkarıldı'
                                                  : '“${q['word']}” favorilere eklendi',
                                            ),
                                            duration: const Duration(
                                              seconds: 2,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              current['word'],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: () => speak(current['word']),
              icon: const Icon(Icons.volume_up),
              tooltip: 'Listen',
              color: Colors.indigo,
              iconSize: 32,
            ),
            const SizedBox(height: 32),
            ...current['options'].map<Widget>(
              (opt) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ElevatedButton(
                  onPressed: () => checkAnswer(opt),
                  child: Text(opt),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  final isFav = favoriteWords.any(
                    (f) => f['word'] == current['word'],
                  );
                  setState(() {
                    if (isFav) {
                      favoriteWords.removeWhere(
                        (f) => f['word'] == current['word'],
                      );
                      // Remove from StatsService favorites
                      final manualList = StatsService.getManualFavorites();
                      final quizList = StatsService.getQuizFavorites();
                      manualList.removeWhere(
                        (f) => f['word'] == current['word'],
                      );
                      quizList.removeWhere((f) => f['word'] == current['word']);
                      StatsService.saveManualFavorites(manualList);
                      StatsService.saveFavorites(quizList);
                    } else {
                      favoriteWords.add({
                        'word': current['word'],
                        'meaning': current['correct'],
                        'manual': '0',
                      });
                      StatsService.addFavorite(
                        current['word'],
                        current['correct'],
                        manual: false,
                      );
                    }
                  });
                  if (widget.onFavoriteAdded != null) widget.onFavoriteAdded!();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isFav
                            ? '“${current['word']}” favorilerden çıkarıldı'
                            : '“${current['word']}” favorilere eklendi',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                icon: favoriteWords.any((f) => f['word'] == current['word'])
                    ? const Icon(Icons.favorite, color: Color(0xFFF94F8E))
                    : const Icon(
                        Icons.favorite_border,
                        color: Color(0xFF3B4FE0),
                      ),
                label: Text(
                  favoriteWords.any((f) => f['word'] == current['word'])
                      ? "Added to Favorites"
                      : "Add to Favorites",
                  style: TextStyle(
                    color:
                        favoriteWords.any((f) => f['word'] == current['word'])
                        ? Color(0xFFF94F8E)
                        : Color(0xFF3B4FE0),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      favoriteWords.any((f) => f['word'] == current['word'])
                      ? const Color(0xFFFFE4EC)
                      : const Color(0xFFEAF0FF),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shadowColor: Colors.transparent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
