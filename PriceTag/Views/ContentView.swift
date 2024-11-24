import SwiftUI

struct ContentView: View {
    @StateObject private var cameraViewModel = CameraViewModel()
    @StateObject private var currencyViewModel = CurrencyViewModel()
    @State private var sourceCurrency = "TRY"  // Kaynak para birimi
    @State private var targetCurrency = "USD"  // Hedef para birimi
    let currencies = ["USD", "EUR", "GBP", "JPY", "TRY"]
    
    var body: some View {
        ZStack {
            // Kamera görüntüsü
            CameraView(viewModel: cameraViewModel)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                // Para birimi seçicileri
                HStack {
                    // Kaynak para birimi seçici
                    Menu {
                        Picker("Kaynak Para Birimi", selection: $sourceCurrency) {
                            ForEach(currencies, id: \.self) { currency in
                                Text(currency).tag(currency)
                            }
                        }
                    } label: {
                        HStack {
                            Text("FROM: \(sourceCurrency)")
                            Image(systemName: "chevron.down")
                        }
                        .padding(8)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                    }
                    
                    // Dönüştürme ikonu
                    Image(systemName: "arrow.left.arrow.right")
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    // Hedef para birimi seçici
                    Menu {
                        Picker("Hedef Para Birimi", selection: $targetCurrency) {
                            ForEach(currencies, id: \.self) { currency in
                                Text(currency).tag(currency)
                            }
                        }
                    } label: {
                        HStack {
                            Text("TO: \(targetCurrency)")
                            Image(systemName: "chevron.down")
                        }
                        .padding(8)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                    }
                }
                .padding(.top, 50)
                .padding(.horizontal)
                
                if currencyViewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                }
                
                Spacer()
                
                // Tarama çerçevesi
                ZStack {
                    Rectangle()
                        .strokeBorder(Color.white, lineWidth: 2)
                        .frame(width: 250, height: 100)
                        .background(Color.black.opacity(0.2))
                    
                    if cameraViewModel.recognizedPrice == nil {
                        Text("Fiyat etiketi gösterin")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(4)
                    }
                }
                
                Spacer()
                
                // Fiyat gösterimi
                if let price = cameraViewModel.recognizedPrice {
                    let convertedPrice = currencyViewModel.convertPrice(
                        price.value,
                        from: sourceCurrency,  // Kullanıcının seçtiği kaynak para birimi
                        to: targetCurrency
                    )
                    
                    VStack(spacing: 12) {
                        HStack {
                            Text("Okunan:")
                                .foregroundColor(.gray)
                            Text("\(sourceCurrency) \(String(format: "%.2f", price.value))")
                                .foregroundColor(.white)
                                .font(.title3)
                        }
                        
                        HStack {
                            Text("Sonuç:")
                                .foregroundColor(.gray)
                            Text("\(targetCurrency) \(String(format: "%.2f", convertedPrice))")
                                .foregroundColor(.green)
                                .font(.title2)
                                .bold()
                        }
                        
                        if let lastUpdate = currencyViewModel.lastUpdateTime {
                            Text("Son güncelleme: \(lastUpdate.formatted())")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut, value: price)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
