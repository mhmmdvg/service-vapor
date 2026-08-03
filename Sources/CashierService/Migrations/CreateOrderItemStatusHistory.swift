//
//  CreateOrderItemStatusHistory.swift
//  CashierService
//
//  Created by Muhammad Vikri on 03/08/26.
//

import Fluent

struct CreateOrderItemStatusHistory: AsyncMigration {
    func prepare(on database: any Database) async throws {
        let status = try await database.enum("order_status").read()
        
        try await database.schema("order_item_status_history")
            .id()
            .field("order_item_id", .uuid, .required, .references("order_items", "id"))
            .field("status", status)
            .field("note", .string)
            .field("updated_by", .uuid, .required, .references("users", "id"))
            .field("created_at", .datetime)
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.enum("order_status").delete()
        try await database.schema("order_status_history").delete()
    }
}
