//
//  Payment.swift
//  CashierService
//
//  Created by Muhammad Vikri on 03/08/26.
//

import Fluent
import Foundation

enum PaymentMethods: String, Codable, CaseIterable {
    case cash
    case qris
    case card
}

final class Payment: Model, @unchecked Sendable {
    static let schema: String = "payments"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "order_id")
    var order: Order

    @Field(key: "amount")
    var amount: Int64

    @Enum(key: "method")
    var method: PaymentMethods

    @Parent(key: "cashier_id")
    var cashier: User

    @Timestamp(key: "paid_at", on: .create)
    var paidAt: Date?

    init() {}

    func toDTO() -> PaymentDTO {
        .init(
            id: self.id,
            orderID: self.$order.id,
            amount: self.amount,
            method: self.method,
            cashierID: self.$cashier.id
        )
    }
}
