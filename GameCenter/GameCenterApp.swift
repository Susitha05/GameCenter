//
//  GameCenterApp.swift
//  GameCenter
//
//  Created by TUTU on 10/07/2026.
//

import SwiftUI
import SwiftData

@main
struct GameCenterApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
    }
}

struct RootTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                Home()
            }
            .tabItem {
                Label("Home", systemImage: "gamecontroller.fill")
            }
 
            StatsTab()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
 
            MapTab()
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }
 
            SettingsTab()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .onAppear {
            LocationService.shared.requestPermission()
        }
    }
}
