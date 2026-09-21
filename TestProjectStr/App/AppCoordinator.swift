//
//  AppCoordinator.swift
//  TestProjectStr
//
//  Слой: App
//

import UIKit

/// Корневой флоу. Сейчас показывает регистрацию; следующие экраны добавляются здесь
/// или в дочерних координаторах.
final class AppCoordinator: Coordinator {

    private let navigationController: UINavigationController
    private let resolver: DIResolver

    init(navigationController: UINavigationController, resolver: DIResolver) {
        self.navigationController = navigationController
        self.resolver = resolver
    }

    func start() {
        let factory = resolver.resolve(RegistrationScreenFactory.self)
        let screen = factory.makeRegistrationScreen { userID in
            // Точка расширения: здесь начинается следующий шаг онбординга.
            print("Пользователь зарегистрирован: \(userID)")
        }
        navigationController.setViewControllers([screen], animated: false)
    }
}
