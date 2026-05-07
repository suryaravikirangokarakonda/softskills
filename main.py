import os
import io
import json
import re
import traceback
from supabase import create_client, Client
import soundfile as sf
import numpy as np
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.responses import StreamingResponse
from fastapi.middleware.cors import CORSMiddleware
from groq import Groq
from kittentts import KittenTTS

app = FastAPI(title="Local AI Communication Tutor")

# Add CORS middleware for Flutter Web
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["X-Response-Text", "X-User-Transcribed", "X-Score", "x-response-text", "x-user-transcribed", "x-score"]
)

# --- Initialization & Path Setup ---
# Required for KittenTTS to function in your Anaconda/Windows environment
os.environ['PHONEMIZER_ESPEAK_LIBRARY'] = r'C:\Program Files\eSpeak NG\libespeak-ng.dll'
os.environ['PHONEMIZER_ESPEAK_PATH'] = r'C:\Program Files\eSpeak NG'

print("⏳ Initializing local TTS (Kitten TTS)...")
try:
    # Local TTS helps students improve fluency and confidence
    tts_model = KittenTTS("KittenML/kitten-tts-nano-0.8")
    SELECTED_VOICE = "Jasper"
    print(f"✅ TTS Ready! Using voice: '{SELECTED_VOICE}'")
except Exception as e:
    print(f"❌ Failed to load TTS Model: {e}")
    tts_model = None

# Fetch Groq API key from environment variable
api_key = os.getenv("GROQ_API_KEY")
if not api_key:
    # Fallback for local testing if not using .env
    api_key = "gsk_replace_this_with_your_actual_key_in_env_file"

groq_client = Groq(api_key=api_key)
DB_FILE = "evaluations.json"

# --- Supabase Initialization ---
SUPABASE_URL = "https://ssktamuozmtzezgiqiql.supabase.co"
SUPABASE_KEY = "sb_publishable_K1CDZRWbcZ9Xz8bINwM0PQ_cf42NTaY"
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# --- Utility Functions ---

def sanitize_header(text: str) -> str:
    """Collapses newlines/tabs and enforces ASCII for safe HTTP transmission."""
    if not text or text.upper().strip() == "EMPTY": 
        return "Speech not detected"
    # Replace all whitespace (newlines, tabs, etc) with a single space
    clean = re.sub(r'\s+', ' ', text)
    # Strip non-ASCII characters to prevent protocol errors
    clean = clean.encode("ascii", "ignore").decode("ascii")
    return clean.strip()[:2000]

def clean_text_for_tts(text: str) -> str:
    """Removes symbols like * or [] that cause TTS engine glitches."""
    text = re.sub(r'[\*\_\(\)\[\]]', '', text)
    return text.replace("\n", ". ").strip()

def save_evaluation(user_id, module, facts):
    data = []
    if os.path.exists(DB_FILE) and os.path.getsize(DB_FILE) > 0:
        with open(DB_FILE, "r") as f:
            try: data = json.load(f)
            except: data = []
    
    data.append({"user_id": user_id, "module": module, "extracted_facts": facts})
    with open(DB_FILE, "w") as f:
        json.dump(data, f, indent=4)

def get_user_history(user_id, max_chars=800):
    """Returns recent history for a user, truncated to avoid token overflow."""
    if not os.path.exists(DB_FILE) or os.path.getsize(DB_FILE) == 0: return ""
    with open(DB_FILE, "r") as f:
        try:
            data = json.load(f)
            entries = [item["extracted_facts"] for item in data if item["user_id"] == user_id]
            # Only keep the most recent entries to avoid TPM limits
            history = "\n".join(entries[-5:])  # Last 5 entries only
            # Hard cap on characters (~200 tokens max)
            return history[-max_chars:] if len(history) > max_chars else history
        except: return ""

async def transcribe(audio_file):
    """Async transcription using Groq Whisper."""
    audio_bytes = await audio_file.read()
    return groq_client.audio.transcriptions.create(
        file=(audio_file.filename, audio_bytes),
        model="whisper-large-v3-turbo",
        response_format="text"
    ).strip()

def generate_audio(text):
    if tts_model is None: raise HTTPException(status_code=500, detail="TTS Offline")
    # Use clean text for TTS to ensure smooth speech generation
    audio_array = tts_model.generate(clean_text_for_tts(text), voice=SELECTED_VOICE) 
    wav_io = io.BytesIO()
    sf.write(wav_io, audio_array, 24000, format='WAV', subtype='PCM_16')
    wav_io.seek(0)
    return wav_io

# --- Endpoints ---

