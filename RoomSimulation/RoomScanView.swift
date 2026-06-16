//
//  RoomScanView.swift
//  RoomSimulation
//
//  Created by 山崎祥太郎 on 2026/06/16.
//

import SwiftUI

import SwiftUI
import Combine
import RoomPlan

struct RoomScanView: View {
    @StateObject private var captureManager = CaptureSessionManager()
    @State private var isScanning = false

    var body: some View {
        VStack {
            // スキャン中の画面
            ZStack(alignment: .bottom) {
                RoomCaptureViewRepresentable(isScanning: $isScanning, captureSessionManager: captureManager)
                    .edgesIgnoringSafeArea(.all)
                    .background(Color.red)
            }
            
            // スキャン開始・停止ボタン
            Button(action: {
                let impactMed = UIImpactFeedbackGenerator(style: .medium)
                impactMed.impactOccurred()
                isScanning.toggle()
            }) {
                Text(isScanning ? "スキャン終了" : "スキャン開始")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: 250)
                    .background(isScanning ? Color.red : Color.blue)
                    .cornerRadius(15)
                    .shadow(radius: 5)
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
        roomCaptureView.delegate = captureSessionManager
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

class CaptureSessionManager: NSObject,ObservableObject, RoomCaptureSessionDelegate, RoomCaptureViewDelegate {
    @Published var exportURL: URL?
    @Published var isProcessing: Bool = false
    
    override init() {
        super.init()
    }

    required init?(coder: NSCoder) {
        super.init()
    }

    func encode(with coder: NSCoder) {
        
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
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let fileManager = FileManager.default
                let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                // 保存先のURLを作成
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyyMMdd_HHmmss"

                let fileName = "ScannedRoom_\(formatter.string(from: Date())).usdz"
                let destinationURL = documentDirectory.appendingPathComponent(fileName)
                
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
                    
                    NotificationCenter.default.post(
                        name: .usdzSaved,
                        object: nil
                    )
                }
            } catch {
                print("USDZのエクスポートに失敗しました: \(error)")
                DispatchQueue.main.async { self.isProcessing = false }
            }
        }
    }
}
