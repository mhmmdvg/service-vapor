//
//  CreatePayment.swift
//  CashierService
//
//  Created by Muhammad Vikri on 03/08/26.
//

import Fluent

struct CreatePayment: AsyncMigration {
    func prepare(on database: any Database) async throws {
        let paymentMethod = try await database.enum("payment_methods")
            .case("cash")
            .case("qris")
            .case("card")
            .create()
        
        try await database.schema("payments")
            .id()
            .field("order_id", .uuid, .required, .references("orders", "id"))
            .field("amount", .int64, .required)
            .field("method", paymentMethod)
            .field("cashier_id", .uuid, .required, .references("users", "id"))
            .field("paid_at", .datetime)
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.enum("payment_methods").delete()
        try await database.schema("payments").delete()
    }
}
