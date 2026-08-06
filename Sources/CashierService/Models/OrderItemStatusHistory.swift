//
//  OrderItemStatusHistory.swift
//  CashierService
//
//  Created by Muhammad Vikri on 03/08/26.
//

import Fluent
import Foundation

final class OrderItemStatusHistory: Model, @unchecked Sendable {
    static let schema: String = "order_item_status_history"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "order_item_id")
    var orderItem: OrderItem

    @Enum(key: "status")
    var status: OrderStatus

    @OptionalField(key: "note")
    var note: String?

    @Parent(key: "updated_by")
    var user: User

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() {}

    func toDTO() -> OrderItemStatusHistoryDTO {
        .init(
            id: self.id,
            orderItemID: self.$orderItem.id,
            status: self.status,
            note: self.note,
            updatedBy: self.$user.id,
            createdAt: self.createdAt
        )
    }
}
