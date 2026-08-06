//
//  OrderItem.swift
//  CashierService
//
//  Created by Muhammad Vikri on 03/08/26.
//

import Fluent
import Foundation

final class OrderItem: Model, @unchecked Sendable {
    static let schema: String = "order_items"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "order_id")
    var order: Order

    @Parent(key: "device_id")
    var device: Device

    @OptionalField(key: "complaint")
    var complaint: String?

    @Enum(key: "status")
    var status: OrderStatus
    
    @Children(for: \.$orderItem)
    var statusHistory: [OrderItemStatusHistory]

    @OptionalField(key: "final_cost")
    var finalCost: Int64?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() {}

    func toDTO() -> OrderItemDTO {
        .init(
            id: self.id,
            orderID: self.$order.id,
            deviceID: self.$device.id,
            complaint: self.complaint,
            status: self.status,
            finalCost: self.finalCost
        )
    }
}
