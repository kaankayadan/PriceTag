import Foundation
import SwiftUI

class CurrencyViewModel: ObservableObject {
    @Published var exchangeRates: [String: Double] = [:]
    @Published var lastUpdateTime: Date?
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    init() {
        // İlk açılışta kurları al
        Task {
            await updateRates()
        }
        
        // Her gün saat 00:00'da güncelle
        setupDailyUpdate()
    }
    
    private func setupDailyUpdate() {
        let calendar = Calendar.current
        let now = Date()
        
        // Yarının 00:00'ını hesapla
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
              let nextUpdate = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: tomorrow) else {
            return
        }
        
        // İlk güncelleme için geçecek süreyi hesapla
        let timeInterval = nextUpdate.timeIntervalSince(now)
        
        // Timer'ı kur
        Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] _ in
            Task {
                await self?.updateRates()
                // Sonraki günlük güncellemeler için yeni timer kur
                self?.setupDailyUpdate()
            }
        }
    }
    
    @MainActor
    func updateRates() async {
        isLoading = true
        error = nil
        
        do {
            exchangeRates = try await ExchangeService.shared.fetchLatestRates()
            lastUpdateTime = Date()
            print("Kurlar güncellendi:", exchangeRates) // Debug için
        } catch {
            self.error = "Kurlar güncellenirken hata oluştu: \(error.localizedDescription)"
            print("Kur güncelleme hatası:", error) // Debug için
        }
        
        isLoading = false
    }
    
    func convertPrice(_ amount: Double, from sourceCurrency: String, to targetCurrency: String) -> Double {
        guard let sourceRate = exchangeRates[sourceCurrency],
              let targetRate = exchangeRates[targetCurrency] else {
            print("Kur dönüşümü başarısız - Kaynak: \(sourceCurrency), Hedef: \(targetCurrency)") // Debug için
            return amount
        }
        
        let result = amount * (targetRate / sourceRate)
        print("Kur dönüşümü: \(amount) \(sourceCurrency) = \(result) \(targetCurrency)") // Debug için
        return result
    }
}
