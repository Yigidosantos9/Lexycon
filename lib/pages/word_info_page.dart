import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/stats_service.dart';

class WordInfoPage extends StatefulWidget {
  final String word;
  final String meaning;
  final VoidCallback? onDelete;

  const WordInfoPage({
    Key? key,
    required this.word,
    required this.meaning,
    this.onDelete,
  }) : super(key: key);

  @override
  State<WordInfoPage> createState() => _WordInfoPageState();
}

class _WordInfoPageState extends State<WordInfoPage> {
  late TextEditingController wordController;
  late TextEditingController meaningController;
  late TextEditingController sentenceController;
  late TextEditingController synonymController;
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

  String get _prefsKey => 'wordinfo_${widget.word}_${widget.meaning}';

  bool get _showAddPhotoPrompt =>
      imagePath == null ||
      imagePath!.isEmpty ||
      !(File(imagePath!).existsSync());

  @override
  void initState() {
    super.initState();
    wordController = TextEditingController(text: widget.word);
    meaningController = TextEditingController(text: widget.meaning);
    sentenceController = TextEditingController();
    synonymController = TextEditingController();
    flutterTts = FlutterTts();
    flutterTts.setLanguage("en-US");
    flutterTts.setPitch(1.0);
    _loadPrefs();
    _loadCategoryAndMastery();
  }

  void _loadCategoryAndMastery() {
    // Try to find the favorite entry and load its category/mastery
    final allFavs = [
      ...StatsService.getManualFavorites(),
      ...StatsService.getQuizFavorites(),
    ];
    final match = allFavs.firstWhere(
      (f) => f['word'] == widget.word && f['meaning'] == widget.meaning,
      orElse: () => <String, dynamic>{},
    );
    setState(() {
      final cats = match['category'];
      if (cats is List) {
        // Ensure it's a List<String>
        selectedCategories = cats.map((c) => c.toString()).toList();
      } else if (cats is String) {
        selectedCategories = [cats];
      } else {
        selectedCategories = ['Uncategorized'];
      }
      selectedMastery = match.isNotEmpty ? (match['mastery'] ?? -1) : -1;
    });
  }

  Future<void> _loadPrefs() async {
    prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_prefsKey);
    if (data != null && data.length >= 3) {
      setState(() {
        sentenceController.text = data[0];
        synonymController.text = data[1];
        imagePath = data[2].isNotEmpty ? data[2] : null;
      });
    }
  }

  Future<void> _saveAll() async {
    // Update word/meaning/category/mastery in favorites if changed
    final oldWord = widget.word;
    final oldMeaning = widget.meaning;
    final newWord = wordController.text.trim();
    final newMeaning = meaningController.text.trim();
    final newCategory = selectedCategories.isNotEmpty
        ? selectedCategories
        : ['Uncategorized'];
    final newMastery = selectedMastery;
    // Update in manualFavorites and quizFavorites
    final manualList = StatsService.getManualFavorites();
    final quizList = StatsService.getQuizFavorites();
    bool updated = false;
    for (var fav in manualList) {
      if (fav['word'] == oldWord && fav['meaning'] == oldMeaning) {
        fav['word'] = newWord;
        fav['meaning'] = newMeaning;
        fav['category'] = newCategory;
        fav['mastery'] = newMastery;
        updated = true;
      }
    }
    for (var fav in quizList) {
      if (fav['word'] == oldWord && fav['meaning'] == oldMeaning) {
        fav['word'] = newWord;
        fav['meaning'] = newMeaning;
        fav['category'] = newCategory;
        fav['mastery'] = newMastery;
        updated = true;
      }
    }
    if (updated) {
      StatsService.saveManualFavorites(manualList);
      StatsService.saveFavorites(quizList);
    }
    // Save extra fields with new key
    final newPrefsKey = 'wordinfo_${newWord}_${newMeaning}';
    await prefs.setStringList(newPrefsKey, [
      sentenceController.text,
      synonymController.text,
      imagePath ?? '',
    ]);
    // If word/meaning changed, remove old extra fields
    if (newPrefsKey != _prefsKey) {
      await prefs.remove(_prefsKey);
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
              leading: const Icon(Icons.camera_alt, color: Color(0xFFF94F8E)),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(source: ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo, color: Color(0xFFF94F8E)),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(source: ImageSource.gallery);
              },
            ),
            if (!_showAddPhotoPrompt)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Remove Photo',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  setState(() {
                    imagePath = null;
                  });
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _speak() async {
    await flutterTts.stop();
    await flutterTts.speak(wordController.text);
  }

  void _delete() {
    if (widget.onDelete != null) widget.onDelete!();
    Navigator.pop(context, 'deleted');
  }

  @override
  void dispose() {
    wordController.dispose();
    meaningController.dispose();
    sentenceController.dispose();
    synonymController.dispose();
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Word Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF94F8E),
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
        backgroundColor: const Color(0xFFF94F8E),
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
              controller: wordController,
              decoration: const InputDecoration(
                labelText: 'Word',
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
                  selectedColor: const Color(0xFFF94F8E).withOpacity(0.2),
                  checkmarkColor: const Color(0xFFF94F8E),
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
              controller: synonymController,
              decoration: const InputDecoration(
                labelText: 'Synonym',
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
                  image: !_showAddPhotoPrompt
                      ? DecorationImage(
                          image: FileImage(File(imagePath!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _showAddPhotoPrompt
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
                  backgroundColor: const Color(0xFFF94F8E),
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
