
import SwiftUI

// Add Persona Card View


// This view represents a button for adding a new persona card
struct AddPersonaCard: View {
    var userId: String
    
    var body: some View {
        NavigationLink(destination: PersonaFormView(userId: userId)){
                VStack {
                    // Icon (plus symbol) for adding a new persona
                    Image(systemName: "plus.circle")
                        .font(.largeTitle)  // Large icon size
                        .foregroundColor(.white)  // White color for the icon
                    
                    // Text label for the button
                    Text("Add Persona")
                        .font(.headline)  // Headline font size for the label
                        .foregroundColor(.white)  // White color for the text
                }
                .padding()  // Padding around the content (icon + label)
                .frame(width: 200, height: 250)  // Button size (width and height)
                .background(Color.gray)  // Gray background color for the button
                .cornerRadius(15)  // Rounded corners
                .shadow(radius: 5)  // Shadow effect
        }
    }
}
