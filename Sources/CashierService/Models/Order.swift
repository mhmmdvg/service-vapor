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

    @Parent(key: "device_id")
    var device: Device

    @Parent(key: "cashier_id")
    var cashier: User

    @OptionalField(key: "complaint")
    var complaint: String?

    @Enum(key: "status")
    var status: OrderStatus

    @Field(key: "final_cost")
    var finalCost: Int64

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() {}

    func toDTO() -> OrderDTO {
        .init(
            id: self.id,
            orderCode: self.orderCode,
            qrToken: self.qrToken,
            customerID: self.$customer.id,
            deviceID: self.$device.id,
            cashierID: self.$cashier.id,
            complaint: self.complaint ?? "",
            status: self.status,
            finalCost: self.finalCost
        )
    }
}
