//
//  QuizView.swift
//  TestGenius
//
//  Created by Aleksandr Matkava on 15.07.2024.
//

import SwiftUI

struct QuizView: View {
    @ObservedObject var viewModel: QuizViewModel
    @State private var showPicker = false
    @State private var showShuffleAlert = false
    @State private var timerText = "00:00"
    @State private var timer: Timer?
    @State private var showSwipeHint = true
    @State private var transitionDirection: Edge = .leading

    var body: some View {
        NavigationView {
            VStack {
                Text("Вопрос № \(viewModel.currentQuestionIndex + 1)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                    .padding(.bottom, 10)

                if viewModel.currentQuestionIndex < viewModel.questions.count {
                    let question = viewModel.questions[viewModel.currentQuestionIndex]

                    VStack(alignment: .leading) {
                        HStack {
                            TimerView(timerText: $timerText)
                            Spacer()
                            ScoreCounterView(correctCount: viewModel.correctAnswersCount, incorrectCount: viewModel.incorrectAnswersCount)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .padding(.horizontal)

                        if showSwipeHint {
                            Text("Проведите влево или вправо для переключения вопросов")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                                .padding(.bottom, 5)
                        }

                        Text(question.text)
                            .font(.title2)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                            .shadow(radius: 5)
                            .transition(.move(edge: transitionDirection))
                            .id(question.id)  // Make sure the view gets updated
                            .gesture(
                                DragGesture()
                                    .onEnded { value in
                                        withAnimation {
                                            showSwipeHint = false
                                            if value.translation.width < -100 {
                                                transitionDirection = .trailing
                                                viewModel.nextQuestion()
                                            } else if value.translation.width > 100 {
                                                transitionDirection = .leading
                                                viewModel.previousQuestion()
                                            }
                                        }
                                    }
                            )
                            .padding(.horizontal)
                        
                        if question.options.count > 4 {
                            ScrollView {
                                VStack {
                                    ForEach(question.options, id: \.self) { option in
                                        OptionButton(option: option, viewModel: viewModel)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        } else {
                            VStack {
                                ForEach(question.options, id: \.self) { option in
                                    OptionButton(option: option, viewModel: viewModel)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                    }
                    
                    Spacer()
                    
                    HStack {
                        Spacer()
                        Button(action: {
                            showPicker.toggle()
                        }) {
                            Image(systemName: "list.bullet.circle")
                                .font(.largeTitle)
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(PlainButtonStyle())
                        Spacer()
                        Button {
                            withAnimation {
                                viewModel.checkAnswer(for: question)
                            }
                        } label: {
                            Text("Проверить")
                                .frame(minWidth: 140)
                                .frame(minHeight: 27.5)
                        }
                        .buttonStyle(MainButtonStyle())
                        .padding(.leading)
                        Spacer()
                        Button(action: {
                            showShuffleAlert = true
                        }) {
                            Image(systemName: viewModel.isShuffled ? "shuffle.circle.fill" : "shuffle.circle")
                                .font(.largeTitle)
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(PlainButtonStyle())
                        Spacer()
                    }
                    .padding()
                } else {
                    Text("Вопросы закончились!")
                        .padding()
                        .transition(.opacity)
                }
            }
            .alert(isPresented: $showShuffleAlert) {
                Alert(
                    title: Text("Режим случайных вопросов"),
                    message: Text("Вкл/Выкл"),
                    dismissButton: .default(Text("ОК")) {
                        viewModel.isShuffled.toggle()
                    }
                )
            }
            .sheet(isPresented: $showPicker) {
                QuestionPickerView(viewModel: viewModel, showPicker: $showPicker, resetTimer: resetTimer)
            }
            .onAppear {
                startTimer()
            }
            .onDisappear {
                stopTimer()
            }
        }
    }

    private func startTimer() {
        let startDate = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            let elapsedTime = Int(Date().timeIntervalSince(startDate))
            let minutes = elapsedTime / 60
            let seconds = elapsedTime % 60
            timerText = String(format: "%02d:%02d", minutes, seconds)
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func resetTimer() {
        stopTimer()
        timerText = "00:00"
        startTimer()
    }
}

struct OptionButton: View {
    let option: String
    @ObservedObject var viewModel: QuizViewModel

    var body: some View {
        let optionLetter = String(option.prefix(1))
        Button(action: {
            withAnimation {
                viewModel.toggleSelection(for: option)
            }
        }) {
            HStack {
                Image(systemName: viewModel.selectedOptions.contains(optionLetter) ? "checkmark.square.fill" : "square")
                    .foregroundColor(Color.primary)
                Text(option)
                    .foregroundColor(Color.primary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                viewModel.isCorrect == true && viewModel.selectedOptions.contains(optionLetter) ? Color.green.opacity(0.3) :
                viewModel.incorrectOptions.contains(optionLetter) ? Color.red.opacity(0.3) :
                Color.clear
            )
            .cornerRadius(10)
            .shadow(radius: 5)
        }
    }
}

struct MainButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .shadow(radius: 10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct ScoreCounterView: View {
    let correctCount: Int
    let incorrectCount: Int

    var body: some View {
        HStack(spacing: 20) {
            VStack {
                Text("Правильные")
                    .font(.caption)
                Text("\(correctCount)")
                    .font(.title)
                    .bold()
                    .foregroundColor(.green)
            }
            VStack {
                Text("Неправильные")
                    .font(.caption)
                Text("\(incorrectCount)")
                    .font(.title)
                    .bold()
                    .foregroundColor(.red)
            }
        }
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}

struct TimerView: View {
    @Binding var timerText: String

    var body: some View {
        VStack {
            Text("Таймер")
                .font(.caption)
                .foregroundColor(.blue)
            Text(timerText)
                .font(.title)
                .bold()
                .foregroundColor(.blue)
        }
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}
