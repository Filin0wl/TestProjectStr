//
//  StaticRegistrationFormSchemaProvider.swift
//  TestProjectStr
//
//  Слой: Data / Repositories
//

import Foundation

/// Схема формы, зашитая в приложение. Чтобы добавить поле, достаточно дописать элемент —
/// верстка, отправка запроса и разбор ошибок подхватят его автоматически.
final class StaticRegistrationFormSchemaProvider: RegistrationFormSchemaProvider {

    func schema() -> [FormField] {
        [
            FormField(id: .login, title: "Логин", contentKind: .text),
            FormField(id: .phone, title: "Номер телефона", contentKind: .phone),
            FormField(id: .email, title: "Email", contentKind: .email)
        ]
    }
}
