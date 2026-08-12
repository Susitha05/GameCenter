//
//  ContentView.swift
//  GameCenter
//
//  Created by TUTU on 10/07/2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        ZStack{
            LinearGradient(colors: [.black],startPoint: .top, endPoint: .bottom)
            VStack(spacing:20){
                Image("gamelogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 250)
                

            }
            Spacer();
        }
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
