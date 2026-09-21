//
//  Registration.swift
//  TestProjectStr
//
//  Слой: Domain / Entities
//

import Foundation

/// Заявка на регистрацию. Хранит значения по идентификаторам полей,
/// чтобы добавление нового поля не меняло сигнатуры домена.
struct RegistrationRequest: Equatable, Sendable {
    var values: [FormFieldID: String]

    init(values: [FormFieldID: String] = [:]) {
        self.values = values
    }

    func value(for field: FormFieldID) -> String {
        values[field] ?? ""
    }
}

/// Результат обращения к бэкенду: либо регистрация прошла, либо сервер вернул ошибки по полям.
enum RegistrationOutcome: Equatable, Sendable {
    case registered(userID: String)
    case rejected(FieldErrors)
}
