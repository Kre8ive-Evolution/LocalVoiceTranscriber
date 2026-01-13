import Foundation

/// Handles webhook communication with n8n (Nexa/Bruce)
class WebhookHandler {
    static let shared = WebhookHandler()

    // Webhook URLs
    private let nexaURL = "http://localhost:5678/webhook/nexa"
    private let bruceURL = "http://localhost:5678/webhook/bruce"

    // Keywords (case-insensitive)
    private let nexaKeyword = "nexa"
    private let bruceKeyword = "bruce"

    private init() {}

    /// Check if transcription contains a webhook keyword
    func checkForKeyword(_ text: String) -> (keyword: String, url: String)? {
        let lowercased = text.lowercased()

        if lowercased.contains(bruceKeyword) {
            return (bruceKeyword, bruceURL)
        } else if lowercased.contains(nexaKeyword) {
            return (nexaKeyword, nexaURL)
        }

        return nil
    }

    /// Send transcription to webhook and get response
    func sendToWebhook(text: String, url: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let requestURL = URL(string: url) else {
            completion(.failure(NSError(domain: "WebhookHandler", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60

        let body: [String: Any] = ["transcript": text]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }

        print("📤 Sending to webhook: \(url)")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "WebhookHandler", code: -2, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let response = json["response"] as? String {
                    print("📥 Webhook response: \(response.prefix(100))...")
                    completion(.success(response))
                } else {
                    completion(.failure(NSError(domain: "WebhookHandler", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
