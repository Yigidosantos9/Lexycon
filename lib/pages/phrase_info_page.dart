import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/stats_service.dart';
import '../services/movie_phrases_service.dart';

class PhraseInfoPage extends StatefulWidget {
  final String phrase;
  final String meaning;
  final String? movie;
  final VoidCallback? onDelete;

  const PhraseInfoPage({
    Key? key,
    required this.phrase,
    required this.meaning,
    this.movie,
    this.onDelete,
  }) : super(key: key);

  @override
  State<PhraseInfoPage> createState() => _PhraseInfoPageState();
}

class _PhraseInfoPageState extends State<PhraseInfoPage> {
  late TextEditingController phraseController;
  late TextEditingController meaningController;
  late TextEditingController sentenceController;
  late TextEditingController movieController;
  String? imagePath;
  late SharedPreferences prefs;
  late FlutterTts flutterTts;
  List<String> selectedCategories = ['Uncategorized'];
  int selectedMastery = -1;
  final List<String> categories = [
    'Uncategorized',
    'Daily',
    'Travel',
    'Work & Study',
    'Special Topics',
  ];

  String get _prefsKey => 'phraseinfo_${widget.phrase}_${widget.meaning}';

  @override
  void initState() {
    super.initState();
    phraseController = TextEditingController(text: widget.phrase);
    meaningController = TextEditingController(text: widget.meaning);
    sentenceController = TextEditingController();
    movieController = TextEditingController(text: widget.movie ?? '');
    flutterTts = FlutterTts();
    flutterTts.setLanguage("en-US");
    flutterTts.setPitch(1.0);
    _loadPrefs();
    // Movie phrase ise movie name'i otomatik doldur
    final movieMatch = MoviePhrasesService.getMoviePhrases().firstWhere(
      (mp) => mp['phrase'] == widget.phrase && mp['meaning'] == widget.meaning,
      orElse: () => {},
    );
    if (movieMatch.isNotEmpty &&
        (movieMatch['movie']?.isNotEmpty ?? false) &&
        (widget.movie == null || widget.movie!.isEmpty)) {
      movieController.text = movieMatch['movie']!;
    }
    // Load category/mastery from phrase
    final phraseEntry = StatsService.getPhrases().firstWhere(
      (p) => p['phrase'] == widget.phrase && p['meaning'] == widget.meaning,
      orElse: () => {},
    );
    if (phraseEntry.isNotEmpty) {
      final cats = phraseEntry['category'];
      if (cats is List) {
        selectedCategories = (cats as List).map((c) => c.toString()).toList();
      } else if (cats is String) {
        selectedCategories = [cats];
      } else {
        selectedCategories = ['Uncategorized'];
      }
      final masteryValue = phraseEntry['mastery'];
      selectedMastery = int.tryParse(masteryValue?.toString() ?? '-1') ?? -1;
    }
  }

