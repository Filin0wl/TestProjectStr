//
//  RegistrationScreenFactories.swift
//  TestProjectStr
//
//  Слой: Presentation / Registration
//

import SwiftUI
import UIKit

/// Точка подмены верстки. Обе фабрики отдают `UIViewController` с одной и той же вьюмоделью,
/// поэтому переключение UIKit ↔ SwiftUI не задевает ни навигацию, ни логику.
final class UIKitRegistrationScreenFactory: RegistrationScreenFactory {

    private let makeViewModel: () -> RegistrationViewModel

    init(makeViewModel: @escaping () -> RegistrationViewModel) {
        self.makeViewModel = makeViewModel
    }

    func makeRegistrationScreen(onRegistered: @escaping (String) -> Void) -> UIViewController {
        let viewModel = makeViewModel()
        viewModel.onRegistered = onRegistered
        return RegistrationViewController(viewModel: viewModel)
    }
}

final class SwiftUIRegistrationScreenFactory: RegistrationScreenFactory {

    private let makeViewModel: () -> RegistrationViewModel

    init(makeViewModel: @escaping () -> RegistrationViewModel) {
        self.makeViewModel = makeViewModel
    }

    func makeRegistrationScreen(onRegistered: @escaping (String) -> Void) -> UIViewController {
        let viewModel = makeViewModel()
        viewModel.onRegistered = onRegistered
        return UIHostingController(rootView: RegistrationScreen(viewModel: viewModel))
    }
}
