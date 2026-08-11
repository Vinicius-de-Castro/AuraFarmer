//
//  ContentView.swift
//  AuraFarmer
//
//  Created by Vinicius Rodrigues de Castro on 06/08/26.
//

import SwiftUI
import AVFoundation
import Vision

struct ContentView: View {
    
    @State private var cameraManager = CameraManager()
    
    @State private var debugMode: Bool = false
    
    let startDate = Date()
    
    var body: some View {
        
        let skelePoints = cameraManager.auraCounter.skelePoints
        let leftWristRaw = skelePoints[.leftWrist]
        let rightWristRaw = skelePoints[.rightWrist]
        let neckRaw = skelePoints[.neck]
        let leftHipRaw = skelePoints[.leftHip]
        let rightHipRaw = skelePoints[.rightHip]
        
        ZStack(alignment: .center) {
            if let frame = cameraManager.currentFrame {
                Image(frame, scale: 1.0, orientation: .up, label: Text("Camera Feed"))
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                    .scaleEffect(x: -1, y: 1)
                
                
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
                
                if cameraManager.auraCounter.aura >= 0 {
                    Rectangle()
                        .fill(.black.opacity(0.01))
//                        .visualEffect { content, proxy in
//                            // Aqui virão os shaders
//                        }
                        .edgesIgnoringSafeArea(.all)
                        .scaleEffect(x: -1, y: 1)
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
