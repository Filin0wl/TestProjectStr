//
//  AppConfiguration.swift
//  TestProjectStr
//
//  Слой: App
//

import Foundation

enum UIFramework {
    case uiKit
    case swiftUI
}

enum BackendKind {
    /// Заглушка: отвечает через 3 секунды.
    case stub
    /// Боевой HTTP-бэкенд.
    case http(baseURL: URL)
}

/// Переключатели сборки. Смена верстки на SwiftUI — это ровно одна строка ниже.
enum AppConfiguration {
    static let uiFramework: UIFramework = .uiKit
    static let backend: BackendKind = .stub
}
