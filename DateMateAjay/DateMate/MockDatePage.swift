import SwiftUI
import Speech
import AVFoundation

class SpeechRecognizer: ObservableObject {
    @Published var recognizedText = ""
    @Published var isRecording = false
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    private var silenceTimer: Timer?
    private let silenceThreshold: TimeInterval = 2.5
    private var lastSpeechTime: Date?
    private let shortPauseBuffer: TimeInterval = 0.5
    
    func startRecording() {
        guard !audioEngine.isRunning else { return }
        
        recognizedText = ""
        lastSpeechTime = Date()
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set up audio session: \(error)")
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                DispatchQueue.main.async {
                    let newText = result.bestTranscription.formattedString
                    if newText != self.recognizedText {
                        self.recognizedText = newText
                        self.lastSpeechTime = Date()
                        self.resetSilenceTimer()
                    }
                }
            }
            
            if error != nil || result?.isFinal == true {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                DispatchQueue.main.async {
                    self.isRecording = false
                }
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("Audio engine failed to start: \(error)")
        }
        
        DispatchQueue.main.async {
            self.isRecording = true
            self.resetSilenceTimer()
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        silenceTimer?.invalidate()
        DispatchQueue.main.async {
            self.isRecording = false
        }
    }
    
    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if let lastSpeechTime = self.lastSpeechTime,
               Date().timeIntervalSince(lastSpeechTime) > self.silenceThreshold + self.shortPauseBuffer {
                self.stopRecording()
            }
        }
    }
}

struct Message: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

struct AnimatedBlob: View {
    @State private var scale: CGFloat = 1.0
    let isAnimating: Bool
    
    var body: some View {
        Circle()
            .fill(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: 300, height: 300)
            .scaleEffect(scale)
            .animation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true), value: scale)
            .onAppear {
                if isAnimating {
                    scale = 1.2
                }
            }
            .onChange(of: isAnimating) { newValue in
                withAnimation {
                    scale = newValue ? 1.2 : 1.0
                }
            }
    }
}

struct MockDatePage: View {
    var persona: Persona
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @StateObject private var perplexityService = PerplexityService()
    @StateObject private var elevenLabsService = ElevenLabsService(
        apiKey: "sk_ac16c7513d52c1343ffeada9400574a0d56f2787ad1d2a47",
        voiceID: "jsCqWAovK2LkecY7zXl4"
    )
    @State private var messages: [Message] = []
    @State private var lastProcessedText = ""
    @State private var isPrintingPaused = false
    @State private var isAIReplying = false
    @State private var isSessionActive = false
    @State private var remainingTime: TimeInterval = 180 // 3 minutes
    @State private var timer: Timer?
    @State private var showSecondChanceView = false
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    Text("AI Voice Assistant")
                        .font(.largeTitle)
                        .padding()
                    
                    if elevenLabsService.quotaExceeded {
                        Text("ElevenLabs quota exceeded. Please try again later.")
                            .foregroundColor(.red)
                    }
                    
                    Spacer()
                    
                    AnimatedBlob(isAnimating: isAIReplying)
                        .frame(width: 300, height: 300)
                    
                    Spacer()
                    
                    if isSessionActive {
                        Text(timeString(from: remainingTime))
                            .font(.headline)
                            .padding(.bottom, 10)
                    }
                    
                    Button(action: toggleSession) {
                        Image(systemName: isSessionActive ? "stop.circle.fill" : "mic.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 44, height: 44)
                            .foregroundColor(isSessionActive ? .red : (isAIReplying ? .gray : .blue))
                    }
                    .disabled(isAIReplying)
                    .padding(.bottom, 20)
                }
                
//                NavigationLink(destination: SecondChanceView(), isActive: $showSecondChanceView) {
//                    EmptyView()
//                }
            }
        }
        .onAppear {
            setupSpeechRecognition()
        }
        .onChange(of: speechRecognizer.isRecording) { isRecording in
            if !isRecording && !speechRecognizer.recognizedText.isEmpty && speechRecognizer.recognizedText != lastProcessedText {
                lastProcessedText = speechRecognizer.recognizedText
                if !isPrintingPaused {
                    addMessage(speechRecognizer.recognizedText, isUser: true)
                }
                isAIReplying = true
                perplexityService.getResponse(for: speechRecognizer.recognizedText)
            }
        }
        .onChange(of: perplexityService.aiResponse) { response in
            if !response.isEmpty {
                if !isPrintingPaused {
                    addMessage(response, isUser: false)
                }
                elevenLabsService.convertTextToSpeech(response)
                
                // Add a delay before allowing the next input
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(response.count) * 0.05 + 3.0) {
                    isAIReplying = false
                    if isSessionActive && !speechRecognizer.isRecording {
                        speechRecognizer.startRecording()
                    }
                }
            }
        }
    }
    
    private func toggleSession() {
        isSessionActive.toggle()
        if isSessionActive {
            startSession()
        } else {
            endSession()
        }
    }
    
    private func startSession() {
        remainingTime = 300
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remainingTime > 0 {
                remainingTime -= 1
            } else {
                endSession()
            }
        }
        speechRecognizer.startRecording()
        lastProcessedText = ""
    }
    
    private func endSession() {
        isSessionActive = false
        timer?.invalidate()
        timer = nil
        speechRecognizer.stopRecording()
        showSecondChanceView = true
    }
    
    private func addMessage(_ text: String, isUser: Bool) {
        let newMessage = Message(text: text, isUser: isUser)
        messages.append(newMessage)
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func setupSpeechRecognition() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    print("Speech recognition authorized")
                } else {
                    print("Speech recognition not authorized")
                }
            }
        }
    }
    
    init(persona: Persona) {
        self.persona = persona
        setupAudioSession()
    }

    func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
}

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isUser { Spacer() }
            Text(message.text)
                .padding(10)
                .background(message.isUser ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
            if !message.isUser { Spacer() }
        }
    }
}

//struct MockDatePage_Previews: PreviewProvider {
//    static var previews: some View {
//        MockDatePage(persona: <#T##Persona#>)
//    }
//}
