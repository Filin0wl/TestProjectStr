//
//  RegistrationAssembly.swift
//  TestProjectStr
//
//  Слой: App / DI
//

import Foundation

/// Регистрация зависимостей фичи «Регистрация». Новая фича добавляет свою ассамблею рядом.
struct RegistrationAssembly: Assembly {

    func assemble(into container: DIContainer) {
        container.register(RegistrationFormSchemaProvider.self, scope: .shared) { _ in
            StaticRegistrationFormSchemaProvider()
        }

        container.register(RegistrationRepository.self, scope: .shared) { resolver in
            DefaultRegistrationRepository(remote: resolver.resolve(RegistrationRemoteDataSource.self))
        }

        container.register(RegisterUserUseCase.self) { resolver in
            DefaultRegisterUserUseCase(repository: resolver.resolve(RegistrationRepository.self))
        }

        container.register(RegistrationScreenFactory.self, scope: .shared) { resolver in
            let makeViewModel: () -> RegistrationViewModel = {
                RegistrationViewModel(
                    registerUser: resolver.resolve(RegisterUserUseCase.self),
                    schemaProvider: resolver.resolve(RegistrationFormSchemaProvider.self)
                )
            }

            switch AppConfiguration.uiFramework {
            case .uiKit:
                return UIKitRegistrationScreenFactory(makeViewModel: makeViewModel)
            case .swiftUI:
                return SwiftUIRegistrationScreenFactory(makeViewModel: makeViewModel)
            }
        }
    }
}
