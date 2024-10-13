import SwiftUI

// PersonasButton view that supports gradient, corner radius, and text styles
struct PersonasButton: View {
    var gradient: Gradient  // Gradient background for the button
    var width: CGFloat      // Width of the button
    var height: CGFloat     // Height of the button
    var cornerRadius: CGFloat  // Corner radius of the button
    var textStyle: TextStyle  // Text content (headline and subheadline)
    var action: () -> Void   // Action to be executed on button press
    
    // Enum to define the type of text style used in the button
    enum TextStyle {
        case headlineSubheadline(headline: String, subheadline: String)  // Headline and subheadline
    }
    
    var body: some View {
        // Button component with action passed in
        Button(action: {
            action()  // Executes when button is pressed
        }) {
            VStack {
                switch textStyle {
                case .headlineSubheadline(let headline, let subheadline):
                    // Display headline and subheadline
                    Text(headline)
                        .font(.title2)
                        .foregroundColor(.white)  // White text for headline
                    Text(subheadline)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))  // Slightly transparent subheadline
                }
            }
            .frame(width: width, height: height)  // Set frame size
            .background(
                // Apply gradient as background
                LinearGradient(
                    gradient: gradient,
                    startPoint: .topLeading,  // Start gradient from top-left corner
                    endPoint: .bottomTrailing  // End gradient at bottom-right corner
                )
            )
            .cornerRadius(cornerRadius)  // Apply rounded corners
            .shadow(radius: 5)  // Add shadow to the button
        }
    }
}

