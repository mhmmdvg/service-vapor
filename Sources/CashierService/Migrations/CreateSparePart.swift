//
//  CreateSparePart.swift
//  CashierService
//
//  Created by Muhammad Vikri on 03/08/26.
//

import Fluent

struct CreateSparePart: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("spare_parts")
            .id()
            .field("name", .string, .required)
            .field("stock", .int, .required)
            .field("cost_price", .int64, .required)
            .field("sell_price", .int64, .required)
            .field("sku", .string, .required)
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema("spare_parts").delete()
    }
}
