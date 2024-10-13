import SwiftUI
import FirebaseFirestore

class MockDatesViewModel: ObservableObject {
    @Published var personas: [Persona] = []  // Holds fetched personas
    private let db = Firestore.firestore()   // Firestore reference

    // Fetch personas from Firestore using userId
    func fetchPersonas(for userId: String) {
        db.collection("personas")
            .whereField("userId", isEqualTo: userId)  // Query by userId
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching personas: \(error.localizedDescription)")
                    return
                }

                // Map Firestore documents to Persona objects
                self.personas = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: Persona.self)
                } ?? []
            }
    }
}

struct MockDatesView: View {
    @StateObject private var viewModel = MockDatesViewModel()  // ViewModel instance
    let userId: String  // Receive userId as input

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Select a Persona for Mock Date")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.leading)

                // Display fetched personas as a list of NavigationLinks
                ForEach(viewModel.personas) { persona in
                    NavigationLink(destination: MockDatePage(persona: persona)) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(persona.name)
                                .font(.headline)
                            Text("Age: \(persona.age)")
                            Text("Profession: \(persona.profession)")
                            Text(persona.details)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding()  // Padding inside each card
                        .frame(maxWidth: .infinity)  // Full width for VStack
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.2)))
                        .padding(.horizontal)  // Padding on sides of each card
                    }
                }
            }
            .padding(.horizontal)  // Padding for the entire VStack container
        }
        .navigationTitle("Mock Dates")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Fetch personas when the view appears
            viewModel.fetchPersonas(for: userId)
        }
    }
}

// MARK: - Preview
struct MockDatesView_Previews: PreviewProvider {
    static var previews: some View {
        MockDatesView(userId: "koe1Au2UD2NZ1yOszqmFteroFcc2")
    }
}
