//
//  ContentView.swift
//  RoomSimulation
//
//  Created by yamasaki.shotaro on 2026/06/16.
//

import SwiftUI

struct ContentView: View {
    @State private var usdzList: [URL] = []
    @State private var path = NavigationPath()
    @EnvironmentObject var store: USDZStore
    
    var body: some View {
        NavigationStack(path: $path) {
            HeaderView()
            
            List {
                ForEach(usdzList, id: \.self) { url in
                    NavigationLink {
                        USDZSceneView(modelURL: url)
                            .ignoresSafeArea()
                    } label: {
                        Text(url.lastPathComponent)
                    }.swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                           deleteFile(url)
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    }
                }
            }
        }.onReceive(
            NotificationCenter.default.publisher(for: .usdzSaved)
        ) { _ in
            loadUsdzList()
        }.task {
            loadUsdzList()
        }
    }
    
    func loadUsdzList() {
        Task {
            do {
                usdzList = try await store.fetchStoreList()
            } catch {
                return
            }
        }
    }
    
    func deleteFile(_ url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
            loadUsdzList()
        } catch {
            print(error)
        }
    }
}

#Preview {
    ContentView()
}
