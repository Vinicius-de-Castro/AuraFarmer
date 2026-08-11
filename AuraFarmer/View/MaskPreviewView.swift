//
//  MaskPreviewView.swift
//  AuraFarmer
//
//  Created by Vinicius Rodrigues de Castro on 10/08/26.
//

import SwiftUI
import AVFoundation
import Vision

struct MaskPreviewView: View {
    
    @State private var cameraManager = CameraManager()
    
    var body: some View {
        ZStack {
            Image("bg2")
                .resizable()
                .scaledToFill()
//            Color.green
            
            if let mask = cameraManager.currentMask, let frame = cameraManager.currentFrame {
                // Ambas as imagens são convertidas em CIImage (creio que exista maneira melhor)
                let cIFrame = CIImage(cgImage: frame)
                let cIMask = CIImage(cgImage: mask)
                
                // Essa transformação garante que ambas terão as mesmas dimensões, independente
                // de otimizações do Vision
                let scaleX = cIFrame.extent.size.width / cIMask.extent.size.width
                let scaleY = cIFrame.extent.size.height / cIMask.extent.size.height
                let scaledMask = cIMask.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
                
                let transparentBG = CIImage(color: CIColor.clear).cropped(to: cIFrame.extent)
                
                // Aqui, usamos a imagem em preto e branco (matte) como máscara para o frame
                let maskingFilter = CIFilter(name: "CIBlendWithMask", parameters: [
                    kCIInputImageKey: cIFrame,
                    kCIInputBackgroundImageKey: transparentBG,
                    kCIInputMaskImageKey: cIMask
                ])
                
                HStack {
                    
                    if let outputImage = maskingFilter?.outputImage,
                       
                       // A CIImage é "renderizada" para poder ser utilizada na view
                       let renderedCGImage = cameraManager.renderCIImage((outputImage)) {
                        
                        Image(renderedCGImage, scale: 1.0, orientation: .up, label: Text("Camera Feed"))
                            .resizable()
                            .scaledToFill()
                            .edgesIgnoringSafeArea(.all)
                            .scaleEffect(x: -1, y: 1)
                    }
                }
            }
        }
    }
}
