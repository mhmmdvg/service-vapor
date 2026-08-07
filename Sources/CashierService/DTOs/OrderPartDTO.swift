//
//  OrderPartDTO.swift
//  CashierService
//
//  Created by Muhammad Vikri on 03/08/26.
//

import Fluent
import Vapor

struct OrderPartDTO: Content {
    var id: UUID?
    var orderItemID: OrderItem.IDValue
    var sparePartID: SparePart.IDValue
    var qty: Int
    var priceAtUse: Int64

    func toModel() -> OrderPart {
        let model = OrderPart()

        model.$orderItem.id = self.orderItemID
        model.$sparePart.id = self.sparePartID
        model.qty = self.qty
        model.priceAtUse = self.priceAtUse

        return model
    }
}

/// Request body untuk menambahkan spare part ke sebuah order item.
struct OrderPartCreateDTO: Content {
    var sparePartID: SparePart.IDValue
    var qty: Int
}

/// Rincian satu baris spare part yang dipakai, dipakai untuk tampilan struk & tracking.
struct OrderPartDetailDTO: Content {
    var id: UUID?
    var sparePartID: SparePart.IDValue
    var sparePartName: String
    var sku: String
    var qty: Int
    var priceAtUse: Int64
    var subtotal: Int64
}

/// Response setelah spare part order item berubah (ditambah/dihapus), berisi final cost terbaru.
struct OrderItemPartsDTO: Content {
    var orderItemID: OrderItem.IDValue
    var serviceFee: Int64?
    var finalCost: Int64?
    var parts: [OrderPartDetailDTO]
}

extension OrderPart {
    func toDetailDTO() -> OrderPartDetailDTO {
        .init(
            id: self.id,
            sparePartID: self.$sparePart.id,
            sparePartName: self.sparePart.name,
            sku: self.sparePart.sku,
            qty: self.qty,
            priceAtUse: self.priceAtUse,
            subtotal: self.priceAtUse * Int64(self.qty)
        )
    }
}
