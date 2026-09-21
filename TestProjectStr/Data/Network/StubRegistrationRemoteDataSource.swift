//
//  StubRegistrationRemoteDataSource.swift
//  TestProjectStr
//
//  Слой: Data / Network
//

import Foundation

/// Заглушка бэкенда: держит паузу и возвращает ответ в том же формате, что и настоящий сервер.
///
/// Правила проверок живут только здесь. Клиент их не дублирует, поэтому добавление
/// новых ошибок на сервере не требует изменений в остальных слоях.
final class StubRegistrationRemoteDataSource: RegistrationRemoteDataSource {

    private let latency: Duration
    private let takenLogins: Set<String>

    init(latency: Duration = .seconds(3), takenLogins: Set<String> = ["admin", "user", "test", "stacy"]) {
        self.latency = latency
        self.takenLogins = takenLogins
    }

    func register(_ dto: RegistrationRequestDTO) async throws -> RegistrationResponseDTO {
        try await Task.sleep(for: latency)

        var errors: [RegistrationResponseDTO.FieldError] = []
        errors.append(contentsOf: loginErrors(dto.fields[FormFieldID.login.rawValue] ?? ""))
        errors.append(contentsOf: phoneErrors(dto.fields[FormFieldID.phone.rawValue] ?? ""))
        errors.append(contentsOf: emailErrors(dto.fields[FormFieldID.email.rawValue] ?? ""))

        guard errors.isEmpty else {
            return RegistrationResponseDTO(status: "validation_error", errors: errors)
        }

        return RegistrationResponseDTO(status: "ok", userId: UUID().uuidString)
    }

    // MARK: - Правила заглушки

    private func loginErrors(_ login: String) -> [RegistrationResponseDTO.FieldError] {
        var errors: [RegistrationResponseDTO.FieldError] = []

        if login.isEmpty {
            errors.append(.init(field: FormFieldID.login.rawValue, code: "login_required", message: "Обязательное поле"))
            return errors
        }

        if login.count < 3 {
            errors.append(.init(field: FormFieldID.login.rawValue, code: "login_too_short", message: "Минимум 3 символа"))
        }

        if takenLogins.contains(login.lowercased()) {
            errors.append(.init(field: FormFieldID.login.rawValue, code: "login_taken", message: "Введен существующий логин"))
        }

        return errors
    }

    private func phoneErrors(_ phone: String) -> [RegistrationResponseDTO.FieldError] {
        var errors: [RegistrationResponseDTO.FieldError] = []
        let digits = phone.filter(\.isNumber)

        if digits.isEmpty {
            errors.append(.init(field: FormFieldID.phone.rawValue, code: "phone_required", message: "Обязательное поле"))
            return errors
        }

        if digits.count != 11 {
            errors.append(.init(field: FormFieldID.phone.rawValue, code: "phone_length", message: "Длина должна быть 11 цифр"))
        }

        if !Self.knownPhonePrefixes.contains(where: digits.hasPrefix) {
            errors.append(.init(field: FormFieldID.phone.rawValue, code: "phone_not_found", message: "Несуществующий номер"))
        }

        return errors
    }

    private func emailErrors(_ email: String) -> [RegistrationResponseDTO.FieldError] {
        if email.isEmpty {
            return [.init(field: FormFieldID.email.rawValue, code: "email_required", message: "Обязательное поле")]
        }

        guard email.wholeMatch(of: Self.emailPattern) != nil else {
            return [.init(field: FormFieldID.email.rawValue, code: "email_format", message: "Неверный формат")]
        }

        return []
    }

    private static let knownPhonePrefixes = ["79", "89"]

    private static let emailPattern = /[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}/
}
