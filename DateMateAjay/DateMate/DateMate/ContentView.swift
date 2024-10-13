import SwiftUI
import Firebase
import FirebaseFirestore

// ViewModel to manage persona data from Firebase

class PersonasViewModel: ObservableObject {
    @Published var personas: [Persona] = [] // Holds persona data

    private let db = Firestore.firestore() // Firestore database reference

    // Fetch personas for the currently logged-in user
    func fetchPersonas(for userId: String) {
        db.collection("personas")
            .whereField("userId", isEqualTo: userId) // Fetch personas for specific user
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching personas: \(error)")
                    return
                }
                self.personas = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: Persona.self) // Decode Firestore data to Persona
                } ?? []
            }
    }
}

// Persona model conforming to Codable for Firestore decoding
struct Persona: Identifiable, Codable {
    @DocumentID var id: String? // Firestore document ID
    var name: String
    var age: String
    var profession: String
    var details: String
}

struct ContentView: View {
    @StateObject private var viewModel = PersonasViewModel()
    let userId: String  // Receive userId from AuthenticationView

    let characters = ["hippo", "panda", "cat", "lion", "racoon", "pink"]  // List of character images

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {
                    // Header
                    HStack {
                        Text("Hello,")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button(action: {
                            print("Profile button tapped")
                        }) {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.black)
                        }
                        .padding(.trailing)
                    }
                    .padding([.leading, .top])
                    
                    Text("Welcome to DateMate!")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.leading)
                        .padding(.bottom, 16)
                    
                    // Personas Section Header
                    HStack {
                        Text("Personas")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.leading)
                        
                        Spacer()
                    }
                    
                    // Personas Cards in Horizontal ScrollView
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {  // Increased spacing for shadow spread
                            ForEach(Array(viewModel.personas.enumerated()), id: \.1.id) { index, persona in
                                let imageName = characters[index % characters.count]  // Select image in order
                                PersonaCard(
                                    name: persona.name,
                                    age: persona.age,
                                    profession: persona.profession,
                                    details: persona.details,
                                    imageName: imageName
                                )
                                .padding(10)  // Extra padding for shadow space
                                .shadow(color: .gray.opacity(0.1), radius: 2, x: 1, y: 1)
                            }

                            AddPersonaCard(userId: userId)
                                .padding(10)
                                .shadow(color: .black.opacity(0.1), radius: 70, x: 5, y: 5)
                        }
                        .frame(height: 320)  // Set height of horizontal scroll view
                        .padding(.horizontal)  // Add horizontal padding to the HStack
                    }
                    .padding(.horizontal)
                    
                    // DateLab Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("DateLab")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.leading)
                        
                        VStack(spacing: 16) {
                            DateLabButton(
                                title: "Mock Dates",
                                subtitle: "Practice for your date",
                                color: .blue,
                                imageName: "bear",
                                userId: userId
                            )
                            DateLabButton(
                                title: "Red-Green Flag",
                                subtitle: "Check your vibes",
                                color: .purple,
                                imageName: "fox",
                                userId: userId
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 20)
                .onAppear {
                    viewModel.fetchPersonas(for: userId)
                }
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}


// Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(userId: "koe1Au2UD2NZ1yOszqmFteroFcc2")
    }
}
