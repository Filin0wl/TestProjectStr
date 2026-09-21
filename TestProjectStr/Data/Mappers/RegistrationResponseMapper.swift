//
//  RegistrationResponseMapper.swift
//  TestProjectStr
//
//  Слой: Data / Mappers
//

import Foundation

enum RegistrationResponseMapper {

    /// Переводит ответ бэкенда в доменный результат.
    ///
    /// Коды ошибок и имена полей не сверяются с локальными списками: любой незнакомый код
    /// или поле проходят дальше как есть, а показывается текст, присланный сервером.
    static func map(_ dto: RegistrationResponseDTO) -> RegistrationOutcome {
        let responseErrors = dto.errors ?? []

        guard responseErrors.isEmpty else {
            var errors = FieldErrors()
            for error in responseErrors {
                errors.append(
                    ValidationMessage(code: error.code ?? "unknown", text: error.message),
                    to: FormFieldID(error.field)
                )
            }
            return .rejected(errors)
        }

        return .registered(userID: dto.userId ?? "")
    }
}
