import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class StatsService {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static void incrementQuiz({required int correct, required int wrong}) {
    int total = _prefs.getInt('quizTotal') ?? 0;
    int currentCorrect = _prefs.getInt('quizCorrect') ?? 0;
    int currentWrong = _prefs.getInt('quizWrong') ?? 0;

    _prefs.setInt('quizTotal', total + 1);
    _prefs.setInt('quizCorrect', currentCorrect + correct);
    _prefs.setInt('quizWrong', currentWrong + wrong);
  }

  static void saveFavorites(List<Map<String, dynamic>> favorites) {
    _prefs.setStringList(
      'favorites',
      favorites
          .map(
            (e) =>
                '${e['word'].toString()}|${e['meaning'].toString()}|${(e['category'] as List<String>).join(',')}|${e['mastery']?.toString() ?? '-1'}',
          )
          .toList(),
    );
  }

  static List<Map<String, dynamic>> getFavorites() {
    final manual = getManualFavorites();
    final quiz = getQuizFavorites();
    final all = [...manual];
    for (final f in quiz) {
      if (!all.any(
        (e) => e['word'] == f['word'] && e['meaning'] == f['meaning'],
      )) {
        all.add(f);
      }
    }
    return all;
  }

  static void addFavorite(
    String word,
    String meaning, {
    bool manual = false,
    List<String>? category,
    int? mastery,
  }) {
    if (manual) {
      final manualFavs = List<Map<String, dynamic>>.from(
        getManualFavorites().map((e) => Map<String, dynamic>.from(e)),
      );
      if (!manualFavs.any(
        (f) => f['word'] == word && f['meaning'] == meaning,
      )) {
        manualFavs.add({
          'word': word,
          'meaning': meaning,
          'category': category ?? ['Uncategorized'],
          'mastery': mastery ?? -1,
        });
        _prefs.setStringList(
          'manualFavorites',
          manualFavs
              .map(
                (e) =>
                    '${e['word'].toString()}|${e['meaning'].toString()}|${(e['category'] as List<String>).join(',')}|${e['mastery']?.toString() ?? '-1'}',
              )
              .toList(),
        );
      }
    } else {
      final quizFavs = List<Map<String, dynamic>>.from(
        getQuizFavorites().map((e) => Map<String, dynamic>.from(e)),
      );
      if (!quizFavs.any((f) => f['word'] == word && f['meaning'] == meaning)) {
        quizFavs.add({
          'word': word,
          'meaning': meaning,
          'category': category ?? ['Uncategorized'],
          'mastery': mastery ?? -1,
        });
        _prefs.setStringList(
          'favorites',
          quizFavs
              .map(
                (e) =>
                    '${e['word'].toString()}|${e['meaning'].toString()}|${(e['category'] as List<String>).join(',')}|${e['mastery']?.toString() ?? '-1'}',
              )
              .toList(),
        );
      }
    }
  }

  static List<Map<String, dynamic>> getManualFavorites() {
    final list = _prefs.getStringList('manualFavorites') ?? [];
    return list.map((e) {
      final parts = e.split('|');
      final categoryString = parts.length > 2 && parts[2].isNotEmpty
          ? parts[2]
          : 'Uncategorized';
      return {
        'word': parts[0],
        'meaning': parts.length > 1 ? parts[1] : '',
        'category': categoryString.split(','),
        'mastery': parts.length > 3 && parts[3].isNotEmpty
            ? int.tryParse(parts[3]) ?? -1
            : -1,
      };
    }).toList();
  }

  static List<Map<String, dynamic>> getQuizFavorites() {
    final list = _prefs.getStringList('favorites') ?? [];
    return list.map((e) {
      final parts = e.split('|');
      final categoryString = parts.length > 2 && parts[2].isNotEmpty
          ? parts[2]
          : 'Uncategorized';
      return {
        'word': parts[0],
        'meaning': parts.length > 1 ? parts[1] : '',
        'category': categoryString.split(','),
        'mastery': parts.length > 3 && parts[3].isNotEmpty
            ? int.tryParse(parts[3]) ?? -1
            : -1,
      };
    }).toList();
  }

  static void saveWrongWords(Set<String> wrongWords) {
    final existing = getWrongWords();
    final merged = existing.union(wrongWords).toList();
    _prefs.setStringList('wrongWords', merged);
  }

  static Set<String> getWrongWords() {
    return _prefs.getStringList('wrongWords')?.toSet() ?? {};
  }

  static QuizStats getStats() {
    final total = _prefs.getInt('quizTotal') ?? 0;
    final correct = _prefs.getInt('quizCorrect') ?? 0;
    final wrong = _prefs.getInt('quizWrong') ?? 0;
    return QuizStats(total: total, correct: correct, wrong: wrong);
  }

  static List<Map<String, String>> getPhrases() {
    final list = _prefs.getStringList('phrases') ?? [];
    return list
        .map((e) {
          final parts = e.split('|');
          final categoryString = parts.length > 2 && parts[2].isNotEmpty
              ? parts[2]
              : 'Uncategorized';
          return {
            'phrase': parts[0],
            'meaning': parts.length > 1 ? parts[1] : '',
            'category': categoryString,
            'mastery': parts.length > 3 && parts[3].isNotEmpty
                ? parts[3]
                : '-1',
          };
        })
        .map((e) {
          return {
            'phrase': e['phrase'] as String,
            'meaning': e['meaning'] as String,
            'category': e['category'] as String,
            'mastery': e['mastery'] as String,
          };
        })
        .toList();
  }

  static void savePhrases(List<Map<String, dynamic>> phrases) {
    final jsonList = phrases.map((e) {
      final rawCategory = e['category'];
      String categoryString;
      if (rawCategory is List) {
        categoryString = (rawCategory as List)
            .map((c) => c.toString())
            .join(',');
      } else if (rawCategory is String) {
        categoryString = rawCategory;
      } else {
        categoryString = 'Uncategorized';
      }
      return '${e['phrase']}|${e['meaning']}|${categoryString}|${e['mastery'] ?? '-1'}';
    }).toList();
    _prefs.setStringList('phrases', jsonList);
  }

  static void addPhrase(
    String phrase,
    String meaning, {
    List<String>? category,
    String? mastery,
  }) {
    final phrases = List<Map<String, dynamic>>.from(
      getPhrases().map((e) => Map<String, dynamic>.from(e)),
    );
    phrases.add({
      'phrase': phrase,
      'meaning': meaning,
      'category': category ?? ['Uncategorized'],
      'mastery': mastery ?? '-1',
    });
    savePhrases(phrases);
  }

  // Movie Phrases methods
  static void saveMoviePhrases(List<Map<String, String>> moviePhrases) {
    final jsonList = moviePhrases
        .map((e) => '${e['phrase']}|${e['meaning']}|${e['movie'] ?? ''}')
        .toList();
    _prefs.setStringList('moviePhrases', jsonList);
  }

  static List<Map<String, String>> getMoviePhrases() {
    final list = _prefs.getStringList('moviePhrases') ?? [];
    return list.map((e) {
      final parts = e.split('|');
      return {
        'phrase': parts[0],
        'meaning': parts.length > 1 ? parts[1] : '',
        'movie': parts.length > 2 ? parts[2] : '',
      };
    }).toList();
  }

  static void addMoviePhrase(String phrase, String meaning, String movie) {
    final moviePhrases = getMoviePhrases();
    moviePhrases.add({'phrase': phrase, 'meaning': meaning, 'movie': movie});
    saveMoviePhrases(moviePhrases);
  }

  static Future<void> resetQuizData() async {
    _prefs.setInt('quizTotal', 0);
    _prefs.setInt('quizCorrect', 0);
    _prefs.setInt('quizWrong', 0);
    _prefs.setStringList('wrongWords', []);
    _prefs.setInt('quiz_word_index', 0);
    saveFavorites([]);
  }

  static Future<void> resetAllData() async {
    // Load default movie phrases from assets
    final String jsonString = await rootBundle.loadString(
      'assets/movie_phrases.json',
    );
    final List<dynamic> jsonList = json.decode(jsonString);
    final Set<String> defaultMovieKeys = jsonList
        .map((item) => "${item['phrase']}|${item['meaning']}")
        .toSet();
    // Get current movie phrases
    final allMoviePhrases = getMoviePhrases();
    // Only keep default ones
    final filteredMoviePhrases = allMoviePhrases
        .where(
          (mp) => defaultMovieKeys.contains("${mp['phrase']}|${mp['meaning']}"),
        )
        .toList();
    // Clear all data
    await _prefs.clear();
    // Restore only default movie phrases
    saveMoviePhrases(filteredMoviePhrases);
    // Remove movie phrases from favorites
    final moviePhraseKeys = filteredMoviePhrases
        .map((mp) => "${mp['phrase']}|${mp['meaning']}")
        .toSet();
    // Remove from quiz favorites
    final quizFavs = getQuizFavorites().where(
      (fav) => !moviePhraseKeys.contains("${fav['word']}|${fav['meaning']}"),
    );
    saveFavorites(quizFavs.toList());
    // Remove from manual favorites
    final manualFavs = getManualFavorites().where(
      (fav) => !moviePhraseKeys.contains("${fav['word']}|${fav['meaning']}"),
    );
    saveManualFavorites(manualFavs.toList());
  }

  static void saveManualFavorites(List<Map<String, dynamic>> manualFavorites) {
    _prefs.setStringList(
      'manualFavorites',
      manualFavorites
          .map(
            (e) =>
                '${e['word'].toString()}|${e['meaning'].toString()}|${(e['category'] as List<String>).join(',')}|${e['mastery']?.toString() ?? '-1'}',
          )
          .toList(),
    );
  }

  static SharedPreferences get prefs => _prefs;
}

class QuizStats {
  final int total;
  final int correct;
  final int wrong;

  QuizStats({required this.total, required this.correct, required this.wrong});
}
