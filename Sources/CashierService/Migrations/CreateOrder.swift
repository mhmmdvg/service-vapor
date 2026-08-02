//
//  CreateOrder.swift
//  CashierService
//
//  Created by Muhammad Vikri on 03/08/26.
//

import Fluent

struct CreateOrder: AsyncMigration {
    func prepare(on database: any Database) async throws {
        let status = try await database.enum("order_status")
            .case("received")
            .case("diagnosing")
            .case("inProgress")
            .case("completed")
            .create()
        
        try await database.schema("orders")
            .id()
            .field("order_code", .string, .required)
            .field("qr_token", .string, .required)
            .field("customer_id", .uuid, .required, .references("customers", "id"))
            .field("device_id", .uuid, .required, .references("devices", "id"))
            .field("cashier_id", .uuid, .required, .references("users", "id"))
            .field("complaint", .string)
            .field("status", status)
            .field("final_cost", .int64, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "order_code")
            .unique(on: "qr_token")
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.enum("order_status").delete()
        try await database.schema("orders").delete()
    }
}
