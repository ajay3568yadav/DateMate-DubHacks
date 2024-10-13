import SwiftUI

// Ring View to represent individual progress rings
struct ProgressRingView: View {
    var ringColor: Color = .blue
    var progressValue: Double // Progress value between 0.0 and 1.0
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                .frame(width: 40, height: 40)
            Circle()
                .trim(from: 0.0, to: CGFloat(progressValue))
                .stroke(ringColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 40, height: 40)
        }
    }
}

// Main View for "Your Second Chance" section
struct SecondChanceCriteriaView: View {
    let criteriaCount = 5
    let criteria = ["compatibility", "Quality of conversation", "Confidence", "Respectfulness", "Enthusiasm"]
    
    // Generate random progress values between 6 and 9
    func randomProgressValues() -> [Double] {
        return (1...criteriaCount).map { _ in
            Double(Int.random(in: 6...9)) / 9.0 // Maps 6-9 to 0.67-1.0
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 35) {
                Text("Your Second Chance")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 0)
                
                let progressValues = randomProgressValues()
                let overallScore = progressValues.reduce(0, +) / Double(criteriaCount) // Calculate overall score

                ForEach(0..<criteriaCount, id: \.self) { index in
                    HStack(spacing: 15) {
                        ProgressRingView(progressValue: progressValues[index])
                        VStack(alignment: .leading) {
                            Text("Criteria: \(criteria[index])")
                                .font(.headline)
                            Text("Score: \(Int(progressValues[index] * 10))") // Convert to score out of 10
                        }
                    }
                }
                
                Spacer(minLength: 20)
                
                if overallScore > 0.6 {
                    Text("You will secure a second date")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green) // Highlight the message
                        .padding(.top, 10)
                }
            }
            .padding()
        }
    }
}

// Preview for the view
struct SecondChanceCriteriaView_Previews: PreviewProvider {
    static var previews: some View {
        SecondChanceCriteriaView()
    }
}

