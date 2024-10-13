from fastapi import FastAPI, File, UploadFile, HTTPException, BackgroundTasks
from pydantic import BaseModel
from typing import List, Dict
import requests
from faster_whisper import WhisperModel
from io import BytesIO
from audio_utils import save_audio, transcribe_audio, play_audio
from fastapi.responses import JSONResponse

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
        # Print response details for debugging
        print(f"Status Code: {response.status_code}, Response: {response.text}")
        response.raise_for_status()  # Raise exception for 4xx/5xx responses
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
    perplexity_api_key="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",
    elevenlabs_api_key="sk_b1fff0c19ff35a98f9eda239b78bcb00f9d1ea60f98eba0b",
    elevenlabs_voice_id="jsCqWAovK2LkecY7zXl4"
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

@app.get("/health/")
async def health_check():
    return {"status": "ok"}
    
@app.post("/speak/")
async def get_ai_response(request: UserInputRequest):
    """Get a response from the AI."""
    ai_response = app_state.send_to_perplexity(request.input_text)
    app_state.conversation_history.append({"user": request.input_text, "ai": ai_response})
    return {"response": ai_response}

#@app.post("/send_audio/")
#async def upload_audio(file: UploadFile = File(...), background_tasks: BackgroundTasks = BackgroundTasks()):
#    """Upload audio, transcribe it, and get AI response."""
#    try:
#        audio_path = save_audio(file)  # Save audio file locally
#        user_input = transcribe_audio(audio_path, app_state.whisper_model)  # Transcribe
#        ai_response = app_state.send_to_perplexity(user_input)  # AI Response
#
#        # Optionally, generate TTS and play audio in the background
#        audio_stream = app_state.tts_with_elevenlabs(ai_response)
#        background_tasks.add_task(play_audio, audio_stream)
#
#        return JSONResponse(content={"transcription": user_input, "response": ai_response})
#
#    except Exception as e:
#        raise HTTPException(status_code=500, detail=f"Error processing audio: {str(e)}")


func sendAudioAndPlayResponse() {
    guard let url = URL(string: "http://127.0.0.1:8000/send_audio/") else { return }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    
    // Set boundary for multipart form-data
    let boundary = "Boundary-\(UUID().uuidString)"
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

    // Load the audio file
    guard let audioURL = Bundle.main.url(forResource: "user_input", withExtension: "wav"),
          let audioData = try? Data(contentsOf: audioURL) else { return }

    // Create the multipart form body
    let body = createMultipartBody(audioData: audioData, boundary: boundary, filename: "user_input.wav")
    request.httpBody = body

    URLSession.shared.dataTask(with: request) { data, response, error in
        if let data = data,
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
           let responseText = json["response"] {
            print("AI Response: \(responseText)")
            speakResponse(responseText)
        } else if let error = error {
            print("Error: \(error.localizedDescription)")
        }
    }.resume()
}

// Helper function to create multipart form data
func createMultipartBody(audioData: Data, boundary: String, filename: String) -> Data {
    var body = Data()
    body.append("--\(boundary)\r\n".data(using: .utf8)!)
    body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
    body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
    body.append(audioData)
    body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
    return body
}

@State private var audioPlayer: AVAudioPlayer?  // Keep the player in scope

func playAudioFromData(_ data: Data) {
    do {
        audioPlayer = try AVAudioPlayer(data: data)  // Assign to @State
        audioPlayer?.prepareToPlay()
        audioPlayer?.play()
    } catch {
        print("Failed to play audio: \(error.localizedDescription)")
    }
}



