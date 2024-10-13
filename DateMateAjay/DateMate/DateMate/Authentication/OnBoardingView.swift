import SwiftUI
import RiveRuntime

struct OnBoardingView: View {
    @State private var showSignInModal = false

    var body: some View {
        ZStack {
            // Background Image Layer
            GeometryReader { geometry in
                Image("Spline")
                    .resizable()
                    .scaledToFit()
                    .frame(width: geometry.size.width * 1.5)
                    .position(x: geometry.size.width / 1.1, y: geometry.size.height / 2)
                    .blur(radius: 30)
                    .ignoresSafeArea()
            }

            // Rive Animation Layer
            RiveViewModel(fileName: "shapes")
                .view()
                .ignoresSafeArea()
                .blur(radius: 30)

            // Main Content Layer
            VStack(alignment: .leading, spacing: 20) {
                Spacer() // Push content from top to center

                // Title Texts
                Text("Meet\nConnect\n& Spark")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.leading)

                // Subtitle Text
                Text("Don't miss connections. Meet, chat, and spark meaningful relationships. Explore real connections through genuine conversations.")
                    .font(.system(size: 17))
                    .foregroundColor(.black.opacity(0.7))

                Spacer() // Push the rest of the content to the bottom

                // Sign Up or Sign In Button
                Button(action: {
                    withAnimation {
                        showSignInModal = true // Show the modal with animation
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.right")
                            .foregroundColor(.white)

                        Text("Sign Up or Sign In")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.black)
                            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 10)
                    )
                }

                Spacer().frame(height: 20) // Extra space at the bottom
            }
            .padding(.horizontal, 30)
            .padding(.top, 60) // Adjust for the top safe area

            // Sign-In Modal Overlay
            if showSignInModal {
                AuthenticationView(showModal: $showSignInModal) // Custom sign-in modal
                    .transition(.move(edge: .bottom)) // Animation
                    .zIndex(1) // Ensure it's on top
            }
        }
    }
}


// Preview
#Preview {
    OnBoardingView()
}
