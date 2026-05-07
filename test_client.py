import torch
import sounddevice as sd
import soundfile as sf
import numpy as np
import requests
import io

API_URL = "http://localhost:8000/api/v1/module"
USER_ID = "win_conda_user_01"

print("⏳ Initializing VAD (Silero)...")
vad_model, _ = torch.hub.load(repo_or_dir='snakers4/silero-vad', model='silero_vad', trust_repo=True)
vad_model.eval()

def record_speech(sample_rate=16000, silence_limit=1.5):
    audio_data = []
    print("\n🎙️ Listening...")
    with sd.InputStream(samplerate=sample_rate, channels=1, dtype='float32') as stream:
        while True:
            chunk, _ = stream.read(512)
            if vad_model(torch.from_numpy(chunk.flatten()), sample_rate).item() > 0.5:
                audio_data.append(chunk)
                break
        silence_count = 0
        while silence_count < int((sample_rate / 512) * silence_limit):
            chunk, _ = stream.read(512)
            audio_data.append(chunk)
            if vad_model(torch.from_numpy(chunk.flatten()), sample_rate).item() < 0.35:
                silence_count += 1
            else:
                silence_count = 0
    return np.concatenate(audio_data).flatten()

def run_audio_module(endpoint):
    print(f"\n--- {endpoint.upper()} MODE (Ctrl+C to go back) ---")
    while True:
        try:
            audio = record_speech()
            wav_io = io.BytesIO()
            sf.write(wav_io, audio, 16000, format='WAV', subtype='PCM_16')
            wav_io.seek(0)
            
            print("⏳ Server is processing...")
            r = requests.post(f"{API_URL}/{endpoint}", files={'audio': ('audio.wav', wav_io)}, data={'user_id': USER_ID})
            
            if r.status_code == 200:
                # Text is pulled from the sanitized header
                print(f"🤖 AI: {r.headers.get('X-Response-Text')}")
                data, fs = sf.read(io.BytesIO(r.content))
                sd.play(data, fs); sd.wait()
            else:
                print(f"❌ Error: {r.text}")
        except KeyboardInterrupt:
            break

if __name__ == "__main__":
    while True:
        print("\n=== English Communication Tutor ===")
        print("1: Assessment | 2: Vocab Polish | 3: AI Interaction | 4: Coach Report | 5: Exit")
        choice = input("Select: ")
        
        if choice == "1": run_audio_module("assessment")
        elif choice == "2": run_audio_module("vocab-sentence")
        elif choice == "3": run_audio_module("ai-interaction")
        elif choice == "4":
            print("⏳ Generating Report...")
            r = requests.get(f"{API_URL}/feedback", params={"user_id": USER_ID})
            print("\n📝 YOUR PROGRESS REPORT:\n", r.json().get("feedback_report"))
        elif choice == "5":
            break