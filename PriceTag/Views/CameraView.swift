import SwiftUI
import AVFoundation
import Vision
import VisionKit

// CameraViewModel'i import et
import Foundation // Eğer aynı modülde değilse

struct CameraView: UIViewRepresentable {
    @ObservedObject var viewModel: CameraViewModel
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        viewModel.setupCamera(in: view)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}
