//
//  RegistrationDTO.swift
//  TestProjectStr
//
//  Слой: Data / DTO
//

import Foundation

struct RegistrationRequestDTO: Encodable, Sendable {
    let fields: [String: String]
}

struct RegistrationResponseDTO: Decodable, Sendable {

    struct FieldError: Decodable, Sendable {
        let field: String
        let code: String?
        let message: String
    }

    let status: String
    let userId: String?
    let errors: [FieldError]?

    init(status: String, userId: String? = nil, errors: [FieldError]? = nil) {
        self.status = status
        self.userId = userId
        self.errors = errors
    }
}
