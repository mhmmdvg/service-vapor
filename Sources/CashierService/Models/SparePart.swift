//
//  SparePart.swift
//  CashierService
//
//  Created by Muhammad Vikri on 03/08/26.
//

import Fluent
import Foundation

final class SparePart: Model, @unchecked Sendable {
    static let schema: String = "spare_parts"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "stock")
    var stock: Int

    @Field(key: "cost_price")
    var costPrice: Int64

    @Field(key: "sell_price")
    var sellPrice: Int64

    @Field(key: "sku")
    var sku: String

    init() {}

    func toDTO() -> SparePartDTO {
        .init(
            id: self.id,
            name: self.name,
            stock: self.stock,
            costPrice: self.costPrice,
            sellPrice: self.sellPrice,
            sku: self.sku
        )
    }
}
