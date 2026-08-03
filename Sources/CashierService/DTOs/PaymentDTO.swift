//
//  PaymentDTO.swift
//  CashierService
//
//  Created by Muhammad Vikri on 03/08/26.
//

import Fluent
import Vapor

struct PaymentDTO: Content {
    var id: UUID?
    var orderID: Order.IDValue
    var amount: Int64
    var method: PaymentMethods
    var cashierID: User.IDValue

    func toModel() -> Payment {
        let model = Payment()
        
        model.$order.id = self.orderID
        model.amount = self.amount
        model.method = self.method
        model.$cashier.id = self.cashierID
        
        return model
    }
}
