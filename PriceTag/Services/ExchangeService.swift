import Foundation

// MARK: - Exchange Rate Models
struct ExchangeRateResponse: Codable {
    let result: String
    let base_code: String
    let conversion_rates: [String: Double]
}

// MARK: - Exchange Service
class ExchangeService {
    static let shared = ExchangeService()
    private let apiKey = "509c56ad36ac83b04384e499"
    
    private init() {}
    
    func fetchLatestRates() async throws -> [String: Double] {
        let urlString = "https://v6.exchangerate-api.com/v6/\(apiKey)/latest/USD"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        // Debug için API yanıtını konsola yazdıralım
        if let jsonString = String(data: data, encoding: .utf8) {
            print("API Response:", jsonString)
        }
        
        let ratesResponse = try JSONDecoder().decode(ExchangeRateResponse.self, from: data)
        
        // Sadece kullanılan para birimlerini filtreleyelim
        let filteredRates = ratesResponse.conversion_rates.filter { key, _ in
            ["USD", "EUR", "GBP", "JPY", "TRY"].contains(key)
        }
        
        return filteredRates
    }
}
