import SwiftUI
import FirebaseAuth

struct SignInEmailView: View {
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?
    @State private var isLoading: Bool = false
    
    var body: some View {
        VStack {
            Text("Sign In")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 40)
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding(.bottom, 20)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.bottom, 20)
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding(.bottom, 20)
            }
            
            if isLoading {
                ProgressView()
                    .padding(.bottom, 20)
            }
            
            Button(action: signIn) {
                Text("Sign In")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .disabled(isLoading)
        }
        .padding()
    }
    
    func signIn() {
        guard !email.isEmpty, !password.isEmpty else {
            self.errorMessage = "Please enter both email and password."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            isLoading = false
            
            if let error = error {
                self.errorMessage = error.localizedDescription
            } else {
                // Handle successful sign-in (e.g., navigate to the next screen)
                print("Signed in successfully")
            }
        }
    }
}

#Preview {
    SignInEmailView()
}
