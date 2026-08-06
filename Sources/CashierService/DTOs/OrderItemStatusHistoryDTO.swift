//
//  OrderItemStatusHistoryDTO.swift
//  CashierService
//
//  Created by Muhammad Vikri on 03/08/26.
//

import Fluent
import Vapor

struct OrderItemStatusHistoryDTO: Content {
    var id: UUID?
    var orderItemID: OrderItem.IDValue
    var status: OrderStatus
    var note: String?
    var updatedBy: User.IDValue
    var createdAt: Date?
    
    func toModel() -> OrderItemStatusHistory {
        let model = OrderItemStatusHistory()
        
        model.$orderItem.id = self.orderItemID
        model.status = self.status
        model.note = self.note
        model.$user.id = self.updatedBy
        
        return model
    }
}
