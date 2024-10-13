import Foundation

class PerplexityService: ObservableObject {
    @Published var aiResponse = ""
    private let apiKey = "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"
    private let apiUrl = "https://api.perplexity.ai/chat/completions"
    
    func getResponse(for userInput: String) {
        let parameters: [String: Any] = [
            "model": "mistral-7b-instruct",
            "messages": [
                ["role": "system", "content": "You are a 23 year old Indian American living in New York City. and you are supposed to be on a date with the user, so talk accordingly. you like bollywood and dance and music. Provide short to moderate and sweet answers and do ask questions sometimes like people do on usual dates."],
                ["role": "user", "content": userInput]
            ],
            "max_tokens": 50  // Adjust this value to control response length
        ]
        
        guard let url = URL(string: apiUrl) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            print("Error creating request body: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    DispatchQueue.main.async {
                        self.aiResponse = content
                    }
                }
            } catch {
                print("Error parsing JSON: \(error)")
            }
        }.resume()
    }
}
