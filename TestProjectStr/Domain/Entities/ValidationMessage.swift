//
//  ValidationMessage.swift
//  TestProjectStr
//
//  Слой: Domain / Entities
//

import Foundation

/// Одна ошибка валидации, пришедшая с бэкенда.
///
/// `code` — машинный идентификатор (может быть любым, список открыт),
/// `text` — готовый для показа текст. Приложение не переводит коды в тексты,
/// поэтому новые ошибки на бэкенде работают без релиза клиента.
struct ValidationMessage: Hashable, Sendable {
    let code: String
    let text: String

    init(code: String, text: String) {
        self.code = code
        self.text = text
    }
}

/// Набор ошибок, сгруппированных по полям.
struct FieldErrors: Equatable, Sendable {

    private var storage: [FormFieldID: [ValidationMessage]]

    init(_ storage: [FormFieldID: [ValidationMessage]] = [:]) {
        self.storage = storage
    }

    var isEmpty: Bool {
        storage.values.allSatisfy(\.isEmpty)
    }

    var fields: [FormFieldID] {
        Array(storage.keys)
    }

    subscript(field: FormFieldID) -> [ValidationMessage] {
        storage[field] ?? []
    }

    mutating func append(_ message: ValidationMessage, to field: FormFieldID) {
        storage[field, default: []].append(message)
    }

    mutating func removeMessages(for field: FormFieldID) {
        storage[field] = nil
    }
}
