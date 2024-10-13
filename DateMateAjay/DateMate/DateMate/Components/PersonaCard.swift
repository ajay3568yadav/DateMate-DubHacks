import SwiftUI

// PersonaCard view to display individual persona details
struct PersonaCard: View {
    var name: String
    var age: String
    var profession: String
    var details: String
    var imageName: String

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // White background to fill the card
            Color.white
                .cornerRadius(30)
                .shadow(radius: 10)  // Add shadow for better visibility

            VStack(spacing: 10) {
                // Profile image at the top center
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .clipShape(Circle())

                Spacer()  // Push text content to the bottom

                VStack(alignment: .leading, spacing: 4) {
                    // Name and Age on the same line
                    Text("\(name), \(age)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)

                    // Profession and Details
                    Text("\(profession) - \(details)")
                        .font(.subheadline)
                        .foregroundColor(.black.opacity(0.8))
                        .lineLimit(3)  // Wrap to a third line if needed
                        .fixedSize(horizontal: false, vertical: true)  // Allow vertical growth
                }
                .padding([.horizontal, .bottom])  // Add padding to text
            }
            .padding()  // Add padding to the entire VStack
        }
        .frame(width: 200, height: 280)  // Set card size
        .cornerRadius(30)  // Rounded corners for the card
        .shadow(radius: 10)  // Shadow for depth
        .onTapGesture {
            print("\(name) button pressed")
        }
    }
}
