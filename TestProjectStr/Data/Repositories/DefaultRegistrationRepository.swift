//
//  DefaultRegistrationRepository.swift
//  TestProjectStr
//
//  Слой: Data / Repositories
//

import Foundation

final class DefaultRegistrationRepository: RegistrationRepository {

    private let remote: RegistrationRemoteDataSource

    init(remote: RegistrationRemoteDataSource) {
        self.remote = remote
    }

    func register(_ request: RegistrationRequest) async throws -> RegistrationOutcome {
        let fields = Dictionary(
            uniqueKeysWithValues: request.values.map { ($0.key.rawValue, $0.value) }
        )
        let response = try await remote.register(RegistrationRequestDTO(fields: fields))
        return RegistrationResponseMapper.map(response)
    }
}
