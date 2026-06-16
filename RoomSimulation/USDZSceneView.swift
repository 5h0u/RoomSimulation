//
//  USDZSceneView.swift
//  RoomSimulation
//
//  Created by 山崎祥太郎 on 2026/06/16.
//

import SwiftUI
import SceneKit

struct USDZSceneView: View {
    let modelURL: URL

    var body: some View {
        SceneView(
            scene: loadScene(),
            options: [
                .allowsCameraControl,
                .autoenablesDefaultLighting
            ]
        )
    }

    private func loadScene() -> SCNScene? {
        guard let scene = try? SCNScene(url: modelURL) else {
            return nil
        }
        
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 3, 6)
        
        let constraint = SCNLookAtConstraint(target: scene.rootNode)
        constraint.isGimbalLockEnabled = true
        cameraNode.constraints = [constraint]
        
        scene.rootNode.addChildNode(cameraNode)
        
        scene.rootNode.childNodes.forEach {
            $0.scale = SCNVector3(0.5, 0.5, 0.5)
        }
        scene.background.contents = UIColor.systemGray6

        return scene
    }
}
