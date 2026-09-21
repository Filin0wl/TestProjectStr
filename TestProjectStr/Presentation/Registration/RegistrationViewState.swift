//
//  RegistrationViewState.swift
//  TestProjectStr
//
//  Слой: Presentation / Registration
//

import Foundation

/// Полное состояние экрана регистрации. Готово к отрисовке: и UIKit, и SwiftUI
/// только раскладывают эти значения по вьюхам и ничего не вычисляют сами.
struct RegistrationViewState: Equatable {

    var fields: [FormField] = []
    var values: [FormFieldID: String] = [:]
    /// Тексты ошибок по полям — уже в том виде, в котором их показываем.
    var errors: [FormFieldID: [String]] = [:]
    /// Ошибки по полям, которых нет в текущей схеме. Показываем общим блоком, чтобы не терять их.
    var generalErrors: [String] = []
    var isSubmitting: Bool = false
    var successMessage: String?

    var isSubmitEnabled: Bool {
        !isSubmitting
    }

    var areInputsEnabled: Bool {
        !isSubmitting
    }

    func value(for field: FormFieldID) -> String {
        values[field] ?? ""
    }

    /// Несколько ошибок по одному полю показываются одной строкой через запятую.
    func errorText(for field: FormFieldID) -> String? {
        guard let messages = errors[field], !messages.isEmpty else { return nil }
        return messages.joined(separator: ", ")
    }

    var generalErrorText: String? {
        generalErrors.isEmpty ? nil : generalErrors.joined(separator: ", ")
    }
}
