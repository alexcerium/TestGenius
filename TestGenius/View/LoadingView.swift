//
//  LoadingView.swift
//  TestGenius
//
//  Created by Aleksandr Matkava on 15.07.2024.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                .scaleEffect(2.0)
                .padding()
            Text("Загрузка...")
                .font(.headline)
                .foregroundColor(.blue)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground).opacity(0.8))
        .edgesIgnoringSafeArea(.all)
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
            .preferredColorScheme(.dark)
    }
}
