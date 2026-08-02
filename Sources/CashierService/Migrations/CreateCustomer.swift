//
//  CreateCustomer.swift
//  CashierService
//
//  Created by Muhammad Vikri on 02/08/26.
//

import Fluent

struct CreateCustomer: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("customers")
            .id()
            .field("name", .string, .required)
            .field("email", .string, .required)
            .unique(on: "email")
            .field("phone", .string, .required)
            .field("address", .string, .required)
            .field("created_at", .datetime)
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema("customers").delete()
    }
}
