//
//  QuizRush.swift
//  GameCenter
//
//  Created by TUTU on 17/07/2026.
//

import SwiftUI

struct QuizRush: View {
    @StateObject private var viewModel = QuizViewModel()
       @State private var shakeTrigger: CGFloat = 0
    
       var body: some View {
           ZStack {
               Color(.systemBackground).ignoresSafeArea()
    
               switch viewModel.state {
               case .loading:
                   ProgressView("Loading questions…")
               case .failed(let message):
                   errorView(message)
               case .loaded:
                   if viewModel.isRoundComplete {
                       resultsView
                   } else {
                       quizContent
                   }
               }
           }
           .navigationTitle("Quiz Rush")
           .navigationBarTitleDisplayMode(.inline)
           .task {
               if viewModel.questions.isEmpty {
                   await viewModel.load()
               }
           }
           .onChange(of: viewModel.lastAnswerWasCorrect) { newValue in
               if newValue == false {
                   withAnimation(.linear(duration: 0.4)) {
                       shakeTrigger += 1
                   }
               }
           }
       }
    
       // MARK: - States
    
       private func errorView(_ message: String) -> some View {
           VStack(spacing: 16) {
               Image(systemName: "wifi.exclamationmark")
                   .font(.system(size: 40))
                   .foregroundColor(.orange)
               Text(message)
                   .multilineTextAlignment(.center)
                   .foregroundColor(.secondary)
                   .padding(.horizontal, 32)
               Button("Retry") {
                   Task { await viewModel.load() }
               }
               .buttonStyle(.borderedProminent)
           }
       }
    
       private var quizContent: some View {
           VStack(alignment: .leading, spacing: 24) {
               header
    
               if let question = viewModel.currentQuestion {
                   Text(question.question)
                       .font(.title3.bold())
                       .fixedSize(horizontal: false, vertical: true)
                       .padding(.horizontal)
                       .modifier(ShakeEffect(animatableData: shakeTrigger))
    
                   VStack(spacing: 12) {
                       ForEach(viewModel.shuffledAnswers, id: \.self) { answer in
                           AnswerButton(text: answer, isDisabled: viewModel.isAnswering) {
                               viewModel.selectAnswer(answer)
                           }
                       }
                   }
                   .padding(.horizontal)
               }
    
               Spacer()
           }
           .padding(.top, 12)
           .background(
               (viewModel.lastAnswerWasCorrect == true ? Color.green : Color.clear)
                   .opacity(0.15)
                   .ignoresSafeArea()
                   .animation(.easeInOut(duration: 0.3), value: viewModel.lastAnswerWasCorrect)
           )
       }
    
       private var header: some View {
           HStack {
               Text("\(viewModel.currentIndex + 1) of \(viewModel.totalQuestions)")
                   .font(.headline)
               Spacer()
               Text("Score: \(viewModel.score)")
                   .font(.headline)
               Spacer()
               Text("🔥 \(viewModel.streak)")
                   .font(.headline)
           }
           .padding(.horizontal)
       }
    
       private var resultsView: some View {
           RoundEndView(
               title: "Round Complete!",
               score: viewModel.score,
               highScore: viewModel.highScore,
               onReplay: { Task { await viewModel.load() } }
           )
       }
    
    @MainActor
    private func saveRoundIfNeeded() {
        let coordinate = LocationService.shared.coordinateForSession
        
        // 2. Map it to the tuple expected by SessionStore (if it exists)
        let sessionCoordinate: (latitude: Double, longitude: Double)? = {
            guard let coord = coordinate else { return nil }
            return (latitude: coord.latitude, longitude: coord.longitude)
        }()
        SessionStore.shared.addSession(
            mode: .quizRush,
            score: viewModel.score,
            coordinate: sessionCoordinate
        )
     }
   }
    
   // MARK: - Subviews
    
   private struct AnswerButton: View {
       let text: String
       let isDisabled: Bool
       let action: () -> Void
    
       var body: some View {
           Button(action: action) {
               Text(text)
                   .font(.body.weight(.medium))
                   .frame(maxWidth: .infinity, alignment: .leading)
                   .padding()
                   .background(Color(.secondarySystemBackground))
                   .cornerRadius(12)
           }
           .foregroundColor(.primary)
           .disabled(isDisabled)
           .opacity(isDisabled ? 0.6 : 1.0)
       }
   }
    
   /// Simple horizontal shake, driven by an ever-increasing animatableData value
   /// so `withAnimation` can trigger it repeatedly.
   private struct ShakeEffect: GeometryEffect {
       var amount: CGFloat = 8
       var shakesPerUnit: CGFloat = 3
       var animatableData: CGFloat
    
       func effectValue(size: CGSize) -> ProjectionTransform {
           let translation = amount * sin(animatableData * .pi * shakesPerUnit)
           return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
       }
       
}

#Preview {
    NavigationStack { QuizRush() }
}
