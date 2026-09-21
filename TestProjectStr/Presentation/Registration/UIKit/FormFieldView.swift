//
//  FormFieldView.swift
//  TestProjectStr
//
//  Слой: Presentation / Registration / UIKit
//

import UIKit

/// Поле ввода с заголовком, который поднимается над полем при фокусе,
/// и подписью ошибки под полем.
final class FormFieldView: UIView {

    var onTextChanged: ((String) -> Void)?
    var onReturn: (() -> Void)?

    private(set) var fieldID: FormFieldID = FormFieldID("")

    private let titleLabel = UILabel()
    private let inputContainer = UIView()
    private let textField = UITextField()
    private let errorLabel = UILabel()
    private let stack = UIStackView()

    private var title = ""
    private var hasError = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpSubviews()
        setUpLayout()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: FormFieldView, _) in
            view.updateBorder()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Конфигурация

    func configure(with field: FormField) {
        fieldID = field.id
        title = field.title
        titleLabel.text = field.title
        textField.placeholder = field.title
        textField.keyboardType = field.contentKind.keyboardType
        textField.textContentType = field.contentKind.textContentType
        textField.autocapitalizationType = field.contentKind.autocapitalization
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.returnKeyType = .next
        accessibilityIdentifier = "field.\(field.id.rawValue)"
    }

    func apply(value: String, errorText: String?, isEnabled: Bool) {
        if textField.text != value {
            textField.text = value
        }

        hasError = errorText != nil
        errorLabel.text = errorText
        setErrorVisible(errorText != nil)

        textField.isEnabled = isEnabled
        alpha = isEnabled ? 1 : 0.5

        updateTitlePosition(animated: false)
        updateBorder()
    }

    @discardableResult
    override func becomeFirstResponder() -> Bool {
        textField.becomeFirstResponder()
    }

    @discardableResult
    override func resignFirstResponder() -> Bool {
        textField.resignFirstResponder()
    }

    // MARK: - Верстка

    private func setUpSubviews() {
        titleLabel.font = .preferredFont(forTextStyle: .footnote)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = .secondaryLabel
        titleLabel.alpha = 0

        textField.font = .preferredFont(forTextStyle: .body)
        textField.adjustsFontForContentSizeCategory = true
        textField.delegate = self
        textField.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
        textField.translatesAutoresizingMaskIntoConstraints = false

        inputContainer.layer.cornerRadius = 12
        inputContainer.layer.borderWidth = 1
        inputContainer.addSubview(textField)

        errorLabel.font = .preferredFont(forTextStyle: .footnote)
        errorLabel.adjustsFontForContentSizeCategory = true
        errorLabel.textColor = .systemRed
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true

        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        [titleLabel, inputContainer, errorLabel].forEach(stack.addArrangedSubview)
        addSubview(stack)
    }

    private func setUpLayout() {
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),

            textField.topAnchor.constraint(equalTo: inputContainer.topAnchor, constant: 14),
            textField.bottomAnchor.constraint(equalTo: inputContainer.bottomAnchor, constant: -14),
            textField.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 12),
            textField.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -12)
        ])

        // Место под заголовок занято всегда, иначе форма прыгает при фокусе.
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    // MARK: - Состояния

    private var isTitleFloating: Bool {
        textField.isFirstResponder || !(textField.text ?? "").isEmpty
    }

    private func updateTitlePosition(animated: Bool) {
        let floating = isTitleFloating
        let changes = {
            self.titleLabel.alpha = floating ? 1 : 0
            self.textField.placeholder = floating ? nil : self.title
        }

        guard animated else {
            changes()
            return
        }

        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseOut, .beginFromCurrentState]) {
            changes()
        }
    }

    private func setErrorVisible(_ isVisible: Bool) {
        guard errorLabel.isHidden == isVisible else { return }
        errorLabel.isHidden = !isVisible
    }

    private func updateBorder() {
        let color: UIColor
        if hasError {
            color = .systemRed
        } else if textField.isFirstResponder {
            color = tintColor
        } else {
            color = .separator
        }
        inputContainer.layer.borderColor = color.resolvedColor(with: traitCollection).cgColor
    }

    @objc private func editingChanged() {
        onTextChanged?(textField.text ?? "")
        updateTitlePosition(animated: true)
    }
}

// MARK: - UITextFieldDelegate

extension FormFieldView: UITextFieldDelegate {

    func textFieldDidBeginEditing(_ textField: UITextField) {
        updateTitlePosition(animated: true)
        updateBorder()
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        updateTitlePosition(animated: true)
        updateBorder()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        onReturn?()
        return true
    }
}

// MARK: - Домен → UIKit

private extension FormFieldContentKind {

    var keyboardType: UIKeyboardType {
        switch self {
        case .text: .default
        case .phone: .phonePad
        case .email: .emailAddress
        }
    }

    var textContentType: UITextContentType? {
        switch self {
        case .text: .username
        case .phone: .telephoneNumber
        case .email: .emailAddress
        }
    }

    var autocapitalization: UITextAutocapitalizationType {
        .none
    }
}
