//
//  HTTPRegistrationRemoteDataSource.swift
//  TestProjectStr
//
//  Слой: Data / Network
//

import Foundation

/// Боевой транспорт. Используется вместо заглушки переключением `AppConfiguration.backend`.
final class HTTPRegistrationRemoteDataSource: RegistrationRemoteDataSource {

    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(
        baseURL: URL,
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder()
    ) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = decoder
        self.encoder = encoder
    }

    func register(_ dto: RegistrationRequestDTO) async throws -> RegistrationResponseDTO {
        var request = URLRequest(url: baseURL.appending(path: "registration"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(dto)

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw RegistrationNetworkError.invalidResponse
        }

        // 422 — валидационный ответ с ошибками по полям, это не сбой транспорта.
        guard (200..<300).contains(http.statusCode) || http.statusCode == 422 else {
            throw RegistrationNetworkError.server(statusCode: http.statusCode)
        }

        return try decoder.decode(RegistrationResponseDTO.self, from: data)
    }
}
