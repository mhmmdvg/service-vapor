//
//  Order.swift
//  CashierService
//
//  Created by Muhammad Vikri on 03/08/26.
//

import Fluent
import Foundation

enum OrderStatus: String, Codable, CaseIterable {
    case received
    case diagnosing
    case inProgress
    case completed
}

final class Order: Model, @unchecked Sendable {
    static let schema: String = "orders"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "order_code")
    var orderCode: String

    @Field(key: "qr_token")
    var qrToken: String

    @Parent(key: "customer_id")
    var customer: Customer

    @Parent(key: "cashier_id")
    var cashier: User
    
    @Children(for: \.$order)
    var items: [OrderItem]

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() {}

    /// Membutuhkan relasi `customer` dan `cashier` sudah ter-load.
    func toDTO() -> OrderDTO {
        .init(
            id: self.id,
            orderCode: self.orderCode,
            qrToken: self.qrToken,
            createdAt: self.createdAt,
            customer: .init(id: self.$customer.id, name: self.customer.name),
            cashier: .init(id: self.$cashier.id, name: self.cashier.name)
        )
    }
}
