//
//  NetworkAssembly.swift
//  TestProjectStr
//
//  Слой: App / DI
//

import Foundation

struct NetworkAssembly: Assembly {

    func assemble(into container: DIContainer) {
        container.register(RegistrationRemoteDataSource.self, scope: .shared) { _ in
            switch AppConfiguration.backend {
            case .stub:
                return StubRegistrationRemoteDataSource()
            case .http(let baseURL):
                return HTTPRegistrationRemoteDataSource(baseURL: baseURL)
            }
        }
    }
}
