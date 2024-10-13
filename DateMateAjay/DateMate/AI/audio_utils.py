import wave
from io import BytesIO
from pydub import AudioSegment, playback

def save_audio(file) -> str:
    """Save uploaded audio file."""
    audio_path = f"uploads/{file.filename}"
    with open(audio_path, "wb") as f:
        f.write(file.file.read())
    return audio_path

def transcribe_audio(audio_path: str, whisper_model) -> str:
    """Transcribe audio using Whisper."""
    segments, _ = whisper_model.transcribe(audio_path)
    return ''.join(segment.text for segment in segments)

def play_audio(audio_stream: BytesIO):
    """Play audio stream using pydub."""
    audio = AudioSegment.from_file(audio_stream, format="mp3")
    playback.play(audio)
