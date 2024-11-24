//
//  CameraViewModel.swift
//  PriceTag
//
//  Created by kaan kayadan on 24.11.2024.
//


import SwiftUI
import AVFoundation
import Vision
import VisionKit

class CameraViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var recognizedPrice: Price?
    private var captureSession: AVCaptureSession?
    private lazy var textRecognizer: VNRecognizeTextRequest = {
        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation],
                  let self = self else { return }
            
            for observation in observations {
                guard let candidate = observation.topCandidates(1).first?.string else { continue }
                if let amount = self.extractNumericValue(from: candidate) {
                    DispatchQueue.main.async {
                        self.recognizedPrice = Price(value: amount, currency: "") // Para birimi boş
                    }
                    break
                }
            }
        }
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en-US"]
        request.usesLanguageCorrection = true
        return request
    }()
    
    // Sayısal değeri çıkaran fonksiyon
    private func extractNumericValue(from text: String) -> Double? {
        let numericPattern = "\\d+([.,]\\d{2})?"
        
        guard let regex = try? NSRegularExpression(pattern: numericPattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else {
            return nil
        }
        
        if let numberRange = Range(match.range, in: text) {
            let numberStr = String(text[numberRange])
                .replacingOccurrences(of: ",", with: ".")
            return Double(numberStr)
        }
        
        return nil
    }
    
    func setupCamera(in view: UIView) {
        captureSession = AVCaptureSession()
        guard let captureSession = captureSession else { return }
        
        guard let camera = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            return
        }
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: .userInteractive))
        
        captureSession.beginConfiguration()
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
        }
        captureSession.commitConfiguration()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        
        DispatchQueue.main.async {
            view.layer.addSublayer(previewLayer)
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput,
                      didOutput sampleBuffer: CMSampleBuffer,
                      from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right)
        try? requestHandler.perform([textRecognizer])
    }
}