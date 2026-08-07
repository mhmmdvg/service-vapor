//
//  OrderItemUpdateDTO.swift
//  CashierService
//
//  Created by Muhammad Vikri on 06/08/26.
//

import Vapor

struct OrderItemUpdateDTO: Content {
    var status: OrderStatus?
    var note: String?
    var serviceFee: Int64?
}
