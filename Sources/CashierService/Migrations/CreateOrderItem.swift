//
//  CreateOrderItem.swift
//  CashierService
//
//  Created by Muhammad Vikri on 03/08/26.
//

import Fluent

struct CreateOrderItem: AsyncMigration {
    func prepare(on database: any Database) async throws {
        let status = try await database.enum("order_status")
            .case("received")
            .case("diagnosing")
            .case("inProgress")
            .case("completed")
            .create()
        
        try await database.schema("order_items")
            .id()
            .field("order_id", .uuid, .required, .references("orders", "id"))
            .field("device_id", .uuid, .required, .references("devices", "id"))
            .field("complaint", .string)
            .field("status", status)
            .field("final_cost", .int64)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.enum("order_status").delete()
        try await database.schema("order_items").delete()
    }
}
