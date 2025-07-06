import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/stats_service.dart';

class AddWordPage extends StatefulWidget {
  @override
  State<AddWordPage> createState() => _AddWordPageState();
}

class _AddWordPageState extends State<AddWordPage> {
  final _formKey = GlobalKey<FormState>();
  final wordController = TextEditingController();
  final meaningController = TextEditingController();
  final sentenceController = TextEditingController();
  final synonymController = TextEditingController();
  String? imagePath;
  List<String> selectedCategories = ['Uncategorized'];
  int selectedMastery = -1;
  final List<String> categories = [
    'Uncategorized',
    'Daily',
    'Travel',
    'Work & Study',
    'Special Topics',
  ];

  bool get _showAddPhotoPrompt =>
      imagePath == null ||
      imagePath!.isEmpty ||
      !(File(imagePath!).existsSync());

  @override
  void dispose() {
    wordController.dispose();
    meaningController.dispose();
    sentenceController.dispose();
    synonymController.dispose();
    super.dispose();
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
              leading: const Icon(Icons.camera_alt, color: Color(0xFF3B4FE0)),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                final picker = ImagePicker();
                final picked = await picker.pickImage(
                  source: ImageSource.camera,
                );
                if (picked != null) {
                  setState(() {
                    imagePath = picked.path;
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo, color: Color(0xFF3B4FE0)),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final picker = ImagePicker();
                final picked = await picker.pickImage(
                  source: ImageSource.gallery,
                );
                if (picked != null) {
                  setState(() {
                    imagePath = picked.path;
                  });
                }
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

  void _saveWord() {
    if (_formKey.currentState?.validate() ?? false) {
      final word = wordController.text.trim();
      final meaning = meaningController.text.trim();
      final category = selectedCategories.isNotEmpty
          ? selectedCategories
          : ['Uncategorized'];
      final mastery = selectedMastery;
      final sentence = sentenceController.text.trim();
      final synonym = synonymController.text.trim();
      // Save to favorites
      StatsService.addFavorite(
        word,
        meaning,
        manual: true,
        category: category,
        mastery: mastery,
      );
      // Save extra fields (sentence, synonym, image) using the same key as WordInfoPage
      final prefsKey = 'wordinfo_${word}_$meaning';
      StatsService.prefs.setStringList(prefsKey, [
        sentence,
        synonym,
        imagePath ?? '',
      ]);
      Navigator.pop(context, true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Word added to favorites!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add New Word',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF3B4FE0),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: wordController,
                decoration: const InputDecoration(
                  labelText: 'Word',
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? 'Please enter a word'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: meaningController,
                decoration: const InputDecoration(
                  labelText: 'Meaning',
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontSize: 16),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? 'Please enter a meaning'
                    : null,
              ),
              const SizedBox(height: 16),
              const Text(
                'Categories (Optional)',
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
                    selectedColor: const Color(0xFF3B4FE0).withOpacity(0.2),
                    checkmarkColor: const Color(0xFF3B4FE0),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mastery Level (Optional)',
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
                  labelText: 'Sample Sentence (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: synonymController,
                decoration: const InputDecoration(
                  labelText: 'Synonym (Optional)',
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
                  onPressed: _saveWord,
                  icon: const Icon(Icons.check),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B4FE0),
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
      ),
    );
  }
}
