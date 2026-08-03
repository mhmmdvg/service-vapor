//
//  CreateOrderPart.swift
//  CashierService
//
//  Created by Muhammad Vikri on 03/08/26.
//

import Fluent

struct CreateOrderPart: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("order_parts")
            .id()
            .field("order_item_id", .uuid, .required, .references("order_items", "id"))
            .field("spare_part_id", .uuid, .required, .references("spare_parts", "id"))
            .field("qty", .int, .required)
            .field("price_at_use", .int64, .required)
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema("order_parts").delete()
    }
}
