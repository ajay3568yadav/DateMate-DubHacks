import Foundation
import AVFoundation

class ElevenLabsService: ObservableObject {
    private let apiKey: String
    private let voiceID: String
    private let baseURL = "https://api.elevenlabs.io/v1/text-to-speech"
    
    @Published var isLoading = false
    @Published var audioPlayer: AVAudioPlayer?
    @Published var player: AVPlayer?
    @Published var quotaExceeded = false
    
    init(apiKey: String, voiceID: String) {
        self.apiKey = apiKey
        self.voiceID = voiceID
    }
    
    func convertTextToSpeech(_ text: String) {
        isLoading = true
        
        guard let url = URL(string: "https://api.elevenlabs.io/v1/text-to-speech/\(voiceID)") else {
            print("Invalid URL")
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(apiKey, forHTTPHeaderField: "xi-api-key")
        
        let body: [String: Any] = [
            "text": text,
            "model_id": "eleven_monolingual_v1",
            "voice_settings": [
                "stability": 0.5,
                "similarity_boost": 0.5
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("Error creating request body: \(error)")
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    print("No data received")
                    return
                }
                
                print("Received data size: \(data.count) bytes")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Received JSON: \(jsonString)")
                    if jsonString.contains("quota_exceeded") {
                        // Handle quota exceeded error
                        print("ElevenLabs quota exceeded. Please upgrade your plan or try again later.")
                        // Optionally, you can set a property to indicate the error state
                        self?.quotaExceeded = true
                        // Optionally, switch to a fallback TTS solution here
                        return
                    }
                }
                
                // If we've reached this point, we assume the data is audio
                self?.playAudio(data)
            }
        }.resume()
    }
    
    private func playAudio(_ data: Data) {
            do {
                audioPlayer = try AVAudioPlayer(data: data)
                audioPlayer?.prepareToPlay()
                audioPlayer?.play()
            } catch {
                print("Error playing audio: \(error)")
            }
        }
}
