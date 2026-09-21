//
//  SceneDelegate.swift
//  TestProjectStr
//
//  Слой: App
//

import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    private var coordinator: Coordinator?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene,
              let compositionRoot = (UIApplication.shared.delegate as? AppDelegate)?.compositionRoot else {
            return
        }

        let navigationController = UINavigationController()
        navigationController.navigationBar.prefersLargeTitles = false

        let coordinator = AppCoordinator(
            navigationController: navigationController,
            resolver: compositionRoot.container
        )
        coordinator.start()

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()

        self.window = window
        self.coordinator = coordinator
    }
}
