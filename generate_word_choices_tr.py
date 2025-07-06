import json
import random
from google.cloud import translate_v2 as translate

WORDS_FILE = "assets/words_1000.json"
OUTPUT_FILE = "assets/word_choices_tr.json"

def is_verb(word):
    # In Turkish, verbs often end with 'mak' or 'mek'
    return word.endswith("mak") or word.endswith("mek")

def main():
    # Load words
    with open(WORDS_FILE, "r", encoding="utf-8") as f:
        words = json.load(f)

    # Set up Google Translate client
    translate_client = translate.Client()

    # Translate all words to Turkish (lowercase)
    print("Translating words to Turkish...")
    translations = {}
    for word in words:
        result = translate_client.translate(word, target_language="tr")
        translations[word] = result["translatedText"].lower()

    # Build word_choices_tr.json
    print("Building word_choices_tr.json...")
    word_choices = {}
    all_tr = list(translations.values())
    for word in words:
        correct = translations[word]
        # Try to find similar distractors (same suffix)
        if is_verb(correct):
            candidates = [w for w in all_tr if is_verb(w) and w != correct]
        else:
            candidates = [w for w in all_tr if not is_verb(w) and w != correct]
        # If not enough, fill with randoms
        while len(candidates) < 3:
            extra = random.choice(all_tr)
            if extra != correct and extra not in candidates:
                candidates.append(extra)
        distractors = random.sample(candidates, 3)
        word_choices[word] = {
            "translation": correct,
            "options": distractors
        }

    # Save to file
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(word_choices, f, ensure_ascii=False, indent=2)

    print(f"Done! Saved to {OUTPUT_FILE}")

if __name__ == "__main__":
    main()