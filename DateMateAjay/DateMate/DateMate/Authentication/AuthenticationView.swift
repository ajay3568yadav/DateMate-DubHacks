import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AuthenticationView: View {
    @Binding var showModal: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isSignInMode = true
    @State private var errorMessage: String? = nil
    @State private var isLoading = false

    // Track the authenticated user's ID
    @State private var authenticatedUserId: String? = nil

    private let db = Firestore.firestore()

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()

                // Toggle between Sign In and Sign Up
                HStack(spacing: 0) {
                    Button(action: { isSignInMode = true }) {
                        Text("Sign In")
                            .foregroundColor(isSignInMode ? .white : .gray)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isSignInMode ? Color.pink : Color.clear)
                            .cornerRadius(25)
                    }

                    Button(action: { isSignInMode = false }) {
                        Text("Sign Up")
                            .foregroundColor(!isSignInMode ? .white : .gray)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(!isSignInMode ? Color.pink : Color.clear)
                            .cornerRadius(25)
                    }
                }
                .background(RoundedRectangle(cornerRadius: 25).stroke(Color.gray.opacity(0.5), lineWidth: 1))
                .padding(.horizontal, 30)

                Text(isSignInMode ? "Sign in" : "Sign up")
                    .font(.system(size: 30, weight: .bold))

                TextField("Email", text: $email)
                    .padding(.leading, 40)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 12).stroke(Color.gray, lineWidth: 1))
                    .overlay(Image(systemName: "envelope.fill").foregroundColor(.pink).padding(.leading, 8), alignment: .leading)
                    .padding(.horizontal, 30)

                SecureField("Password", text: $password)
                    .padding(.leading, 35)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 12).stroke(Color.gray, lineWidth: 1))
                    .overlay(Image(systemName: "lock.fill").foregroundColor(.pink).padding(.leading, 8), alignment: .leading)
                    .padding(.horizontal, 30)

                if !isSignInMode {
                    SecureField("Confirm Password", text: $confirmPassword)
                        .padding(.leading, 35)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 12).stroke(Color.gray, lineWidth: 1))
                        .overlay(Image(systemName: "lock.fill").foregroundColor(.pink).padding(.leading, 8), alignment: .leading)
                        .padding(.horizontal, 30)
                }

                Button(action: { isSignInMode ? signIn() : signUp() }) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text(isSignInMode ? "Sign In" : "Sign Up")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 25).fill(Color.pink))
                            .padding(.horizontal, 30)
                    }
                }

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.top, 10)
                }

                Spacer()

                Button(action: { withAnimation { showModal = false } }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.black)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color.white))
                        .shadow(radius: 5)
                }
                .padding(.bottom, 20)
            }
            .navigationDestination(isPresented: .constant(authenticatedUserId != nil)) {
                if let userId = authenticatedUserId {
                    ContentView(userId: userId) // Pass the userId
                }
            }
        }
    }

    func signIn() {
        isLoading = true
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            isLoading = false
            if let error = error {
                errorMessage = "Error: \(error.localizedDescription)"
                return
            }
            authenticatedUserId = result?.user.uid
        }
    }

    func signUp() {
        guard !email.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
            errorMessage = "All fields are required."
            return
        }

        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }

        isLoading = true
        errorMessage = nil

        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            isLoading = false

            if let error = error {
                errorMessage = error.localizedDescription
            } else if let user = authResult?.user {
                let userData: [String: Any] = [
                    "uid": user.uid,
                    "email": user.email ?? "",
                    "createdAt": Timestamp()
                ]

                db.collection("users").document(user.uid).setData(userData) { error in
                    if let error = error {
                        errorMessage = "Firestore Error: \(error.localizedDescription)"
                    } else {
                        authenticatedUserId = user.uid
                    }
                }
            }
        }
    }
}
