from fastapi import FastAPI, File, UploadFile, HTTPException, BackgroundTasks
from pydantic import BaseModel
from typing import List, Dict
import requests
from faster_whisper import WhisperModel
from io import BytesIO
from audio_utils import save_audio, transcribe_audio, play_audio

# Initialize FastAPI app
app = FastAPI()

class VirtualDateApp:
    def __init__(self, perplexity_api_key: str, elevenlabs_api_key: str, elevenlabs_voice_id: str, whisper_model_size='base'):
        self.perplexity_api_key = perplexity_api_key
        self.elevenlabs_api_key = elevenlabs_api_key
        self.elevenlabs_voice_id = elevenlabs_voice_id
        self.conversation_history: List[Dict[str, str]] = []
        self.persona_style_guide = None

        # Whisper model setup
        self.whisper_model = WhisperModel(
            whisper_model_size, device="cpu", compute_type="int8"
        )

    def set_persona_style(self, style_text: str):
        # Generate style guide using Perplexity API
        prompt = f"Analyze this text: {style_text}. Create a style guide."
        self.persona_style_guide = self.send_to_perplexity(prompt)

    def send_to_perplexity(self, user_input: str) -> str:
        url = "https://api.perplexity.ai/chat/completions"
        payload = {
            "model": "llama-3.1-sonar-small-128k-online",
            "messages": [{"role": "user", "content": user_input}],
            "temperature": 0.7,
        }
        headers = {"Authorization": f"Bearer {self.perplexity_api_key}"}
        response = requests.post(url, json=payload, headers=headers)
        response.raise_for_status()
        return response.json()["choices"][0]["message"]["content"]

    def tts_with_elevenlabs(self, text: str) -> BytesIO:
        url = f"https://api.elevenlabs.io/v1/text-to-speech/{self.elevenlabs_voice_id}"
        headers = {
            "xi-api-key": self.elevenlabs_api_key,
            "Content-Type": "application/json",
            "Accept": "audio/mpeg"
        }
        data = {"text": text, "voice_settings": {"stability": 0.75}}
        response = requests.post(url, json=data, headers=headers)
        if response.status_code == 200:
            return BytesIO(response.content)
        else:
            raise HTTPException(status_code=500, detail="TTS generation failed")

# Initialize the VirtualDateApp instance
app_state = VirtualDateApp(
    perplexity_api_key="your-perplexity-api-key",
    elevenlabs_api_key="your-elevenlabs-api-key",
    elevenlabs_voice_id="your-voice-id"
)

# Request models
class PersonaRequest(BaseModel):
    style_text: str

class UserInputRequest(BaseModel):
    input_text: str

@app.post("/set_persona_style/")
async def set_persona_style(request: PersonaRequest):
    """Set the AI's persona style."""
    app_state.set_persona_style(request.style_text)
    return {"message": "Persona style set successfully"}

@app.post("/get_response/")
async def get_ai_response(request: UserInputRequest):
    """Get a response from the AI."""
    ai_response = app_state.send_to_perplexity(request.input_text)
    app_state.conversation_history.append({"user": request.input_text, "ai": ai_response})
    return {"response": ai_response}

@app.post("/upload_audio/")
async def upload_audio(file: UploadFile = File(...), background_tasks: BackgroundTasks = BackgroundTasks()):
    """Upload audio, transcribe it, and get AI response."""
    audio_path = save_audio(file)
    user_input = transcribe_audio(audio_path, app_state.whisper_model)
    ai_response = app_state.send_to_perplexity(user_input)

    # Optionally, generate TTS audio and play it in the background
    audio_stream = app_state.tts_with_elevenlabs(ai_response)
    background_tasks.add_task(play_audio, audio_stream)

    return {"transcription": user_input, "response": ai_response}

