//
//  CameraManager.swift
//  AuraFarmer
//
//  Created by Vinicius Rodrigues de Castro on 06/08/26.
//

import AVFoundation
import Observation
import CoreImage

@Observable
class CameraManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session = AVCaptureSession()
    
    var currentFrame: CGImage?
    
    var currentMask: CGImage?
    
    // Essa parte é pro joguinho
    var auraCounter = AuraCounter() 
    
    private let context = CIContext()
    
    override init() {
        super.init()
        setupCamera()
    }
    
    private func setupCamera() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("Nenhuma câmera encontrada!")
            return
        }
        do {
            let captureDeviceInput = try AVCaptureDeviceInput(device: device)
            
            if session.canAddInput(captureDeviceInput) {
                session.addInput(captureDeviceInput)
            }
            
            let videoOutput = AVCaptureVideoDataOutput()
            
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            
            let queue = DispatchQueue(label: "com.aurafarmer.camera.queue")
            videoOutput.setSampleBufferDelegate(self, queue: queue)
            
            if session.canAddOutput(videoOutput) {
                session.addOutput(videoOutput)
            }
            
            #if !os(macOS)
            if let connection = videoOutput.connection(with: .video) {
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                }
            }
            #endif
            
            Task.detached {
                await self.session.startRunning()
            }
        } catch {
            print("Erro ao iniciar a sessão de captura: \(error)")
        }
    }
    
    private func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) async {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        
        DispatchQueue.main.async {
            self.currentFrame = cgImage
        }
        
        auraCounter.processFrame(pixelBuffer)
        
        if let mask = await auraCounter.processMask(pixelBuffer) {
            DispatchQueue.main.async {
                self.currentMask = self.context.createCGImage(mask, from: mask.extent)
            }
        }
    }
    
    func renderCIImage(_ CIImage: CIImage) -> CGImage? {
        if let cgImage = self.context.createCGImage(CIImage, from: CIImage.extent) {
            return cgImage
        }
        return nil
    }
}
