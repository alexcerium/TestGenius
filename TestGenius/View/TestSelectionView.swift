//
//  TestSelectionView.swift
//  TestGenius
//
//  Created by Aleksandr Matkava on 15.07.2024.
//

import SwiftUI

struct TestSelectionView: View {
    @ObservedObject var viewModel: QuizViewModel
    @Binding var showLoading: Bool

    var body: some View {
        NavigationView {
            VStack {
                Text("Все тесты")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                    .padding(.bottom, 10)

                List {
                    Button(action: {
                        withAnimation {
                            showLoading = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            viewModel.loadQuestionsAndAnswers()
                            withAnimation {
                                viewModel.isTestSelected = true
                                showLoading = false
                            }
                        }
                    }) {
                        Text("Тест по экономике фармации")
                            .font(.title2)
                            .padding(.top, 10)
                            .padding(.bottom, 10)
                    }
                }
            }
        }
    }
}
