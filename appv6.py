import os
import io
import torch
import sounddevice as sd
import soundfile as sf
import numpy as np
from groq import Groq 
from kittentts import KittenTTS 

# ==========================================
# 1. INITIALIZATION & SETUP
# ==========================================
print("⏳ Initializing local VAD (Silero)...")
vad_model, _ = torch.hub.load(
    repo_or_dir='snakers4/silero-vad',
    model='silero_vad',
    force_reload=False,
    trust_repo=True
)
vad_model.eval()

print("⏳ Initializing Cloud Services (Groq LLM & Whisper API)...")
api_key = os.getenv("GROQ_API_KEY")
if not api_key:
    # Use a dummy placeholder for the git commit
    api_key = "gsk_placeholder_for_security"

groq_client = Groq(api_key=api_key)

print("⏳ Initializing local TTS (Kitten TTS)...")
tts_model = KittenTTS("KittenML/kitten-tts-nano-0.8")

# ==========================================
# 2. VOICE ACTIVITY DETECTION (SILERO)
# ==========================================
def record_until_silence(sample_rate=16000, silence_duration=1.2, speech_threshold=0.5):
    chunk_size = 512 
    audio_data = []
    
    print(f"\n🎙️ Listening... (Silence timeout: {silence_duration}s)")
    
    with sd.InputStream(samplerate=sample_rate, channels=1, dtype='float32') as stream:
        while True:
            chunk, _ = stream.read(chunk_size)
            tensor_chunk = torch.from_numpy(chunk.flatten())
            
            speech_prob = vad_model(tensor_chunk, sample_rate).item()
            
            if speech_prob > speech_threshold:
                audio_data.append(chunk)
                print("🗣️ Speech detected! Recording...")
                break
                
        silence_chunks = 0
        max_silence_chunks = int((sample_rate / chunk_size) * silence_duration)
        
        while True:
            chunk, _ = stream.read(chunk_size)
            audio_data.append(chunk)
            tensor_chunk = torch.from_numpy(chunk.flatten())
            speech_prob = vad_model(tensor_chunk, sample_rate).item()
            
            if speech_prob < (speech_threshold - 0.15):
                silence_chunks += 1
            else:
                silence_chunks = 0 
                
            if silence_chunks > max_silence_chunks:
                print("✅ Silence detected. Processing...")
                break
                
    return np.concatenate(audio_data).flatten()

# ==========================================
# 3. PROMPT TEMPLATES (Highly Optimized)
# ==========================================
PROMPT_FAST_MODE = """You are an English communication tutor acting like a friend. 
The user is having a fast, back-to-back conversation with you.
RULES:
1. Reply in EXACTLY one short sentence.
2. Do NOT correct grammar or spelling mistakes. 
3. Just respond naturally to what the user said to keep the conversation moving instantly."""

PROMPT_STORY_FEEDBACK = """The user just told a story to practice their English.
RULES:
1. Reply in EXACTLY one short sentence.
2. Only state if the story was "Good", "Average", or "Bad".
3. Add a brief 3-4 word reason (e.g., "Good, very clear pronunciation" or "Average, lacked emotional tone").
4. Do NOT give any other feedback, corrections, or ask follow-up questions."""

# ==========================================
# 4. MAIN APPLICATION LOOP
# ==========================================
def main():
    chat_history = []
    current_mode = "fast" 

    print("\n🚀 App is ready!")
    print("Commands:")
    print("- Say 'Let me tell you a story' to enter Story Mode.")
    print("- Say 'I am done' to manually finish your story early.")
    print("- Say 'Goodbye' or 'Stop' to exit.")

    while True:
        try:
            silence_timeout = 2.5 if current_mode == "story" else 1.2
            
            user_audio = record_until_silence(silence_duration=silence_timeout)
            
            if len(user_audio) == 0:
                continue
                
            # --- NEW GROQ WHISPER STT LOGIC ---
            # Convert raw numpy audio into an in-memory WAV file for Groq API
            wav_io = io.BytesIO()
            sf.write(wav_io, user_audio, 16000, format='WAV', subtype='PCM_16')
            wav_io.seek(0)
            
            # Send to Groq's whisper-large-v3-turbo for instant transcription
            transcription = groq_client.audio.transcriptions.create(
                file=("audio.wav", wav_io.read()),
                model="whisper-large-v3-turbo",
                language="en",
                response_format="text"
            )
            
            user_text = transcription.strip()
            # ----------------------------------
            
            if not user_text:
                continue
                
            print(f"👤 You: {user_text}")

            if "goodbye" in user_text.lower() or "stop" in user_text.lower():
                print("👋 Ending session. Have a great day!")
                break

            if "tell you a story" in user_text.lower():
                current_mode = "story"
                print("🔄 Switched to STORY MODE. Take your time, I'm listening...")
                continue
                
            if current_mode == "story" and "i'm done" in user_text.lower():
                user_text = user_text.replace("i'm done", "").replace("I am done", "").strip()

            chat_history.append({"role": "user", "content": user_text})
            active_prompt = PROMPT_STORY_FEEDBACK if current_mode == "story" else PROMPT_FAST_MODE
            messages = [{"role": "system", "content": active_prompt}] + chat_history
            
            print("⏳ Thinking...")
            chat_response = groq_client.chat.completions.create(
                model="llama-3.1-8b-instant", 
                messages=messages,
                stream=False 
            )
            
            tutor_reply = chat_response.choices[0].message.content
            print(f"🤖 Tutor: {tutor_reply}")
            
            chat_history.append({"role": "assistant", "content": tutor_reply})

            # Process with Kitten TTS
            audio_output = tts_model.generate(tutor_reply, voice='Jasper')
            sd.play(audio_output, samplerate=24000)
            sd.wait() 

            if current_mode == "story":
                current_mode = "fast"
                print("\n🔄 Switched back to FAST MODE.")

        except Exception as e:
            print(f"\n❌ An error occurred: {e}")
            break

if __name__ == "__main__":
    main()