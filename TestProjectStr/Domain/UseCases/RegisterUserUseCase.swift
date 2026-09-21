//
//  RegisterUserUseCase.swift
//  TestProjectStr
//
//  Слой: Domain / UseCases
//

import Foundation

protocol RegisterUserUseCase: AnyObject {
    func execute(_ request: RegistrationRequest) async throws -> RegistrationOutcome
}

final class DefaultRegisterUserUseCase: RegisterUserUseCase {

    private let repository: RegistrationRepository

    init(repository: RegistrationRepository) {
        self.repository = repository
    }

    func execute(_ request: RegistrationRequest) async throws -> RegistrationOutcome {
        try await repository.register(normalized(request))
    }

    /// Обрезаем пробелы по краям — это единственная клиентская обработка,
    /// решение о валидности принимает бэкенд.
    private func normalized(_ request: RegistrationRequest) -> RegistrationRequest {
        var request = request
        request.values = request.values.mapValues { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        return request
    }
}
