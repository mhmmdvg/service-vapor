//
//  OrderDTO.swift
//  CashierService
//
//  Created by Muhammad Vikri on 03/08/26.
//

import Fluent
import Vapor

/// Ringkasan pihak yang terkait order (customer / cashier).
struct OrderPartyDTO: Content {
    var id: UUID
    var name: String
}

struct OrderDTO: Content {
    var id: UUID?
    var orderCode: String
    var qrToken: String
    var createdAt: Date?
    var customer: OrderPartyDTO
    var cashier: OrderPartyDTO


    func toModel() -> Order {
        let model = Order()

        model.orderCode = self.orderCode
        model.qrToken = self.qrToken
        model.$customer.id = self.customer.id
        model.$cashier.id = self.cashier.id

        return model
    }
}
