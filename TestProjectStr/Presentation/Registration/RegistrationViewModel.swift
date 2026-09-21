//
//  RegistrationViewModel.swift
//  TestProjectStr
//
//  Слой: Presentation / Registration
//

import Combine
import Foundation

/// Вся логика экрана. Не импортирует ни UIKit, ни SwiftUI, поэтому одна и та же вьюмодель
/// обслуживает обе верстки: UIKit подписывается через Combine, SwiftUI — как на `ObservableObject`.
@MainActor
final class RegistrationViewModel: ObservableObject {

    @Published private(set) var state: RegistrationViewState

    /// Вызывается после успешной регистрации, навигацию решает координатор.
    var onRegistered: ((String) -> Void)?

    private let registerUser: RegisterUserUseCase
    private var submitTask: Task<Void, Never>?

    init(registerUser: RegisterUserUseCase, schemaProvider: RegistrationFormSchemaProvider) {
        self.registerUser = registerUser

        let fields = schemaProvider.schema()
        var state = RegistrationViewState()
        state.fields = fields
        state.values = Dictionary(uniqueKeysWithValues: fields.map { ($0.id, "") })
        self.state = state
    }

    // MARK: - Ввод

    func valueChanged(_ text: String, for field: FormFieldID) {
        guard state.value(for: field) != text else { return }

        state.values[field] = text

        // При повторном вводе ошибки поля уходят.
        if state.errors[field] != nil {
            state.errors[field] = nil
        }
        if !state.generalErrors.isEmpty {
            state.generalErrors = []
        }
    }

    // MARK: - Отправка

    func submit() {
        // Пока запрос в полёте, второй не стартуем — кнопка в это время ещё и заблокирована в UI.
        guard submitTask == nil else { return }

        state.isSubmitting = true
        state.errors = [:]
        state.generalErrors = []
        state.successMessage = nil

        let request = RegistrationRequest(values: state.values)

        submitTask = Task { [weak self] in
            guard let self else { return }
            defer {
                self.submitTask = nil
                self.state.isSubmitting = false
            }

            do {
                let outcome = try await self.registerUser.execute(request)
                self.handle(outcome)
            } catch is CancellationError {
                // Экран закрыли — показывать нечего.
            } catch {
                self.state.generalErrors = [Strings.Registration.networkFailure]
            }
        }
    }

    func acknowledgeSuccess() {
        state.successMessage = nil
    }

    func cancelSubmission() {
        submitTask?.cancel()
        submitTask = nil
    }

    // MARK: - Результат

    private func handle(_ outcome: RegistrationOutcome) {
        switch outcome {
        case .registered(let userID):
            state.errors = [:]
            state.generalErrors = []
            state.successMessage = Strings.Registration.success
            onRegistered?(userID)

        case .rejected(let fieldErrors):
            let knownFields = Set(state.fields.map(\.id))
            var errors: [FormFieldID: [String]] = [:]
            var generalErrors: [String] = []

            for field in fieldErrors.fields {
                let texts = fieldErrors[field].map(\.text)
                guard !texts.isEmpty else { continue }

                if knownFields.contains(field) {
                    errors[field] = texts
                } else {
                    // Поле, о котором приложение пока не знает: текст всё равно показываем.
                    generalErrors.append(contentsOf: texts)
                }
            }

            state.errors = errors
            state.generalErrors = generalErrors
        }
    }
}
