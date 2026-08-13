//
//  ContentView.swift
//  AuraFarmer
//
//  Created by Vinicius Rodrigues de Castro on 06/08/26.
//

import Vision
import SwiftUI
import Foundation
import AVFoundation

struct ContentView: View {
    
    @State private var cameraManager = CameraManager()
    
    @State private var debugMode: Bool = false
    
    let startDate = Date()
    
    var body: some View {
        ZStack(alignment: .center) {
            if let frame = cameraManager.currentFrame {
                Image(frame, scale: 1.0, orientation: .up, label: Text("Camera Feed"))
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                    .scaleEffect(x: -1, y: 1)
                    .grayscale(min(1, Double(cameraManager.auraCounter.aura)/67.0))
                    .contrast(1 + 0.5 * Double(cameraManager.auraCounter.aura)/67.0)
                    .brightness(-0.05 * Double(cameraManager.auraCounter.aura)/67.0)
                
                
                if debugMode {
                    Canvas { context, size in
                        
                        let points = cameraManager.auraCounter.skelePoints
                        
                        let connections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
                            // Tronco
                            (.neck, .leftShoulder),
                            (.neck, .rightShoulder),
                            (.leftShoulder, .rightShoulder),
                            (.leftShoulder, .leftHip),
                            (.rightShoulder, .rightHip),
                            (.leftHip, .rightHip),
                            
                            // Braços
                            (.leftShoulder, .leftElbow),
                            (.leftElbow, .leftWrist),
                            (.rightShoulder, .rightElbow),
                            (.rightElbow, .rightWrist)
                        ]
                        
                        var path = Path()
                        
                        for connection in connections {
                            if let startPoint = points[connection.0], let endPoint = points[connection.1] {
                                let startX = startPoint.x * size.width
                                let startY = startPoint.y * size.height
                                let endX = endPoint.x * size.width
                                let endY = endPoint.y * size.height
                                
                                path.move(to: CGPoint(x: startX, y: startY))
                                path.addLine(to: CGPoint(x: endX, y: endY))
                            }
                        }
                        
                        context.stroke(path, with: .color(.green), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                        
                        for (_, point) in points {
                            let x = point.x * size.width
                            let y = point.y * size.height
                            let rect = CGRect(x: x-5, y: y-5, width: 10, height: 10)
                            context.fill(Path(ellipseIn: rect), with: .color(.red))
                        }
                    }
                    .edgesIgnoringSafeArea(.all)
                    .scaleEffect(x: -1, y: 1)
                }
                
                if cameraManager.auraCounter.aura > 0 {
                    if let frame = cameraManager.currentFrame, let mask = cameraManager.currentMask {
                        
                        // Ambas as imagens são convertidas em CIImage (creio que exista maneira melhor)
                        let cIFrame = CIImage(cgImage: frame)
                        let cIMask = CIImage(cgImage: mask)
                        
                        // Essa transformação garante que ambas terão as mesmas dimensões, independente
                        // de otimizações do Vision
                        let scaleX = cIFrame.extent.size.width / cIMask.extent.size.width
                        let scaleY = cIFrame.extent.size.height / cIMask.extent.size.height
                        let scaledMask = cIMask.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
                        
                        // Essa transformação "aumenta a aura"
                        let expandedMask = scaledMask.applyingFilter("CIMorphologyMaximum", parameters: [
                            kCIInputImageKey: scaledMask,
                            kCIInputRadiusKey:  log2(Double(cameraManager.auraCounter.aura)) * 10
                        ])
                        
                        // Essa transformação converte a máscara em preto e branco em uma máscara de alfa propriamente dita
                        let alphaMask = expandedMask.applyingFilter("CIColorMatrix", parameters: [
                            "inputRVector": CIVector(x:0, y:0, z:0, w:1),
                            "inputGVector": CIVector(x:0, y:0, z:0, w:1),
                            "inputBVector": CIVector(x:0, y:0, z:0, w:1),
                            "inputAVector": CIVector(x:1, y:1, z:1, w:0),
                            "inputBiasVector": CIVector(x:0, y:0, z:0, w:0)
                        ])
                        
                        let renderedAlphaMask = cameraManager.renderCIImage(alphaMask)
                        
                        Rectangle()
                            .fill(.white.opacity(0.01))
                            .visualEffect { content, proxy in
                                content.colorEffect(
                                    ShaderLibrary.auraEffect(
                                        .float2(proxy.size),
                                        .float(startDate.timeIntervalSinceNow),
                                        .float(Float(cameraManager.auraCounter.aura))
//                                        .image(Image(decorative: cgImage, scale: 1.0))
                                    )
                                )
                            }
                            .edgesIgnoringSafeArea(.all)
                            .scaleEffect(x: -1, y: 1)
                            .mask {
                                Image(decorative: renderedAlphaMask!, scale: 1.0)
                                    .resizable()
                                    .edgesIgnoringSafeArea(.all)
                                    .scaleEffect(x: -1, y: 1)
                                    .blur(radius: CGFloat(log2(Double(cameraManager.auraCounter.aura))) * 5 + 1)
                                    .distortionEffect(ShaderLibrary.waveDistortion(
                                        .float(startDate.timeIntervalSinceNow * Double(cameraManager.auraCounter.aura))),
                                                      maxSampleOffset: CGSize(width: 0, height: 20))
                            }
                            .blendMode(.plusLighter)
                            .opacity(min(1, Double(cameraManager.auraCounter.aura)/10))
                        
//                        Image(decorative: renderedAlphaMask!, scale: 1.0)
//                            .resizable()
//                            .edgesIgnoringSafeArea(.all)
//                            .scaleEffect(x: -1, y: 1)
//                            .opacity(0.5)
                    }
                }
                
                VStack{
                    HStack{
                        Text("Pontuação: \(cameraManager.auraCounter.aura)")
                            .font(.system(size: 40, weight: .black))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(10)
                        
                        Spacer()
                        
                        Button("Get aura") {
                            cameraManager.auraCounter.internalMovement += 2
                            cameraManager.auraCounter.updateAura()
                        }
                        .buttonRepeatBehavior(.enabled)
                        
                        Spacer()
                        
                        Button {
                            debugMode.toggle()
                        } label: {
                            Text("Debug mode: \(debugMode ? "On" : "Off")")
                                .font(.system(size: 20, weight: .black))
                                .padding()
                        }
                        .background(debugMode ? .gray : .blue)
                        .cornerRadius(10)
                    }
                    Spacer()
                }
                .padding()
            }
            else {
                Color.black.edgesIgnoringSafeArea(.all)
                ProgressView("Ligando câmera...")
            }
        }
        .onAppear {
            do {
                cameraManager.auraCounter.audioPlayer = try AVAudioPlayer(contentsOf: cameraManager.auraCounter.soundURL!)
            }
            catch {
                return
            }
        }
    }
    private func getWristPosition(isLeft: Bool, size: CGSize) -> CGPoint {
        let points = cameraManager.auraCounter.skelePoints
        let joint: VNHumanBodyPoseObservation.JointName = isLeft ? .leftWrist : .rightWrist
        
        if let point = points[joint] {
            return CGPoint(x: point.x * size.width, y: point.y * size.height)
        }
        return CGPoint(x: -1000, y: -1000)
    }
}
