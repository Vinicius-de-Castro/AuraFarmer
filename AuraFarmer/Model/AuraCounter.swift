//
//  AuraCounter.swift
//  AuraFarmer
//
//  Created by Vinicius Rodrigues de Castro on 06/08/26.
//

import Vision
import CoreMedia
import Observation
import AVFoundation
import SwiftUI

@Observable
class AuraCounter {
    
    enum ArmState {
        case neutral, leftHigh, rightHigh
    }
    
    var aura: Int = 0
    
    private let sequenceHandler = VNSequenceRequestHandler()
    
    private var lastHighArm: ArmState = .neutral
    
    private var heightTreshold: CGFloat = 0.05
    
    var internalMovement: Int = 0
    
    var skelePoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    
    var audioPlayer = AVAudioPlayer()
    
    let soundURL = Bundle.main.url(forResource: "faaah", withExtension: "mp3")
    
    // Função que encontra pontos no frame que recebe do CameraManager
    func processFrame(_ pixelBuffer: CVPixelBuffer) {
        // VNDetectHumanBodyPoseRequest é um tipo de request do Vision que retorna um array de
        // observações de corpo humano, no momento só estou processando o primeiro detectado
        let bodyRequest = VNDetectHumanBodyPoseRequest { [weak self] bodyRequest, error in
            guard let self = self else { return }
            
            guard let observations = bodyRequest.results as? [VNHumanBodyPoseObservation],
                  let firstBody = observations.first else {
                return
            }
            
            // A função então envia o primeiro corpo detectado para outra função, que processa esses dados
            // sem precisar saber que eles são dados de mãos ou algo do tipo, pra função são só dados
            self.analyseBodyPose(firstBody)
        }
        
        do {
            try sequenceHandler.perform([bodyRequest], on: pixelBuffer, orientation: .up)
        } catch {
            print("Erro ao processar o Vision: \(error)")
        }
        
//         Marmotinhas
        if (aura % 67 == 0 && aura != 0) {
            playSound()
        }
    }
    
    func processMask(_ pixelBuffer: CVPixelBuffer) async -> CIImage?{
        let maskRequest = GeneratePersonSegmentationRequest()
        maskRequest.qualityLevel = .accurate
        
        do {
            let results = try await maskRequest.perform(on: pixelBuffer)
            
            if let maskBuffer = try? results.cgImage {
                return CIImage(cgImage: maskBuffer)
            }
        }
        catch {
            print("Erro ao processar a máscara: \(error)")
            return nil
        }
        return nil
    }
    
    private func analyseBodyPose(_ observation: VNHumanBodyPoseObservation) {
        do {
            let rightWrist = try observation.recognizedPoint(.rightWrist)
            let leftWrist = try observation.recognizedPoint(.leftWrist)
            
//            print("Certeza - Dir: \(rightWrist.confidence) | Esq: \(leftWrist.confidence)")
            
            guard rightWrist.confidence > 0.3 && leftWrist.confidence > 0.3 else {
                return
            }
            
            let allPoints = try observation.recognizedPoints(.all)
            var currentFramePoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
            
            for (jointName, point) in allPoints {
                if point.confidence > 0.3 {
                    let invertedY = 1.0 - point.location.y
                    currentFramePoints[jointName] = CGPoint(x: point.location.x, y: invertedY)
                }
            }
            
            
            let yDifference = rightWrist.location.y - leftWrist.location.y
            
            DispatchQueue.main.async {
                
                self.skelePoints = currentFramePoints
                
                if yDifference > self.heightTreshold {
                    if self.lastHighArm == .leftHigh {
                        self.internalMovement += 1
                        self.updateAura()
                    }
                    self.lastHighArm = .rightHigh
                    
                    
                } else if yDifference < -self.heightTreshold {
                    if self.lastHighArm == .rightHigh {
                        self.internalMovement += 1
                        self.updateAura()
                    }
                    self .lastHighArm = .leftHigh
                }
            }
            
        } catch {
            return
        }
    }
    
    func updateAura() {
        aura = internalMovement/2
    }
    
    func playSound() {
//        do {
//            audioPlayer = try AVAudioPlayer(contentsOf: soundURL!)
//        } catch {
//          print("Failed to load the sound: \(error)")
//        }
        audioPlayer.play()
      }
    
    func reset() {
        aura = 0
        internalMovement = 0
        lastHighArm = .neutral
    }
}
