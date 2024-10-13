import SwiftUI

struct FlagGameView: View {
    @State private var currentFlag = ""
    @State private var flagType: String? // "red" or "green"
    @State private var questionIndex = 0
    @State private var score = 0
    @State private var flags: [(flagDescription: String, flagType: String)] = []
    @State private var showResults = false

    var body: some View {
        VStack(spacing: 30) {
            if showResults {
                VStack(spacing: 20) {
                    Text("Game Over! Your score: \(score)/\(flags.count)")
                        .font(.title)
                        .fontWeight(.semibold)
                    Button("Play Again") {
                        resetGame()
                    }
                    .buttonStyle(.bordered)
                    .padding()
                }
            } else if flags.isEmpty {
                Text("Loading...")
                    .font(.title)
                .onAppear {
                    fetchFlags()
                }
            } else {
                Text("Question \(questionIndex + 1): \(currentFlag)")
                    .font(.title2)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .padding()
                HStack(spacing: 20) {
                    Button(action: {
                        processAnswer("red")
                    }) {
                        Text("Red Flag")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                    }
                    .background(Color.red)
                    .cornerRadius(10)
                    
                    Button(action: {
                        processAnswer("green")
                    }) {
                        Text("Green Flag")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                    }
                    .background(Color.green)
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .navigationBarTitle("Red or Green Flag Game", displayMode: .inline)
    }
    
    private func fetchFlags() {
        // Simulate fetching data
        flags = [("Too much jealousy", "red"), ("Supports your career", "green"),
                 ("Always on their phone", "red"), ("Listens to you", "green"),
                 ("Doesn't respect your boundaries", "red")]
        nextQuestion()
    }
    
    private func nextQuestion() {
        if questionIndex >= flags.count {
            showResults = true
        } else {
            currentFlag = flags[questionIndex].flagDescription
            flagType = flags[questionIndex].flagType
        }
    }
    
    private func processAnswer(_ answer: String) {
        if let correctAnswer = flagType, answer == correctAnswer {
            score += 1
        }
        questionIndex += 1
        nextQuestion()
    }
    
    private func resetGame() {
        score = 0
        questionIndex = 0
        showResults = false
        fetchFlags()
    }
}

struct FlagGameView_Previews: PreviewProvider {
    static var previews: some View {
        FlagGameView()
    }
}

