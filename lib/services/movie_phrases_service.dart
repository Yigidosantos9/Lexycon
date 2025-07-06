import 'dart:convert';
import 'package:flutter/services.dart';
import 'stats_service.dart';

class MoviePhrasesService {
  static const String _assetPath = 'assets/movie_phrases.json';

  /// Load movie phrases from JSON file and import them into app storage
  static Future<void> importMoviePhrasesFromJson() async {
    try {
      // Load JSON file
      final String jsonString = await rootBundle.loadString(_assetPath);
      final List<dynamic> jsonList = json.decode(jsonString);

      // Convert to the format expected by the app
      final List<Map<String, String>> moviePhrases = jsonList.map((item) {
        final Map<String, dynamic> dynamicItem = item as Map<String, dynamic>;
        return {
          'phrase': dynamicItem['phrase']?.toString() ?? '',
          'meaning': dynamicItem['meaning']?.toString() ?? '',
          'movie': dynamicItem['movie']?.toString() ?? '',
        };
      }).toList();

      // Check if we already have movie phrases in storage
      final existingPhrases = StatsService.getMoviePhrases();

      // Only import if we don't have any phrases yet
      if (existingPhrases.isEmpty) {
        StatsService.saveMoviePhrases(moviePhrases);
        print('Imported ${moviePhrases.length} movie phrases from JSON');
      } else {
        print(
          'Movie phrases already exist in storage (${existingPhrases.length} phrases)',
        );
      }
    } catch (e) {
      print('Error importing movie phrases: $e');
    }
  }

  /// Get all movie phrases (from storage)
  static List<Map<String, String>> getMoviePhrases() {
    return StatsService.getMoviePhrases();
  }

  /// Add a new movie phrase
  static void addMoviePhrase(String phrase, String meaning, String movie) {
    StatsService.addMoviePhrase(phrase, meaning, movie);
  }

  /// Delete a movie phrase
  static void deleteMoviePhrase(String phrase, String meaning, String movie) {
    final phrases = getMoviePhrases();
    phrases.removeWhere(
      (p) =>
          p['phrase'] == phrase &&
          p['meaning'] == meaning &&
          p['movie'] == movie,
    );
    StatsService.saveMoviePhrases(phrases);
  }
}
