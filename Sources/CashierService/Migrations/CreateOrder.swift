//
//  CreateOrder.swift
//  CashierService
//
//  Created by Muhammad Vikri on 03/08/26.
//

import Fluent

struct CreateOrder: AsyncMigration {
    func prepare(on database: any Database) async throws {
//        let status = try await database.enum("order_status")
//            .case("received")
//            .case("diagnosing")
//            .case("inProgress")
//            .case("completed")
//            .create()
        
        try await database.schema("orders")
            .id()
            .field("order_code", .string, .required)
            .field("qr_token", .string, .required)
            .field("customer_id", .uuid, .required, .references("customers", "id"))
            .field("cashier_id", .uuid, .required, .references("users", "id"))
            .field("created_at", .datetime)
            .unique(on: "order_code")
            .unique(on: "qr_token")
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema("orders").delete()
    }
}
