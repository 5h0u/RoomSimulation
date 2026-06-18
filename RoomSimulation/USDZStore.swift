//
//  USDZStore.swift
//  RoomSimulation
//
//  Created by yamasaki.shotaro on 2026/06/18.
//

import Combine
import Foundation
import FirebaseStorage


final class USDZStore: ObservableObject {
    
    func upload(path: String, fileName: String) async throws -> String {
        guard let url = URL(string: path) else {
            throw URLError(.badURL)
        }

        // 画像DL
        let (data, _) = try await URLSession.shared.data(from: url)
        let ext = url.pathExtension.lowercased()
        
        let storage = Storage.storage()
        let ref = storage.reference()
            .child("USDZ")
            .child(fileName)
        
        // Upload
        _ = try await ref.putDataAsync(data)
        
        // ダウンロードURL取得
        let downloadURL = try await ref.downloadURL()

        return downloadURL.absoluteString
    }
    
    func fetchStoreList() async throws -> [URL]{
        let ref = Storage.storage()
            .reference()
            .child("USDZ")

        let result = try await ref.listAll()
        
        var list:[URL] = []
        for item in result.items {
            list.append(try await item.downloadURL())
        }
        
        return list
    }
}
