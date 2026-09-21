//
//  RegistrationScreen.swift
//  TestProjectStr
//
//  Слой: Presentation / Registration / SwiftUI
//

import SwiftUI

/// SwiftUI-верстка того же экрана. Работает с той же `RegistrationViewModel`,
/// что и UIKit-версия: логика не продублирована.
struct RegistrationScreen: View {

    @ObservedObject var viewModel: RegistrationViewModel
    @FocusState private var focusedField: FormFieldID?

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(viewModel.state.fields) { field in
                        FloatingLabelField(
                            field: field,
                            text: binding(for: field.id),
                            errorText: viewModel.state.errorText(for: field.id),
                            focusedField: $focusedField
                        )
                    }

                    if let generalErrorText = viewModel.state.generalErrorText {
                        Text(generalErrorText)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .disabled(!viewModel.state.areInputsEnabled)

            submitButton
        }
        .navigationTitle(Strings.Registration.title)
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            viewModel.state.successMessage ?? "",
            isPresented: Binding(
                get: { viewModel.state.successMessage != nil },
                set: { isPresented in
                    if !isPresented { viewModel.acknowledgeSuccess() }
                }
            )
        ) {
            Button(Strings.Registration.okAction, role: .cancel) {
                viewModel.acknowledgeSuccess()
            }
        }
    }

    private var submitButton: some View {
        Button {
            focusedField = nil
            viewModel.submit()
        } label: {
            ZStack {
                Text(Strings.Registration.submit)
                    .opacity(viewModel.state.isSubmitting ? 0 : 1)

                if viewModel.state.isSubmitting {
                    ProgressView()
                        .tint(.white)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(!viewModel.state.isSubmitEnabled)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.background)
    }

    private func binding(for field: FormFieldID) -> Binding<String> {
        Binding(
            get: { viewModel.state.value(for: field) },
            set: { viewModel.valueChanged($0, for: field) }
        )
    }
}

/// Поле с заголовком, который появляется над полем при фокусе.
private struct FloatingLabelField: View {

    let field: FormField
    @Binding var text: String
    let errorText: String?
    @FocusState.Binding var focusedField: FormFieldID?

    private var isFloating: Bool {
        focusedField == field.id || !text.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(field.title)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .opacity(isFloating ? 1 : 0)
                .animation(.easeOut(duration: 0.2), value: isFloating)

            TextField(isFloating ? "" : field.title, text: $text)
                .focused($focusedField, equals: field.id)
                .keyboardType(field.contentKind.keyboardType)
                .textContentType(field.contentKind.textContentType)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.horizontal, 12)
                .padding(.vertical, 14)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(borderColor, lineWidth: 1)
                )

            if let errorText {
                Text(errorText)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
    }

    private var borderColor: Color {
        if errorText != nil {
            return .red
        }
        return focusedField == field.id ? .accentColor : Color(uiColor: .separator)
    }
}

// MARK: - Домен → SwiftUI

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
}
