//
//  HeaderView.swift
//  RoomSimulation
//
//  Created by 山崎祥太郎 on 2026/06/16.
//

import SwiftUI

struct HeaderView: View {
    var body: some View {
        HStack {
            Spacer()
            
            NavigationLink("スキャン") {
                RoomScanView()
            }
            .padding(.all, 10)
        }
    }
}

#Preview {
    HeaderView()
}
