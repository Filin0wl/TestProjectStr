//
//  FormField.swift
//  TestProjectStr
//
//  Слой: Domain / Entities
//

import Foundation

/// Идентификатор поля формы.
///
/// Намеренно не `enum`: бэкенд может прислать ошибку по полю, о котором приложение ещё не знает,
/// и такую ошибку нужно сохранить, а не потерять при разборе ответа.
struct FormFieldID: RawRepresentable, Hashable, Sendable {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    init(_ rawValue: String) {
        self.init(rawValue: rawValue)
    }
}

extension FormFieldID {
    static let login = FormFieldID("login")
    static let phone = FormFieldID("phone")
    static let email = FormFieldID("email")
}

/// Тип содержимого поля. Слои верстки сами решают, как отобразить: UIKit — через `UIKeyboardType`,
/// SwiftUI — через `.keyboardType`. Домен о фреймворках не знает.
enum FormFieldContentKind: Hashable, Sendable {
    case text
    case phone
    case email
}

/// Описание одного поля формы. Экран строится из массива таких описаний,
/// поэтому новое поле добавляется одной строкой в схеме, без правок верстки.
struct FormField: Identifiable, Hashable, Sendable {
    let id: FormFieldID
    let title: String
    let contentKind: FormFieldContentKind

    init(id: FormFieldID, title: String, contentKind: FormFieldContentKind = .text) {
        self.id = id
        self.title = title
        self.contentKind = contentKind
    }
}
