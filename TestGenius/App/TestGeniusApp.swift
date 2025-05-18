//
//  TestGeniusApp.swift
//  TestGenius
//
//  Created by Aleksandr Matkava on 24.05.2024.
//

import SwiftUI

@main
struct TestGeniusApp: App {
    @StateObject private var vm = QuizViewModel()
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: vm)
        }
    }
}
