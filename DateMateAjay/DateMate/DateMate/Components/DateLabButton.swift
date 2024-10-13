import SwiftUI

struct DateLabButton: View {
    var title: String
    var subtitle: String
    var color: Color
    var imageName: String
    var userId: String

    var body: some View {
        NavigationLink(destination: destinationView) {
            HStack(spacing: 15) {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .shadow(radius: 5)

                VStack(alignment: .leading, spacing: 5) {
                    // Title Text
                    Text(title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)

                    // Subtitle Text
                    Text(subtitle)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 160)
            .background(color)
            .cornerRadius(30)
            .shadow(radius: 10)
        }
    }

    // MARK: - Dynamic Destination View
    
    private var destinationView: some View {
        if title == "Mock Dates" {
            return AnyView(MockDatesView(userId: userId))  // Navigate to MockDatePage
        } else {
            return AnyView(FlagGameView())  // Navigate to AddPersonaView
        }
    }
}


// MARK: - Preview
struct DateLabButton_Previews: PreviewProvider {
    static var previews: some View {
        DateLabButton(
            title: "Mock Date",
            subtitle: "Practice for your date",
            color: .blue,
            imageName: "bear",
            userId: "koe1Au2UD2NZ1yOszqmFteroFcc2"
        )
        .previewLayout(.sizeThatFits)
        .padding()

        DateLabButton(
            title: "Red-Green Flag",
            subtitle: "Check your vibes",
            color: .purple,
            imageName: "fox",
            userId: "koe1Au2UD2NZ1yOszqmFteroFcc2"
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
