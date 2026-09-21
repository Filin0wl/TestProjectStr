//
//  PrimaryButton.swift
//  TestProjectStr
//
//  Слой: Presentation / Registration / UIKit
//

import UIKit

/// Основная кнопка экрана. В состоянии загрузки показывает индикатор и не реагирует на нажатия.
final class PrimaryButton: UIButton {

    var isLoading = false {
        didSet {
            guard isLoading != oldValue else { return }
            setNeedsUpdateConfiguration()
        }
    }

    private let title: String

    init(title: String) {
        self.title = title
        super.init(frame: .zero)

        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.cornerStyle = .large
        configuration.buttonSize = .large
        self.configuration = configuration

        configurationUpdateHandler = { [weak self] button in
            guard let self else { return }
            var configuration = button.configuration
            configuration?.title = self.isLoading ? nil : self.title
            configuration?.showsActivityIndicator = self.isLoading
            button.configuration = configuration
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
