//
//  RealityKitView.swift
//  RoomSimulation
//
//  Created by 山崎祥太郎 on 2026/06/16.
//

import SwiftUI
import RealityKit
import ARKit

struct RealityKitView: UIViewRepresentable {
    let modelURL: URL
    
    func makeUIView(context: Context) -> ARView {
        
        let arView = ARView(frame: .zero)
        Task {
            do {
                let modelEntity = try await ModelEntity.loadModel(contentsOf: modelURL)
                modelEntity.generateCollisionShapes(recursive: true)
                
                let anchor = AnchorEntity(plane: .horizontal)
                anchor.addChild(modelEntity)
                arView.scene.addAnchor(anchor)
                arView.installGestures([.translation, .scale, .rotation], for: modelEntity)
                
            } catch {
                print("RealityKitでのモデル読み込みに失敗しました: \(error.localizedDescription)")
            }
        }
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        
    }
}
