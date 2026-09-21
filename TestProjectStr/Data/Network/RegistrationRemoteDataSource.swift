//
//  RegistrationRemoteDataSource.swift
//  TestProjectStr
//
//  Слой: Data / Network
//

import Foundation

/// Транспорт регистрации. Заглушка и реальный HTTP-клиент взаимозаменяемы:
/// подмена делается одной строкой в `NetworkAssembly`.
protocol RegistrationRemoteDataSource: AnyObject {
    func register(_ dto: RegistrationRequestDTO) async throws -> RegistrationResponseDTO
}

enum RegistrationNetworkError: Error {
    case invalidResponse
    case server(statusCode: Int)
}
