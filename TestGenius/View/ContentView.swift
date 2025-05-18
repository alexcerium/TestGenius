//
//  ContentView.swift
//  TestGenius
//
//  Created by Aleksandr on 2025.05.18.
//

import SwiftUI

// MARK: – Точка входа в UI
struct ContentView: View {
    @ObservedObject var viewModel: QuizViewModel
    @State private var isLoading    = false
    @State private var showExitAlert = false

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isTestSelected {
                    QuizView(viewModel: viewModel)
                } else {
                    SelectionView(vm: viewModel, loading: $isLoading)
                }
            }
            .navigationTitle(viewModel.isTestSelected ? "Тест" : "Выберите тест")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if viewModel.isTestSelected {
                        Button("Выйти") {
                            showExitAlert = true
                        }
                    }
                }
            }
            .alert("Выйти из теста?", isPresented: $showExitAlert) {
                Button("Выйти", role: .destructive) {
                    viewModel.stopTimer()
                    viewModel.isTestSelected = false
                }
                Button("Отмена", role: .cancel) { }
            } message: {
                Text("Прогресс и ответы будут утеряны.")
            }
        }
    }
}

// MARK: – Экран выбора тестов
struct SelectionView: View {
    @ObservedObject var vm: QuizViewModel
    @Binding var loading: Bool

    // здесь можно добавить несколько тестов
    private let tests = [
        TestInfo(
            title: "Экономика фармации",
            icon: "doc.text.magnifyingglass",
            color: .blue,
            description: "30 вопросов по экономическим основам в фармации"
        )
    ]

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(tests) { test in
                        Button {
                            loading = true
                            DispatchQueue.main.asyncAfter(deadline: .now()+0.6) {
                                vm.loadPDFs()
                                loading = false
                            }
                        } label: {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(test.color)
                                        .frame(width: 50, height: 50)
                                    Image(systemName: test.icon)
                                        .foregroundColor(.white)
                                        .font(.system(size: 24))
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(test.title)
                                        .font(.headline)
                                    Text(test.description)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(.regularMaterial)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }

            if loading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView("Загрузка…")
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(12)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

private struct TestInfo: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let description: String
}

// MARK: – Экран самого теста
struct QuizView: View {
    @ObservedObject var viewModel: QuizViewModel

    private func formatTime(_ s: Int) -> String {
        let m = s / 60, sec = s % 60
        return String(format: "%02d:%02d", m, sec)
    }

    var body: some View {
        VStack(spacing: 12) {
            // Таймер
            HStack {
                Text(formatTime(viewModel.timeRemaining))
                    .font(.headline)
                    .monospacedDigit()
                Spacer()
            }
            .padding(.horizontal)

            // Прогресс бар
            ProgressView(
                value: Double(min(viewModel.currentQuestionIndex, viewModel.questions.count)),
                total: Double(viewModel.questions.count)
            )
            .padding(.horizontal)

            // Контент: либо вопрос, либо итог
            if viewModel.currentQuestionIndex < viewModel.questions.count {
                TabView(selection: $viewModel.currentQuestionIndex) {
                    ForEach(Array(viewModel.questions.enumerated()), id: \.offset) { idx, question in
                        QuestionCard(index: idx, question: question, vm: viewModel)
                            .tag(idx)
                            .padding()
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            } else {
                // Итоговый экран
                VStack(spacing: 20) {
                    Text("Тест завершён")
                        .font(.largeTitle)
                    Text("Правильных: \(viewModel.correctCount) из \(viewModel.questions.count)")
                    let pct = Int(Double(viewModel.correctCount) / Double(viewModel.questions.count) * 100)
                    Text("Процент: \(pct)%")
                        .font(.title2).bold()
                    Button("Снова пройти") {
                        viewModel.isTestSelected = false
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }

            // Кнопка Проверить/Дальше
            if viewModel.currentQuestionIndex < viewModel.questions.count {
                HStack {
                    Spacer()
                    let state = viewModel.correctness[viewModel.currentQuestionIndex]
                    let title = state == nil ? "Проверить" : (state == false ? "Дальше" : "")
                    if !title.isEmpty {
                        Button(title) {
                            if state == nil {
                                viewModel.checkAnswer()
                            } else {
                                viewModel.moveNext()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(width: 140, height: 44)
                    }
                    Spacer()
                }
                .padding(.bottom)
            }
        }
    }
}

// MARK: – Карточка вопроса
struct QuestionCard: View {
    let index: Int
    let question: Question
    @ObservedObject var vm: QuizViewModel

    private var sel: Set<String>         { vm.selections[index] ?? [] }
    private var isCorrect: Bool?        { vm.correctness[index] }
    private var incorrects: Set<String> { vm.incorrects[index] ?? [] }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Вопрос \(index+1)")
                    .font(.caption).foregroundColor(.secondary)

                Text(question.text)
                    .font(.body)
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(10)

                VStack(spacing: 8) {
                    ForEach(question.options, id: \.self) { opt in
                        OptionRow(
                            option: opt,
                            isSelected: sel.contains(String(opt.prefix(1))),
                            isCorrect: isCorrect,
                            incorrects: incorrects,
                            index: index,
                            vm: vm
                        )
                    }
                }
            }
        }
    }
}

// MARK: – Одна строка-опция
struct OptionRow: View {
    let option: String
    let isSelected: Bool
    let isCorrect: Bool?
    let incorrects: Set<String>
    let index: Int
    @ObservedObject var vm: QuizViewModel

    var body: some View {
        let letter = String(option.prefix(1))
        Button {
            vm.toggleSelection(for: option)
        } label: {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                Text(option).font(.body)
                Spacer()
            }
            .padding()
            .background(backgroundColor)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    private var backgroundColor: Color {
        if isCorrect == true && isSelected {
            return .green.opacity(0.2)
        }
        if incorrects.contains(String(option.prefix(1))) {
            return .red.opacity(0.2)
        }
        return .clear
    }
}
