//
//  ViewModel.swift
//  TestGenius
//
//  Created by Aleksandr Matkava on 24.05.2024.
//

import SwiftUI
import PDFKit

class QuizViewModel: ObservableObject {
    // MARK: — данные теста
    @Published private(set) var questions: [Question] = []
    @Published private(set) var answers:   [Answer]   = []

    // текущий индекс страницы (без сброса при переключении!)
    @Published var currentQuestionIndex = 0

    // состояние каждого вопроса
    @Published var selections    = [Int:Set<String>]()   // выбранные буквы
    @Published var correctness   = [Int:Bool]()          // true/false после проверки
    @Published var incorrects    = [Int:Set<String>]()   // буквы, отмеченные неверно

    @Published private(set) var correctCount   = 0
    @Published private(set) var incorrectCount = 0

    @Published var timeRemaining = 30 * 60
    @Published var isTestSelected = false

    private var timer: Timer?
    private var originalQuestions: [Question] = []

    // MARK: — загрузка и старт
    func loadPDFs() {
        guard
            let qURL = Bundle.main.url(forResource: "Questions", withExtension: "pdf"),
            let aURL = Bundle.main.url(forResource: "Answers",   withExtension: "pdf")
        else { return }

        // прочитаем весь текст
        if let qt = extractText(from: qURL) {
            originalQuestions = parseQuestions(from: qt)
            questions = originalQuestions.shuffled().prefix(30).map { $0 }
        }
        if let at = extractText(from: aURL) {
            answers = parseAnswers(from: at)
        }

        // сброс состояний
        correctCount = 0
        incorrectCount = 0
        selections.removeAll()
        correctness.removeAll()
        incorrects.removeAll()
        currentQuestionIndex = 0
        timeRemaining = 30 * 60

        startTimer()
        isTestSelected = true
    }

    // MARK: — выбор опций
    func toggleSelection(for option: String) {
        // если уже проверен — не даём менять
        if correctness[currentQuestionIndex] != nil { return }

        let letter = String(option.prefix(1))
        var sel = selections[currentQuestionIndex] ?? []
        if sel.contains(letter) { sel.remove(letter) }
        else                  { sel.insert(letter) }
        selections[currentQuestionIndex] = sel

        // автопроверка «всё верно» → авто-переход
        if let ans = answers.first(where: { $0.questionId == questions[currentQuestionIndex].id }) {
            if sel == Set(ans.correctOptions) {
                checkAnswer(autoAdvance: true)
            }
        }
    }

    // MARK: — проверка
    func checkAnswer(autoAdvance: Bool = false) {
        // выполняем один раз
        if correctness[currentQuestionIndex] != nil { return }
        guard let ans = answers.first(where: { $0.questionId == questions[currentQuestionIndex].id }) else { return }

        let sel = selections[currentQuestionIndex] ?? []
        let correctSet = Set(ans.correctOptions)

        if sel == correctSet {
            correctness[currentQuestionIndex] = true
            correctCount += 1
            if autoAdvance {
                DispatchQueue.main.asyncAfter(deadline: .now()+0.8) {
                    self.moveNext()
                }
            }
        } else {
            correctness[currentQuestionIndex] = false
            incorrectCount += 1
            incorrects[currentQuestionIndex] = sel.symmetricDifference(correctSet)
        }
    }

    func moveNext() {
        if currentQuestionIndex + 1 >= questions.count {
            endTest()
        } else {
            currentQuestionIndex += 1
        }
    }

    private func endTest() {
        stopTimer()
        currentQuestionIndex = questions.count // чтобы показать итоговый экран
    }

    // MARK: — таймер
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            guard self.timeRemaining > 0 else {
                self.timeRemaining = 0
                self.endTest()
                return
            }
            self.timeRemaining -= 1
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: — PDF & парсинг
    private func extractText(from url: URL) -> String? {
        guard let doc = PDFDocument(url: url) else { return nil }
        return (0..<doc.pageCount)
            .compactMap { doc.page(at: $0)?.string }
            .joined(separator: "\n")
    }

    private func parseQuestions(from txt: String) -> [Question] {
        let lines = txt.split(separator: "\n")
        var questions: [Question] = []
        var currentId: Int?
        var currentText = ""
        var currentOpts: [String] = []

        for raw in lines {
            let line = String(raw)
            if line.hasPrefix("Вопрос №"),
               let num = Int(line.components(separatedBy: "№")[1].trimmingCharacters(in: .whitespaces)) {
                // закончить предыдущий
                if let id = currentId {
                    questions.append(.init(id: id, text: currentText, options: currentOpts))
                }
                currentId = num
                currentText = ""
                currentOpts = []
            } else if ["a)","b)","c)","d)","e)"].contains(where: line.hasPrefix) {
                currentOpts.append(line)
            } else {
                currentText += (currentText.isEmpty ? "" : " ") + line
            }
        }
        // последний
        if let id = currentId {
            questions.append(.init(id: id, text: currentText, options: currentOpts))
        }
        return questions
    }

    private func parseAnswers(from txt: String) -> [Answer] {
        let lines = txt.split(separator: "\n")
        var answers: [Answer] = []

        for raw in lines {
            let parts = raw.split(separator: "]")
            guard parts.count == 2,
                  let num = Int(parts[0].dropFirst().trimmingCharacters(in: .whitespaces))
            else { continue }

            let opts = parts[1]
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }

            answers.append(.init(questionId: num, correctOptions: opts))
        }
        return answers
    }
}
