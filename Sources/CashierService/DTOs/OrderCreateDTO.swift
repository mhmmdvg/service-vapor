//
//  OrderCreateDTO.swift
//  CashierService
//
//  Created by Muhammad Vikri on 03/08/26.
//

import Vapor

struct OrderItemCreateDTO: Content {
    var deviceID: UUID
    var complaint: String
}

struct OrderCreateDTO: Content {
    var customerID: UUID
    var devices: [OrderItemCreateDTO]
}
