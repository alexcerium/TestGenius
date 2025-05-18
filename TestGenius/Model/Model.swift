//
//  Model.swift
//  TestGenius
//
//  Created by Aleksandr Matkava on 24.05.2024.
//

import Foundation

struct Question: Identifiable {
    let id: Int
    let text: String
    let options: [String]
}

struct Answer {
    let questionId: Int
    let correctOptions: [String]
}
