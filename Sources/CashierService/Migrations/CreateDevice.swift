//
//  CreateDevice.swift
//  CashierService
//
//  Created by Muhammad Vikri on 02/08/26.
//

import Fluent

struct CreateDevice: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("devices")
            .id()
            .field("customer_id", .uuid, .required, .references("customers", "id"))
            .field("brand", .string, .required)
            .field("model", .string, .required)
            .field("color", .string, .required)
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema("devices").delete()
    }
}
