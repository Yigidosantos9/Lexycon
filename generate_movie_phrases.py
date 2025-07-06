import json
import random
import openai
from typing import List, Dict
import os

# Configuration
OUTPUT_FILE = "assets/movie_phrases.json"
PHRASES_COUNT = 100  # Number of phrases to generate

# Set up OpenAI client
client = openai.OpenAI(api_key=os.getenv('OPENAI_API_KEY'))

# Try to set up Google Translate client (optional)
translate_client = None
try:
    from google.cloud import translate_v2 as translate
    translate_client = translate.Client()
    print("Google Translate API available")
except Exception as e:
    print(f"Google Translate API not available: {e}")
    print("Will use fallback phrases with Turkish meanings")

def translate_to_turkish(text: str) -> str:
    """
    Translate text to Turkish using Google Translate
    """
    if translate_client is None:
        # If no translation service, return original text
        return text
    
    try:
        result = translate_client.translate(text, target_language="tr")
        return result["translatedText"].lower()
    except Exception as e:
        print(f"Translation error: {e}")
        return text  # Return original text if translation fails

def generate_movie_phrases(count: int) -> List[Dict[str, str]]:
    """
    Generate famous movie phrases using OpenAI API
    """
    system_prompt = """
    You are a helpful assistant that generates famous movie phrases for English learning.
    For each phrase, provide:
    1. The exact phrase as spoken in the movie (in English)
    2. A clear, simple meaning/explanation in English (this will be translated to Turkish)
    3. The movie title and year
    
    Format each response as a JSON object with:
    - "phrase": the exact movie quote (in English)
    - "meaning": simple explanation of what it means (in English - will be translated)
    - "movie": "Movie Title (Year)"
    
    Make sure phrases are:
    - Memorable and well-known
    - Appropriate for English learners
    - From different genres and time periods
    - Not too complex or obscure
    - Meanings should be simple and clear for translation
    """
    
    phrases = []
    
    # Generate phrases in batches to avoid rate limits
    batch_size = 10
    for i in range(0, count, batch_size):
        current_batch = min(batch_size, count - i)
        
        user_prompt = f"""
        Generate {current_batch} famous movie phrases for English learning.
        Return only a JSON array of objects, no other text.
        Each object should have: "phrase", "meaning", "movie"
        - "phrase": exact movie quote in English
        - "meaning": simple explanation in English (will be translated to Turkish)
        - "movie": movie title and year
        """
        
        try:
            response = client.chat.completions.create(
                model="gpt-3.5-turbo",
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt}
                ],
                temperature=0.7,
                max_tokens=1000
            )
            
            # Parse the response
            content = response.choices[0].message.content
            if content is None:
                print(f"Empty response for batch {i//batch_size + 1}, using fallback")
                phrases.extend(generate_fallback_phrases(current_batch))
                continue
                
            content = content.strip()
            
            # Try to extract JSON from the response
            if content.startswith('[') and content.endswith(']'):
                batch_phrases = json.loads(content)
                
                # Translate meanings to Turkish (if translation service is available)
                for phrase in batch_phrases:
                    if 'meaning' in phrase:
                        phrase['meaning'] = translate_to_turkish(phrase['meaning'])
                
                phrases.extend(batch_phrases)
            else:
                # Fallback: generate some default phrases
                print(f"Failed to parse response for batch {i//batch_size + 1}, using fallback")
                phrases.extend(generate_fallback_phrases(current_batch))
                
        except Exception as e:
            print(f"Error generating batch {i//batch_size + 1}: {e}")
            # Use fallback phrases
            phrases.extend(generate_fallback_phrases(current_batch))
    
    return phrases[:count]

def generate_fallback_phrases(count: int) -> List[Dict[str, str]]:
    """
    Generate fallback phrases when AI is not available
    """
    fallback_phrases = [
        {
            "phrase": "May the Force be with you",
            "meaning": "iyi şanslar veya en iyi dilekler",
            "movie": "Star Wars (1977)"
        },
        {
            "phrase": "Here's looking at you, kid",
            "meaning": "bir kadeh kaldırma veya dostane selamlama",
            "movie": "Casablanca (1942)"
        },
        {
            "phrase": "I'll be back",
            "meaning": "geri döneceğim",
            "movie": "The Terminator (1984)"
        },
        {
            "phrase": "Life is like a box of chocolates",
            "meaning": "hayat öngörülemeyen ve sürprizlerle dolu",
            "movie": "Forrest Gump (1994)"
        },
        {
            "phrase": "You had me at hello",
            "meaning": "en başından beri ikna olmuştum",
            "movie": "Jerry Maguire (1996)"
        },
        {
            "phrase": "Houston, we have a problem",
            "meaning": "ciddi bir sorunla karşılaştık",
            "movie": "Apollo 13 (1995)"
        },
        {
            "phrase": "I see dead people",
            "meaning": "başkalarının göremediği şeyleri görebiliyorum",
            "movie": "The Sixth Sense (1999)"
        },
        {
            "phrase": "There's no place like home",
            "meaning": "ev en iyi ve en rahat yerdir",
            "movie": "The Wizard of Oz (1939)"
        },
        {
            "phrase": "I'm the king of the world",
            "meaning": "güçlü ve yenilmez hissediyorum",
            "movie": "Titanic (1997)"
        },
        {
            "phrase": "Keep your friends close, but your enemies closer",
            "meaning": "düşmanlarınızı dikkatle izleyin",
            "movie": "The Godfather Part II (1974)"
        }
    ]
    
    # Return random selection from fallback phrases
    return random.sample(fallback_phrases, min(count, len(fallback_phrases)))

def main():
    print("Generating movie phrases...")
    
    # Check if OpenAI API key is available
    if not os.getenv('OPENAI_API_KEY'):
        print("No OpenAI API key found. Using fallback phrases...")
        phrases = generate_fallback_phrases(PHRASES_COUNT)
    else:
        try:
            # Try to generate phrases with AI
            phrases = generate_movie_phrases(PHRASES_COUNT)
            print(f"Generated {len(phrases)} phrases using AI")
        except Exception as e:
            print(f"AI generation failed: {e}")
            print("Using fallback phrases...")
            phrases = generate_fallback_phrases(PHRASES_COUNT)
    
    # Save to file
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(phrases, f, ensure_ascii=False, indent=2)
    
    print(f"Done! Saved {len(phrases)} phrases to {OUTPUT_FILE}")
    
    # Print a few examples
    print("\nExample phrases:")
    for i, phrase in enumerate(phrases[:3]):
        print(f"{i+1}. '{phrase['phrase']}' - {phrase['meaning']} ({phrase['movie']})")

if __name__ == "__main__":
    main() 