@app.post("/api/v1/module/assessment")
async def module_assessment(user_id: str = Form(...), audio: UploadFile = File(...)):
    try:
        text = await transcribe(audio)
        print(f"👤 User: {text}")
        # Truncate user text to avoid large prompts
        truncated_text = text[:500]
        prompt = "Analyze the user's English proficiency (vocabulary, grammar, confidence). Provide a 1-sentence encouraging summary."
        
        eval_resp = groq_client.chat.completions.create(
            model="llama-3.1-8b-instant",
            messages=[{"role": "system", "content": prompt}, {"role": "user", "content": truncated_text}],
            max_tokens=150
        ).choices[0].message.content
        print(f"🤖 AI: {eval_resp}")
        
        save_evaluation(user_id, "Assessment", f"User said: {text[:200]} | Evaluation: {eval_resp[:200]}")
        
        return StreamingResponse(
            generate_audio(eval_resp), 
            media_type="audio/wav", 
            headers={
                "X-Response-Text": sanitize_header(eval_resp),
                "X-User-Transcribed": sanitize_header(text)
            }
        )
    except Exception as e:
        err_str = str(e)
        print(f"❌ Error: {traceback.format_exc()}")
        if "rate_limit_exceeded" in err_str or "413" in err_str:
            raise HTTPException(status_code=429, detail="Rate limit reached. Please wait a moment and try again.")
        raise HTTPException(status_code=500, detail=err_str)

@app.post("/api/v1/module/vocab-sentence")
async def module_vocab(user_id: str = Form(...), word1: str = Form(""), word2: str = Form(""), audio: UploadFile = File(...)):
    try:
        text = await transcribe(audio)
        print(f"👤 User: {text}")
        # Truncate user text to avoid large prompts
        truncated_text = text[:400]
        vocab_text = word1 if not word2 else f"{word1}, {word2}"
        prompt = f"""
You are an AI evaluator for spoken English practice.

OBJECTIVE:
Improve vocabulary usage, structured sentence formation, speaking fluency, grammar accuracy, 
and soft skills chaining.

INPUT:
- Vocabulary Words: {vocab_text}
- Transcribed Speech: "{truncated_text}"

TASK REQUIREMENTS:
- The response must contain 3–4 connected sentences (30–60 words).
- Both vocabulary words must be used naturally (including inflections).
- Sentences must be logically connected (not isolated).
- Context must relate to soft skills (communication, teamwork, leadership, responsibility, etc.).
- Speech should be fluent and structured.

EVALUATION STEPS:

1. TRANSCRIBED RESPONSE:
Display the original text exactly.

2. POLISHED VERSION:
Rewrite the response:
- Fix grammar and structure
- Improve flow and clarity
- Make it sound confident and conversational

3. ERRORS:
List grammar or structure mistakes clearly.

4. WORD USAGE CHECK:
- Confirm both words are used
- Check if usage is natural
- If missing/misused, explain

5. SOFT SKILLS CHAINING:
- Check logical flow
- Suggest improvements if weak

6. SPEAKING CLARITY:
- Ignore fillers (um, uh, like)
- Identify incomplete sentences
- Suggest confident pauses instead of fillers

RATING RULES (STRICT):
- 3/3 → Excellent fluency, natural usage, strong chaining
- 2/3 → Minor issues OR wrong context
- 1/3 → Weak structure OR incorrect word usage
- 0/3 → Words missing or meaningless speech

CAP RULES:
- If BOTH words not used → max 1/3
- If <30 words → max 1/3
- If poor chaining → max 2/3
- If unrelated to soft skills → max 2/3

OUTPUT FORMAT (STRICT):

Transcribed:
<original text>

Polished:
<improved version>

Errors:
- ...

Word Usage:
- ...

Soft Skills Chaining:
- ...

Clarity Feedback:
- ...

Score: X/3
"""
        
        resp = groq_client.chat.completions.create(
            model="llama-3.1-8b-instant",
            messages=[{"role": "user", "content": prompt}],
            max_tokens=120
        ).choices[0].message.content
        print(f"🤖 AI: {resp}")
        
        save_evaluation(user_id, "Vocab/Grammar", resp[:300])
        return StreamingResponse(
            generate_audio(resp), 
            media_type="audio/wav", 
            headers={
                "X-Response-Text": sanitize_header(resp),
                "X-User-Transcribed": sanitize_header(text)
            }
        )
    except Exception as e:
        err_str = str(e)
        print(f"❌ Error: {traceback.format_exc()}")
        if "rate_limit_exceeded" in err_str or "413" in err_str:
            raise HTTPException(status_code=429, detail="Rate limit reached. Please wait a moment and try again.")
        raise HTTPException(status_code=500, detail=err_str)

