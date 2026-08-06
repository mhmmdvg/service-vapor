//
//  OrderItemDTO.swift
//  CashierService
//
//  Created by Muhammad Vikri on 03/08/26.
//

import Fluent
import Vapor

struct OrderItemDTO: Content {
    var id: UUID?
    var orderID: Order.IDValue
    var deviceID: Device.IDValue
    var complaint: String?
    var status: OrderStatus
    var finalCost: Int64?
    
    func toModel() -> OrderItem {
        let model = OrderItem()
        
        model.$order.id = self.orderID
        model.$device.id = self.deviceID
        model.complaint = self.complaint
        model.status = self.status
        model.finalCost = self.finalCost
        
        return model
    }
}
