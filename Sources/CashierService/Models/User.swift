//
//  User.swift
//  CashierService
//
//  Created by Muhammad Vikri on 02/08/26.
//

import Fluent
import Foundation

import struct Foundation.UUID

final class User: Model, @unchecked Sendable {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "email")
    var email: String

    @Field(key: "password_hash")
    var passwordHash: String

    @Enum(key: "role")
    var role: UserRole

    @OptionalField(key: "phone")
    var phone: String?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() {}

    init(
        id: UUID? = nil,
        name: String,
        email: String,
        passwordHash: String,
        role: UserRole,
        phone: String
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.passwordHash = passwordHash
        self.role = role
        self.phone = phone
    }

    func toDTO() -> UserPublicDTO {
        .init(user: self)
    }
}

enum UserRole: String, Codable, CaseIterable {
    case admin
    case cashier
}
