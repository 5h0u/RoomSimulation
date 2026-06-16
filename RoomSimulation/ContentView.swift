//
//  ContentView.swift
//  RoomSimulation
//
//  Created by yamasaki.shotaro on 2026/06/16.
//

import SwiftUI
import Combine
import RoomPlan
import RealityKit
import ARKit

struct ContentView: View {
    @StateObject private var captureManager = CaptureSessionManager()
    @State private var isScanning = false

    var body: some View {
        ZStack {
            // スキャン完了し、URLが取得できたら3Dプレビューを表示
            if let url = captureManager.exportURL {
                VStack {
                    RealityKitView(modelURL: url)
                        .edgesIgnoringSafeArea(.all)
                    
                    Button("もう一度スキャンする") {
                        captureManager.exportURL = nil
                        isScanning = true
                    }
                    .padding()
                    .buttonStyle(.borderedProminent)
                }
            } else {
                // スキャン中の画面
                ZStack(alignment: .bottom) {
                    RoomCaptureViewRepresentable(isScanning: $isScanning, captureSessionManager: captureManager)
                        .edgesIgnoringSafeArea(.all)
                        .background(Color.red)
                    
                    if captureManager.isProcessing {
                        // エクスポート処理中のローディング表示
                        VStack {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("3Dモデルを生成中...")
                                .padding(.top, 10)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(.black.opacity(0.7))
                        .cornerRadius(10)
                        .padding(.bottom, 50)
                    } else {
                        // スキャン開始・停止ボタン
                        Button(action: {
                            let impactMed = UIImpactFeedbackGenerator(style: .medium)
                            impactMed.impactOccurred()
                            isScanning.toggle()
                        }) {
                            Text(isScanning ? "スキャン完了・モデル生成" : "スキャン開始")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: 250)
                                .background(isScanning ? Color.red : Color.blue)
                                .cornerRadius(15)
                                .shadow(radius: 5)
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
        }
    }
}

struct RoomCaptureViewRepresentable: UIViewRepresentable {
    @Binding var isScanning: Bool
    let captureSessionManager: CaptureSessionManager
    
    func makeUIView(context: Context) -> RoomCaptureView {
        let roomCaptureView = RoomCaptureView(frame: .zero)
        print("RoomCaptureView created")
        roomCaptureView.captureSession.delegate = captureSessionManager
        return roomCaptureView
    }
    
    func updateUIView(_ uiView: RoomCaptureView, context: Context) {
        if isScanning {
            uiView.captureSession.run(configuration: RoomCaptureSession.Configuration())
        } else {
            uiView.captureSession.stop()
        }
    }
}

struct RealityKitView: UIViewRepresentable {
    let modelURL: URL
    
    func makeUIView(context: Context) -> ARView {
        // ARViewを生成（自動的にデバイスのカメラ映像が背景になります）
        let arView = ARView(frame: .zero)
        
        // メインスレッドをブロックしないよう非同期でモデルを読み込む
        Task {
            do {
                // ローカルのUSDZファイルからモデルをロード
                let modelEntity = try await ModelEntity.loadModel(contentsOf: modelURL)
                
                // 【重要】指で操作（タップ、ドラッグ）できるように当たり判定を自動生成
                modelEntity.generateCollisionShapes(recursive: true)
                
                // 現実世界の「水平な面（床や机）」を自動検知して、そこにアンカー（基準点）を置く
                let anchor = AnchorEntity(plane: .horizontal)
                
                // アンカーの上に3Dモデルを乗せる
                anchor.addChild(modelEntity)
                
                // AR空間にアンカーごと追加して表示
                arView.scene.addAnchor(anchor)
                
                // ユーザーが指で「移動（translation）」「拡大縮小（scale）」「回転（rotation）」できるようにジェスチャーを追加
                arView.installGestures([.translation, .scale, .rotation], for: modelEntity)
                
            } catch {
                print("RealityKitでのモデル読み込みに失敗しました: \(error.localizedDescription)")
            }
        }
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // ビューが更新された時の処理（今回は特に不要）
    }
}

class CaptureSessionManager: NSObject,ObservableObject, RoomCaptureSessionDelegate {
    @Published var exportURL: URL?
    @Published var isProcessing: Bool = false
    
    override init() {
        super.init()
    }

    required init?(coder: NSCoder) {
        super.init()
    }

    func encode(with coder: NSCoder) {
        // 保存する必要がなければ空実装でOK
    }
    
    // スキャン完了後の処理
    func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
        if let error = error {
            print("エラーが発生しました: \(error.localizedDescription)")
            return
        }
        
        DispatchQueue.main.async {
            self.isProcessing = true
        }
        
        // バックグラウンドでUSDZファイルとして書き出し
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let fileManager = FileManager.default
                let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                // 保存先のURLを作成
                let destinationURL = documentDirectory.appendingPathComponent("ScannedRoom.usdz")
                
                // 既存のファイルがあれば削除
                if fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.removeItem(at: destinationURL)
                }
                
                // パラメトリック（整理された綺麗な面）としてエクスポート
                try processedResult.export(to: destinationURL, exportOptions: .parametric)
                
                // メインスレッドでURLを更新し、プレビューを表示
                DispatchQueue.main.async {
                    self.exportURL = destinationURL
                    self.isProcessing = false
                }
            } catch {
                print("USDZのエクスポートに失敗しました: \(error)")
                DispatchQueue.main.async { self.isProcessing = false }
            }
        }
    }
}

#Preview {
    ContentView()
}
