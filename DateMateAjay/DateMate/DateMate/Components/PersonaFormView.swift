import SwiftUI
import FirebaseFirestore

struct PersonaFormView: View {
    // State variables to hold user input
    @State private var name = ""
    @State private var age = ""
    @State private var profession = ""
    @State private var details = ""

    // Firestore reference
    private let db = Firestore.firestore()

    // Assuming the user ID is passed into the view
    let userId: String // Inject the user ID when presenting this view

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header Section
                headerSection

                // Input Fields Section
                VStack(spacing: 16) {
                    CustomTextField(label: "Full name", placeholder: "", text: $name)
                    CustomTextField(label: "Age", placeholder: "", text: $age)
                    CustomTextField(label: "Profession", placeholder: "", text: $profession)

                    // Text Area for Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                            .foregroundColor(.black)

                        TextEditor(text: $details)
                            .frame(height: 100) // Set height for the text area
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 8).stroke(Color.black.opacity(0.5), lineWidth: 1))
                            .cornerRadius(8)
                            .disableAutocorrection(true)
                    }
                }
                .padding(.horizontal)

                // Buttons Section
                Spacer()
                buttonsSection
            }
            .padding()
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea()) // Background color
            .navigationBarHidden(true) // Hide default navbar
        }
    }

    // MARK: - Function to Save the Persona to Firestore
    private func savePersona() {
        // Create a new Persona entry as a dictionary
        let newPersona: [String: Any] = [
            "userId": userId,
            "name": name,
            "age": age,
            "profession": profession,
            "details": details,
            "createdAt": Timestamp()
        ]

        // Add the new persona to the 'personas' collection in Firestore
        db.collection("personas").addDocument(data: newPersona) { error in
            if let error = error {
                print("Error adding document: \(error)")
            } else {
                print("New persona added successfully!")
                presentationMode.wrappedValue.dismiss() // Dismiss the form view
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Back button
                Button(action: {
                    presentationMode.wrappedValue.dismiss() // Dismiss the view
                }) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.black)
                        .clipShape(Circle())
                }
                Spacer()
            }

            Text("Create new Persona")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.black)

            Text("Please provide some information about the person you wanna create a persona of.")
                .font(.body)
                .foregroundColor(.gray)
                .lineLimit(nil)
        }
        .padding(.horizontal)
    }

    // MARK: - Buttons Section
    private var buttonsSection: some View {
        VStack(spacing: 16) {
            // Create Button
            Button(action: {
                savePersona() // Call save function when button is tapped
            }) {
                Text("Create")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .cornerRadius(8)
            }

            // Cancel Button
            Button(action: {
                presentationMode.wrappedValue.dismiss() // Dismiss the view
            }) {
                Text("Cancel")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Custom TextField View
struct CustomTextField: View {
    var label: String
    var placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.headline)
                .foregroundColor(.black)

            TextField(placeholder, text: $text)
                .padding()
                .background(RoundedRectangle(cornerRadius: 8).stroke(Color.black.opacity(0.5), lineWidth: 1))
                .disableAutocorrection(true)
        }
    }
}

// MARK: - Preview
struct PersonaFormView_Previews: PreviewProvider {
    static var previews: some View {
        PersonaFormView(userId: "exampleUserID") // Provide test user ID for preview
    }
}
