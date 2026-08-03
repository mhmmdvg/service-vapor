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
    var cashierID: User.IDValue
    
    func toModel() -> Order {
        let model = Order()
        
        model.orderCode = self.orderCode
        model.qrToken = self.qrToken
        model.$customer.id = self.customerID
        model.$cashier.id = self.cashierID
        
        return model
    }
}
