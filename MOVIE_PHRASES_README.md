# Movie Phrases Generator

This feature allows you to generate famous movie phrases using AI for English learning purposes.

## Features

- **AI-Generated Phrases**: Uses OpenAI API to generate famous movie quotes
- **Movie Information**: Each phrase includes the movie title and year
- **Meaning Explanations**: Simple explanations suitable for English learners
- **Fallback System**: Includes pre-defined phrases when AI is unavailable
- **Easy Management**: Add, view, and delete movie phrases in the app

## Setup Instructions

### 1. Install Python Dependencies

```bash
pip install -r requirements.txt
```

### 2. Set Up OpenAI API Key

You have two options:

#### Option A: Environment Variable (Recommended)
```bash
export OPENAI_API_KEY="your-api-key-here"
```

#### Option B: Direct in Script
Edit `generate_movie_phrases.py` and uncomment this line:
```python
openai.api_key = "your-api-key-here"
```

### 3. Generate Movie Phrases

```bash
python generate_movie_phrases.py
```

This will:
- Generate 100 movie phrases using AI (if API key is available)
- Fall back to pre-defined phrases if AI fails
- Save results to `assets/movie_phrases.json`

### 4. Use in Flutter App

The Flutter app will automatically load movie phrases from the JSON file. You can also:
- Add movie phrases manually using the "Add Movie Phrase" button
- View all movie phrases in the "Movie Phrases" section
- Delete phrases you don't want to keep

## Configuration

### Number of Phrases
Edit `PHRASES_COUNT` in `generate_movie_phrases.py` to change how many phrases are generated.

### AI Model
The script uses `gpt-3.5-turbo` by default. You can change this in the script.

### Batch Size
Phrases are generated in batches of 10 to avoid rate limits. Adjust `batch_size` if needed.

## Sample Output

```json
[
  {
    "phrase": "May the Force be with you",
    "meaning": "Good luck or best wishes",
    "movie": "Star Wars (1977)"
  },
  {
    "phrase": "Here's looking at you, kid",
    "meaning": "A toast or friendly greeting",
    "movie": "Casablanca (1942)"
  }
]
```

## App Features

### Movie Phrases Page
- Displays all movie phrases with movie information
- Text-to-speech functionality
- Delete individual phrases
- Empty state when no phrases exist

### Add Movie Phrase Dialog
- Modern, user-friendly interface
- Form validation
- Three fields: phrase, meaning, and movie
- Purple theme matching the movie phrases section

### Integration
- Separate from regular phrases
- Persistent storage using SharedPreferences
- Consistent with app's design language

## Troubleshooting

### AI Generation Fails
- Check your OpenAI API key
- Ensure you have sufficient API credits
- The script will automatically fall back to pre-defined phrases

### No Phrases Appear
- Check that `assets/movie_phrases.json` exists
- Verify the JSON format is correct
- Try adding phrases manually first

### App Crashes
- Check that all imports are correct
- Verify the StatsService methods exist
- Ensure the movie phrases page is properly imported

## Future Enhancements

- Quiz mode for movie phrases
- Categories by movie genre
- Audio clips from movies
- Difficulty levels
- User ratings for phrases 