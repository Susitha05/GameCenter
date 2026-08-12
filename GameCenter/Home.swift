//
//  Home.swift
//  GameCenter
//
//  Created by TUTU on 11/07/2026.

import SwiftUI

struct Home : View{
    var body : some View{
        ZStack{
            LinearGradient(colors: [.black], startPoint: .top, endPoint: .bottom)
            VStack(spacing:40){
                Image("gamelogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 250)

        
                       NavigationLink(destination: TapFrenzy()) {
                           ModeButtonLabel(
                               title: "🏵️ Tap Frenzy",
                               subtitle: "One card. Tap it fast, beat the clock.",
                               color: .yellow
                           )
                       }
    
                       .padding(.top, 40)
                       NavigationLink(destination: LightUp()) {
                           ModeButtonLabel(
                               title: "💡 Light It Up",
                               subtitle: "Grid grows, window shrinks, four levels.",
                               color: .blue
                           )
                       }
        
                       NavigationLink(destination: QuizRush()) {
                           ModeButtonLabel(
                               title: "❓ Quiz Rush",
                               subtitle: "10 live trivia questions, streak bonuses.",
                               color: .orange
                           )
                       }
                Spacer()
            }
            .padding(.top, 80)
        }
        .ignoresSafeArea()
    }
}
private struct ModeButtonLabel: View {
    let title: String
    let subtitle: String
    let color: Color
 
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(title).font(.title3.bold())
            Text(subtitle).font(.subheadline).foregroundColor(.secondary)
        }
        .frame(maxWidth: 340, alignment: .leading)
        .padding()
        .background(color.opacity(0.15))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(color, lineWidth: 2))
        .cornerRadius(16)
        .foregroundColor(.primary)
    }
}
#Preview {
    Home()
}