  Future<void> _loadPrefs() async {
    prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_prefsKey);
    if (data != null && data.length >= 3) {
      setState(() {
        sentenceController.text = data[0];
        movieController.text = data[1];
        imagePath = data[2].isNotEmpty ? data[2] : null;
      });
    }
  }

  Future<void> _saveAll() async {
    final oldPhrase = widget.phrase;
    final oldMeaning = widget.meaning;
    final newPhrase = phraseController.text.trim();
    final newMeaning = meaningController.text.trim();
    final newMovie = movieController.text.trim();
    final newCategory = selectedCategories.isNotEmpty
        ? selectedCategories
        : ['Uncategorized'];
    final newMastery = selectedMastery;
    // Update in phrases
    final phrases = StatsService.getPhrases().map((p) {
      return Map<String, dynamic>.from(p);
    }).toList();
    bool updated = false;
    for (var p in phrases) {
      if (p['phrase'] == oldPhrase && p['meaning'] == oldMeaning) {
        p['phrase'] = newPhrase;
        p['meaning'] = newMeaning;
        p['category'] = newCategory;
        p['mastery'] = newMastery.toString();
        updated = true;
      }
    }
    if (updated) {
      StatsService.savePhrases(phrases);
    }
    // Save extra fields with new key
    final newPrefsKey = 'phraseinfo_${newPhrase}_${newMeaning}';
    await prefs.setStringList(newPrefsKey, [
      sentenceController.text,
      newMovie,
      imagePath ?? '',
    ]);
    if (newPrefsKey != _prefsKey) {
      await prefs.remove(_prefsKey);
    }
    // Movie name eklenmişse movie phrases'e ekle/güncelle, silinmişse çıkar
    if (newMovie.isNotEmpty) {
      // Movie phrases'te varsa güncelle, yoksa ekle
      final moviePhrases = StatsService.getMoviePhrases();
      final idx = moviePhrases.indexWhere(
        (mp) => mp['phrase'] == newPhrase && mp['meaning'] == newMeaning,
      );
      if (idx >= 0) {
        moviePhrases[idx]['movie'] = newMovie;
      } else {
        moviePhrases.add({
          'phrase': newPhrase,
          'meaning': newMeaning,
          'movie': newMovie,
        });
      }
      StatsService.saveMoviePhrases(moviePhrases);
    } else {
      // Movie name silindiyse movie phrases'ten çıkar
      final moviePhrases = StatsService.getMoviePhrases();
      moviePhrases.removeWhere(
        (mp) => mp['phrase'] == newPhrase && mp['meaning'] == newMeaning,
      );
      StatsService.saveMoviePhrases(moviePhrases);
    }
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Changes saved!')));
      Navigator.pop(context, true);
    }
  }

  Future<void> _pickImage({ImageSource? source}) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source ?? ImageSource.gallery,
    );
    if (picked != null) {
      setState(() {
        imagePath = picked.path;
      });
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF8E54E9)),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(source: ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo, color: Color(0xFF8E54E9)),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(source: ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _speak() async {
    await flutterTts.stop();
    await flutterTts.speak(phraseController.text);
  }

  void _delete() {
    if (widget.onDelete != null) widget.onDelete!();
    Navigator.pop(context, 'deleted');
  }

  @override
  void dispose() {
    phraseController.dispose();
    meaningController.dispose();
    sentenceController.dispose();
    movieController.dispose();
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Phrase Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF8E54E9),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up),
            tooltip: 'Speak',
            onPressed: _speak,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            onPressed: _delete,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveAll,
        backgroundColor: const Color(0xFF8E54E9),
        foregroundColor: Colors.white,
        child: const Icon(Icons.check, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: phraseController,
              decoration: const InputDecoration(
                labelText: 'Phrase',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: meaningController,
              decoration: const InputDecoration(
                labelText: 'Meaning',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Categories',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: categories.map((category) {
                final isSelected = selectedCategories.contains(category);
                return FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        if (category == 'Uncategorized') {
                          selectedCategories = ['Uncategorized'];
                        } else {
                          selectedCategories.remove('Uncategorized');
                          selectedCategories.add(category);
                        }
                      } else {
                        selectedCategories.remove(category);
                        if (selectedCategories.isEmpty) {
                          selectedCategories.add('Uncategorized');
                        }
                      }
                    });
                  },
                  selectedColor: const Color(0xFF8E54E9).withOpacity(0.2),
                  checkmarkColor: const Color(0xFF8E54E9),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mastery Level',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(
                    5,
                    (i) => IconButton(
                      icon: Icon(
                        i < (selectedMastery > 0 ? selectedMastery : 0)
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                      ),
                      iconSize: 22,
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        setState(() {
                          selectedMastery = (i + 1 == selectedMastery)
                              ? -1
                              : i + 1;
                        });
                      },
                    ),
                  ),
                ),
                if (selectedMastery == -1)
                  const Text(
                    'Unspecified',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                if (selectedMastery == 1)
                  const Text(
                    'Just Getting Started',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                if (selectedMastery == 2)
                  const Text(
                    'Recognize Only',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                if (selectedMastery == 3)
                  const Text(
                    'Rarely Used',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                if (selectedMastery == 4)
                  const Text(
                    'Somewhat Comfortable',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                if (selectedMastery == 5)
                  const Text(
                    'Confident User',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: sentenceController,
              decoration: const InputDecoration(
                labelText: 'Sample Sentence',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: movieController,
              decoration: const InputDecoration(
                labelText: 'Movie Name (optional)',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: _showImageSourceActionSheet,
              child: Container(
                width: double.infinity,
                height: 250,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(18),
                  image: imagePath != null
                      ? DecorationImage(
                          image: FileImage(File(imagePath!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: imagePath == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.image, size: 60, color: Colors.grey),
                            SizedBox(height: 12),
                            Text(
                              'Tap to add photo',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: ElevatedButton.icon(
                onPressed: _showImageSourceActionSheet,
                icon: const Icon(Icons.photo),
                label: const Text('Change Photo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8E54E9),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
