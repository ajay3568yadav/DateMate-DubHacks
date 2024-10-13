import wave
from pydub import AudioSegment
from pydub.playback import play
import requests
from typing import List, Dict
import pyaudio
import os
from io import BytesIO  # To handle audio in memory
from faster_whisper import WhisperModel

class VirtualDateApp:
    def __init__(self, perplexity_api_key: str, elevenlabs_api_key: str, elevenlabs_voice_id: str, whisper_model_size='base'):
        self.perplexity_api_key = perplexity_api_key
        self.elevenlabs_api_key = elevenlabs_api_key
        self.elevenlabs_voice_id = elevenlabs_voice_id  # Voice ID for ElevenLabs TTS
        self.conversation_history: List[Dict[str, str]] = []
        self.ai_persona = {
            "name": "Alex",
            "age": 28,
            "interests": ["hiking", "cooking", "movies"],
            "personality": "friendly and outgoing",
        }
        self.persona_style_guide = None

        # Set up Whisper model
        num_cores = os.cpu_count()
        self.whisper_model = WhisperModel(
            whisper_model_size,
            device='cpu',
            compute_type='int8',
            cpu_threads=num_cores // 2,
            num_workers=num_cores // 2
        )

        # Set up audio input
        self.audio = pyaudio.PyAudio()
        self.source = self.audio.open(format=pyaudio.paInt16, channels=1, rate=16000, input=True, frames_per_buffer=4096)
        print("Microphone initialized.")

    def set_persona_style(self, style_text: str):
        style_prompt = f"""
        Analyze the following text and use it to create a comprehensive style guide for an AI persona. 
        The guide should cover tone, vocabulary, sentence structure, and any unique characteristics of the writing style.
        This style guide will be used to shape all future responses of the AI persona.

        Text to analyze: {style_text}

        Create a detailed style guide based on this analysis.
        """
        self.persona_style_guide = self.send_to_perplexity(style_prompt)
        print("Persona style has been set.")

    def start_date(self):
        if not self.persona_style_guide:
            print("Error: Persona style has not been set. Please set the style before starting the date.")
            return

        print("Welcome to your virtual date!")
        print(f"You're now chatting with {self.ai_persona['name']}. Say 'exit' or 'quit' to end the date.")

        while True:
            # Listen for user input AFTER AI is done speaking
            user_input = self.listen_to_voice()

            if user_input.lower() in ["exit", "quit"]:
                print("Ending the date. Goodbye!")
                break

            # Get AI response and print text immediately
            ai_response = self.send_to_perplexity(user_input)
            print(f"{self.ai_persona['name']}: {ai_response}")
            self.conversation_history.append({"user": user_input, "ai": ai_response})

            # Play the AI response (wait for playback to finish before continuing)
            self.speak(ai_response)

    def send_to_perplexity(self, user_input: str, depth: int = 0, max_depth: int = 2) -> str:
        if depth > max_depth:
            return "Sorry, I couldn't complete my response."

        url = "https://api.perplexity.ai/chat/completions"
        
        messages = self._prepare_messages(user_input)

        payload = {
            "model": "llama-3.1-sonar-small-128k-online",
            "messages": messages,
            "max_tokens": 150,  # Adjust if needed
            "temperature": 0.7,
            "top_p": 0.9,
            "return_citations": True,
            "search_domain_filter": ["perplexity.ai"],
            "return_images": False,
            "return_related_questions": False,
            "search_recency_filter": "month",
            "top_k": 0,
            "stream": False,
            "presence_penalty": 0,
            "frequency_penalty": 1
        }
        
        headers = {
            "Authorization": f"Bearer {self.perplexity_api_key}",
            "Content-Type": "application/json"
        }
        
        try:
            response = requests.post(url, json=payload, headers=headers)
            response.raise_for_status()
            response_content = response.json()["choices"][0]["message"]["content"]

            if response_content.endswith((".", "!", "?")):
                return response_content
            else:
                continuation = self.send_to_perplexity("Please continue your previous response.", depth + 1, max_depth)
                return response_content + " " + continuation
            
        except requests.RequestException as e:
            print(f"Error calling Perplexity API: {e}")
            return "I'm sorry, I'm having trouble responding right now."

    def _prepare_messages(self, user_input: str) -> List[Dict[str, str]]:
        system_message = f"""
        You are {self.ai_persona['name']}, a {self.ai_persona['age']}-year-old virtual date. 
        You are {self.ai_persona['personality']} and interested in {', '.join(self.ai_persona['interests'])}. 
        Engage in a flirtatious yet respectful conversation.

        Adhere to the following style guide in all your responses:
        {self.persona_style_guide}
        """
        
        messages = [{"role": "system", "content": system_message}]
        
        for entry in self.conversation_history[-5:]:
            messages.append({"role": "user", "content": entry["user"]})
            messages.append({"role": "assistant", "content": entry["ai"]})
        
        messages.append({"role": "user", "content": user_input})
        
        return messages

    def listen_to_voice(self):
        print("Listening for your input...")
        frames = []

        try:
            # Capture audio data for 5 seconds
            for _ in range(0, int(16000 / 4096 * 5)):
                data = self.source.read(4096, exception_on_overflow=False)  # Adjusted buffer size and added the exception handler
                frames.append(data)

            # Save the audio data as a WAV file using the wave module
            with wave.open("user_input.wav", "wb") as wf:
                wf.setnchannels(1)
                wf.setsampwidth(self.audio.get_sample_size(pyaudio.paInt16))
                wf.setframerate(16000)
                wf.writeframes(b''.join(frames))

            print("Audio captured, now transcribing...")

            # Transcribe the audio using Whisper
            return self.wav_to_text("user_input.wav")

        except IOError as e:
            print(f"Audio input overflow: {e}")
            return None

    def wav_to_text(self, audio_path):
        segments, _ = self.whisper_model.transcribe(audio_path)
        text = ''.join(segment.text for segment in segments)
        print(f"Transcribed text: {text}")  # Print the transcribed text for debugging
        return text

    def speak(self, text: str):
        # Use ElevenLabs API for text-to-speech
        url = f"https://api.elevenlabs.io/v1/text-to-speech/{self.elevenlabs_voice_id}"
        headers = {
            "Accept": "audio/mpeg",
            "Content-Type": "application/json",
            "xi-api-key": self.elevenlabs_api_key
        }
        data = {
            "text": text,
            "voice_settings": {
                "stability": 0.75,
                "similarity_boost": 0.75
            }
        }
        
        response = requests.post(url, json=data, headers=headers)

        if response.status_code == 200:
            # Stream the audio content in memory instead of saving it
            audio_content = BytesIO(response.content)

            # Play the audio directly from memory using pydub
            audio = AudioSegment.from_file(audio_content, format="mp3")
            print("AI response streaming as audio.")
            self.play_audio(audio)
        else:
            print(f"Error with TTS API: {response.status_code}, {response.text}")

    def play_audio(self, audio):
        # Play the MP3 file directly from memory using pydub
        play(audio)

if __name__ == "__main__":
    # Replace 'your_elevenlabs_api_key' with your actual ElevenLabs API key
    elevenlabs_api_key = "sk_b1fff0c19ff35a98f9eda239b78bcb00f9d1ea60f98eba0b"
    
    # Replace 'your_voice_id' with the actual voice ID you want to use
    elevenlabs_voice_id = "jsCqWAovK2LkecY7zXl4"
    
    # Initialize the VirtualDateApp with your API key and voice ID
    app = VirtualDateApp(
        perplexity_api_key="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", 
        elevenlabs_api_key=elevenlabs_api_key, 
        elevenlabs_voice_id=elevenlabs_voice_id
    )
    
    # Set the persona style before starting the date
    app.set_persona_style("Friendly and outgoing, enjoys casual conversations, uses simple sentences.")
    
    # Start the virtual date
    app.start_date()
