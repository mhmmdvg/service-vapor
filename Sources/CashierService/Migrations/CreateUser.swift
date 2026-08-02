//
//  CreateUser.swift
//  CashierService
//
//  Created by Muhammad Vikri on 02/08/26.
//

import Fluent

struct CreateUser: AsyncMigration {
    func prepare(on database: any Database) async throws {
        let role = try await database.enum("user_role")
            .case("admin")
            .case("cashier")
            .create()
        
        try await database.schema("users")
            .id()
            .field("name", .string, .required)
            .field("email", .string, .required)
            .unique(on: "email")
            .field("role", role, .required)
            .field("password_hash", .string, .required)
            .field("phone", .string)
            .field("created_at", .datetime)
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema("users").delete()
        try await database.enum("user_role").delete()
    }
}
