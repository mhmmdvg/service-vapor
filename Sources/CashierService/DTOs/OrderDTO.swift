//
//  OrderDTO.swift
//  CashierService
//
//  Created by Muhammad Vikri on 03/08/26.
//

import Fluent
import Vapor

struct OrderDTO: Content {
    var id: UUID?
    var orderCode: String
    var qrToken: String
    var customerID: Customer.IDValue
    var deviceID: Device.IDValue
    var cashierID: User.IDValue
    var complaint: String
    var status: OrderStatus
    var finalCost: Int64
    
    func toModel() -> Order {
        let model = Order()
        
        model.orderCode = self.orderCode
        model.qrToken = self.qrToken
        model.$customer.id = self.customerID
        model.$device.id = self.deviceID
        model.$cashier.id = self.cashierID
        model.complaint = self.complaint
        model.status = self.status
        model.finalCost = self.finalCost
        
        return model
    }
}