@app.post("/api/v1/module/ai-interaction")
async def module_ai_chat(user_id: str = Form(...), audio: UploadFile = File(...)):
    try:
        text = await transcribe(audio)
        print(f"👤 User: {text}")
        # Truncate user text and history to stay well under the 6000 TPM limit
        truncated_text = text[:400]
        history = get_user_history(user_id, max_chars=600)  # ~150 tokens max for history
        system_prompt = "You are a friendly English tutor. Reply in 1-2 short sentences."
        if history:
            system_prompt += f" Context: {history}"
        
        resp = groq_client.chat.completions.create(
            model="llama-3.1-8b-instant",
            messages=[{"role": "system", "content": system_prompt}, {"role": "user", "content": truncated_text}],
            max_tokens=100  # Keep responses short to avoid TPM issues
        ).choices[0].message.content
        print(f"🤖 AI: {resp}")
        
        save_evaluation(user_id, "AI Chat", f"User: {text[:150]} | AI: {resp[:150]}")
        return StreamingResponse(
            generate_audio(resp), 
            media_type="audio/wav", 
            headers={
                "X-Response-Text": sanitize_header(resp),
                "X-User-Transcribed": sanitize_header(text)
            }
        )
    except Exception as e:
        err_str = str(e)
        print(f"❌ Error: {traceback.format_exc()}")
        if "rate_limit_exceeded" in err_str or "413" in err_str:
            raise HTTPException(status_code=429, detail="Rate limit reached. Please wait a moment and try again.")
        raise HTTPException(status_code=500, detail=err_str)

@app.post("/api/v1/assessment/evaluate")
async def evaluate_assessment(
    user_id: str = Form(...), 
    module_type: str = Form(...), # 'sentence_formation', 'image_description', or 'confidence_check'
    context: str = Form(""),       # Target words or the image topic
    audio: UploadFile = File(...),
    second_audio: UploadFile = File(None)
):
    try:
        print(f"📥 Evaluation Request: User={user_id}, Module={module_type}")
        
        # 1. Transcribe the User's audios
        text1 = await transcribe(audio)
        text2 = await transcribe(second_audio) if second_audio else ""
        
        full_text = f"{text1} {text2}".strip()
        print(f"👤 Combined User Text: {full_text}")
        
        # 2. Select Dynamic Prompt based on the module
        if module_type == "sentence_formation":
            system_prompt = f"You are an English tutor. The user had to use these words: {context}. Evaluate their sentence formation, grammar, and pronunciation. User said: {full_text}"
        elif module_type == "image_description":
            system_prompt = f"You are an English tutor. The user is describing an image about: {context}. Evaluate their description quality and vocabulary. User said: {full_text}"
        else: # confidence_check
            system_prompt = f"You are an English tutor. The user is speaking about: {context}. Evaluate their confidence, fluency, and expression. User said: {full_text}"

        ai_resp = groq_client.chat.completions.create(
            model="llama-3.1-8b-instant",
            messages=[
                {"role": "system", "content": system_prompt + " Format the reply exactly like this: Score: X/10 | Feedback: [Your feedback]"},
                {"role": "user", "content": full_text}
            ],
            max_tokens=150
        ).choices[0].message.content
        
        print(f"🤖 AI Result: {ai_resp}")

        # 3. Parse Result
        score_match = re.search(r"Score:\s*(\d+)", ai_resp)
        score = int(score_match.group(1)) if score_match else 5
        feedback = ai_resp.split("|")[-1].replace("Feedback:", "").strip()

        # 4. Save to Database
        column_map = {
            "sentence_formation": "sentence_formation_score",
            "image_description": "image_narration_score",
            "confidence_check": "ai_interaction_score"
        }
        col_name = column_map.get(module_type)
        if col_name:
            try:
                # Check if row exists for this user
                existing = supabase.table("user_performance_history").select("id").eq("user_id", user_id).execute()
                
                if existing.data:
                    # Update existing row
                    supabase.table("user_performance_history").update({col_name: score}).eq("user_id", user_id).execute()
                    print(f"✅ Updated score for {user_id} in {col_name}")
                else:
                    # Insert new row
                    supabase.table("user_performance_history").insert({"user_id": user_id, col_name: score}).execute()
                    print(f"✅ Created new performance record for {user_id}")
                    
            except Exception as e:
                print(f"❌ DB Save Error: {e}")

        # 5. Return spoken AI feedback
        return StreamingResponse(
            generate_audio(feedback), 
            media_type="audio/wav", 
            headers={
                "X-Response-Text": sanitize_header(feedback),
                "X-User-Transcribed": sanitize_header(full_text),
                "X-Score": str(score),
                "Access-Control-Expose-Headers": "X-Response-Text, X-User-Transcribed, X-Score"
            }
        )
    except Exception as e:
        print(f"❌ Evaluation Error: {traceback.format_exc()}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/v1/module/feedback")
async def module_feedback(user_id: str):
    history = get_user_history(user_id, max_chars=1000)
    if not history: return {"feedback_report": "No data found for this user."}
    
    try:
        report = groq_client.chat.completions.create(
            model="llama-3.1-8b-instant",
            messages=[
                {"role": "system", "content": "Write a short 3-sentence coaching report on progress and areas to improve."},
                {"role": "user", "content": history}
            ],
            max_tokens=200
        ).choices[0].message.content
        return {"feedback_report": report}
    except Exception as e:
        err_str = str(e)
        if "rate_limit_exceeded" in err_str or "413" in err_str:
            raise HTTPException(status_code=429, detail="Rate limit reached. Please wait a moment and try again.")
        raise HTTPException(status_code=500, detail=err_str)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)