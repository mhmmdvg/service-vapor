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
