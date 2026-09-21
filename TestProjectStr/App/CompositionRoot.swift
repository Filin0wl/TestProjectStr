//
//  CompositionRoot.swift
//  TestProjectStr
//
//  Слой: App
//

import Foundation

/// Единственное место, где собираются все зависимости приложения.
final class CompositionRoot {

    let container: DIContainer

    init() {
        container = DIContainer(assemblies: [
            NetworkAssembly(),
            RegistrationAssembly()
        ])
    }
}
