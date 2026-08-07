//
//  AddServiceFeeToOrderItem.swift
//  CashierService
//
//  Created by Muhammad Vikri on 07/08/26.
//

import Fluent

struct AddServiceFeeToOrderItem: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("order_items")
            .field("service_fee", .int64)
            .update()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("order_items")
            .deleteField("service_fee")
            .update()
    }
}
