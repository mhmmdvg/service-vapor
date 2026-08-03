//
//  OrderPart.swift
//  CashierService
//
//  Created by Muhammad Vikri on 03/08/26.
//

import Fluent
import Foundation

final class OrderPart: Model, @unchecked Sendable {
    static let schema: String = "order_parts"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "order_item_id")
    var orderItem: OrderItem

    @Parent(key: "spare_part_id")
    var sparePart: SparePart

    @Field(key: "qty")
    var qty: Int

    @Field(key: "price_at_use")
    var priceAtUse: Int64

    init() {}

    func toDTO() -> OrderPartDTO {
        .init(
            id: self.id,
            orderItemID: self.$orderItem.id,
            sparePartID: self.$sparePart.id,
            qty: self.qty,
            priceAtUse: self.priceAtUse
        )
    }
}
