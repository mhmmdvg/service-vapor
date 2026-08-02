//
//  Device.swift
//  CashierService
//
//  Created by Muhammad Vikri on 02/08/26.
//

import Fluent
import Foundation

final class Device: Model, @unchecked Sendable {
    static let schema = "devices"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "customer_id")
    var customer: Customer

    @Field(key: "brand")
    var brand: String

    @Field(key: "model")
    var model: String

    @Field(key: "color")
    var color: String

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() {}

    func toDTO() -> DeviceDTO {
        .init(
            id: self.id,
            customerID: self.$customer.id,
            brand: self.brand,
            model: self.model,
            color: self.color
        )
    }
}
