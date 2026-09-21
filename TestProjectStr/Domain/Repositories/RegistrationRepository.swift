//
//  RegistrationRepository.swift
//  TestProjectStr
//
//  Слой: Domain / Repositories
//

import Foundation

/// Контракт доступа к данным регистрации. Реализация живёт в слое Data.
protocol RegistrationRepository: AnyObject {
    func register(_ request: RegistrationRequest) async throws -> RegistrationOutcome
}

/// Источник схемы формы. Сейчас схема статическая, позже её можно отдавать с бэкенда,
/// подменив реализацию в ассамблее.
protocol RegistrationFormSchemaProvider: AnyObject {
    func schema() -> [FormField]
}
