//
//  QuestionPickerView.swift
//  TestGenius
//
//  Created by Aleksandr Matkava on 15.07.2024.
//

import SwiftUI

struct QuestionPickerView: View {
    @ObservedObject var viewModel: QuizViewModel
    @Binding var showPicker: Bool
    var resetTimer: () -> Void
    @State private var showAlert = false
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(0..<viewModel.questions.count, id: \.self) { index in
                        Button(action: {
                            viewModel.currentQuestionIndex = index
                            showPicker = false
                        }) {
                            HStack {
                                Text("Вопрос № \(index + 1)")
                                    .foregroundColor(.blue)
                                Spacer()
                                if index == viewModel.currentQuestionIndex {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                .navigationBarTitle("Выберите вопрос", displayMode: .inline)
                .navigationBarItems(trailing: Button("Закрыть") {
                    showPicker = false
                }
                .foregroundColor(.red))
                
                HStack {
                    Button(action: {
                        showAlert = true
                    }) {
                        Text("Завершить тест")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .cornerRadius(10)
                            .padding(.bottom, 20)
                    }
                    .alert(isPresented: $showAlert) {
                        Alert(
                            title: Text("Завершить тест?"),
                            message: Text("Вы действительно хотите завершить тест?"),
                            primaryButton: .destructive(Text("Завершить")) {
                                viewModel.resetTest()
                                viewModel.isTestSelected = false
                                resetTimer()
                                showPicker = false
                            },
                            secondaryButton: .cancel(Text("Отмена"))
                        )
                    }
                    
                    Button(action: {
                        viewModel.resetTest()
                        resetTimer()
                        showPicker = false
                    }) {
                        Text("Заново")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                            .padding(.bottom, 20)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}
