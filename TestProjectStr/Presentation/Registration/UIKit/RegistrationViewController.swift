//
//  RegistrationViewController.swift
//  TestProjectStr
//
//  Слой: Presentation / Registration / UIKit
//

import Combine
import UIKit

final class RegistrationViewController: UIViewController {

    private let viewModel: RegistrationViewModel
    private var cancellables = Set<AnyCancellable>()

    private let scrollView = UIScrollView()
    private let fieldsStack = UIStackView()
    private let generalErrorLabel = UILabel()
    private let bottomBar = UIView()
    private let submitButton = PrimaryButton(title: Strings.Registration.submit)

    private var fieldViews: [FormFieldID: FormFieldView] = [:]
    private var renderedFields: [FormField] = []

    init(viewModel: RegistrationViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Strings.Registration.title
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .systemBackground

        setUpSubviews()
        setUpLayout()
        bind()
    }

    // MARK: - Верстка

    private func setUpSubviews() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        scrollView.alwaysBounceVertical = true

        fieldsStack.axis = .vertical
        fieldsStack.spacing = 20
        fieldsStack.translatesAutoresizingMaskIntoConstraints = false

        generalErrorLabel.font = .preferredFont(forTextStyle: .footnote)
        generalErrorLabel.adjustsFontForContentSizeCategory = true
        generalErrorLabel.textColor = .systemRed
        generalErrorLabel.numberOfLines = 0
        generalErrorLabel.isHidden = true

        bottomBar.backgroundColor = .systemBackground
        bottomBar.translatesAutoresizingMaskIntoConstraints = false

        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        submitButton.accessibilityIdentifier = "registration.submit"

        scrollView.addSubview(fieldsStack)
        bottomBar.addSubview(submitButton)
        view.addSubview(scrollView)
        view.addSubview(bottomBar)

        fieldsStack.addArrangedSubview(generalErrorLabel)

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    private func setUpLayout() {
        let contentGuide = scrollView.contentLayoutGuide
        let frameGuide = scrollView.frameLayoutGuide

        // Нижняя панель прижата к safe area, но поднимается вместе с клавиатурой.
        let restingBottom = bottomBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        restingBottom.priority = .defaultHigh

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),

            fieldsStack.topAnchor.constraint(equalTo: contentGuide.topAnchor, constant: 24),
            fieldsStack.leadingAnchor.constraint(equalTo: contentGuide.leadingAnchor, constant: 16),
            fieldsStack.trailingAnchor.constraint(equalTo: contentGuide.trailingAnchor, constant: -16),
            fieldsStack.bottomAnchor.constraint(equalTo: contentGuide.bottomAnchor, constant: -24),
            fieldsStack.widthAnchor.constraint(equalTo: frameGuide.widthAnchor, constant: -32),

            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(lessThanOrEqualTo: view.keyboardLayoutGuide.topAnchor, constant: -16),
            restingBottom,

            submitButton.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: 12),
            submitButton.bottomAnchor.constraint(equalTo: bottomBar.bottomAnchor),
            submitButton.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 16),
            submitButton.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -16)
        ])
    }

    // MARK: - Связывание

    private func bind() {
        viewModel.$state
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.render(state)
            }
            .store(in: &cancellables)
    }

    private func render(_ state: RegistrationViewState) {
        if renderedFields != state.fields {
            rebuildFields(state.fields)
        }

        for field in state.fields {
            fieldViews[field.id]?.apply(
                value: state.value(for: field.id),
                errorText: state.errorText(for: field.id),
                isEnabled: state.areInputsEnabled
            )
        }

        generalErrorLabel.text = state.generalErrorText
        generalErrorLabel.isHidden = state.generalErrorText == nil

        submitButton.isLoading = state.isSubmitting
        submitButton.isEnabled = state.isSubmitEnabled

        if let message = state.successMessage {
            presentSuccess(message)
        }
    }

    private func rebuildFields(_ fields: [FormField]) {
        fieldViews.values.forEach { $0.removeFromSuperview() }
        fieldViews.removeAll()

        for (index, field) in fields.enumerated() {
            let fieldView = FormFieldView()
            fieldView.configure(with: field)
            fieldView.onTextChanged = { [weak self] text in
                self?.viewModel.valueChanged(text, for: field.id)
            }
            fieldView.onReturn = { [weak self] in
                self?.focusField(after: index)
            }
            fieldViews[field.id] = fieldView
            fieldsStack.insertArrangedSubview(fieldView, at: index)
        }

        renderedFields = fields
    }

    private func focusField(after index: Int) {
        let nextIndex = index + 1
        guard nextIndex < renderedFields.count,
              let nextView = fieldViews[renderedFields[nextIndex].id] else {
            dismissKeyboard()
            return
        }
        nextView.becomeFirstResponder()
    }

    private func presentSuccess(_ message: String) {
        guard presentedViewController == nil else { return }

        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Strings.Registration.okAction, style: .default) { [weak self] _ in
            self?.viewModel.acknowledgeSuccess()
        })
        present(alert, animated: true)
    }

    // MARK: - Действия

    @objc private func submitTapped() {
        dismissKeyboard()
        viewModel.submit()
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}
