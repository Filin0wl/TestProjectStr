//
//  Coordinator.swift
//  TestProjectStr
//
//  Слой: Core / Navigation
//

import UIKit

protocol Coordinator: AnyObject {
    func start()
}

/// Экраны отдаются наружу как `UIViewController` независимо от того, на чём они свёрстаны:
/// SwiftUI-экран приходит завёрнутым в `UIHostingController`, поэтому навигация не меняется.
protocol RegistrationScreenFactory: AnyObject {
    func makeRegistrationScreen(onRegistered: @escaping (String) -> Void) -> UIViewController
}
