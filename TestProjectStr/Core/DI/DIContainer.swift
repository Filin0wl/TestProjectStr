//
//  DIContainer.swift
//  TestProjectStr
//
//  Слой: Core / DI
//

import Foundation

/// Читающая часть контейнера. Модули зависят только от неё, а не от конкретного `DIContainer`.
protocol DIResolver: AnyObject {
    func resolve<Service>(_ type: Service.Type) -> Service
    func resolveIfRegistered<Service>(_ type: Service.Type) -> Service?
}

extension DIResolver {
    func resolve<Service>() -> Service {
        resolve(Service.self)
    }
}

/// Время жизни зарегистрированной зависимости.
enum DIScope {
    /// Новый экземпляр на каждый `resolve`.
    case transient
    /// Один экземпляр на весь контейнер.
    case shared
}

/// Модуль регистрации зависимостей. Новая фича добавляет свою ассамблею и не трогает чужие.
protocol Assembly {
    func assemble(into container: DIContainer)
}

final class DIContainer: DIResolver {

    private struct Registration {
        let scope: DIScope
        let factory: (DIResolver) -> Any
    }

    private var registrations: [ObjectIdentifier: Registration] = [:]
    private var sharedInstances: [ObjectIdentifier: Any] = [:]

    init(assemblies: [Assembly] = []) {
        apply(assemblies)
    }

    func apply(_ assemblies: [Assembly]) {
        for assembly in assemblies {
            assembly.assemble(into: self)
        }
    }

    func register<Service>(
        _ type: Service.Type,
        scope: DIScope = .transient,
        factory: @escaping (DIResolver) -> Service
    ) {
        registrations[ObjectIdentifier(type)] = Registration(scope: scope) { resolver in
            factory(resolver)
        }
    }

    func resolve<Service>(_ type: Service.Type) -> Service {
        guard let service = resolveIfRegistered(type) else {
            preconditionFailure("Зависимость \(type) не зарегистрирована. Добавьте её в соответствующую Assembly.")
        }
        return service
    }

    func resolveIfRegistered<Service>(_ type: Service.Type) -> Service? {
        let key = ObjectIdentifier(type)

        if let shared = sharedInstances[key] as? Service {
            return shared
        }

        guard let registration = registrations[key],
              let service = registration.factory(self) as? Service else {
            return nil
        }

        if registration.scope == .shared {
            sharedInstances[key] = service
        }

        return service
    }
}
