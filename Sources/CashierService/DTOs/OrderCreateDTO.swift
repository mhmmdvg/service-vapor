//
//  OrderCreateDTO.swift
//  CashierService
//
//  Created by Muhammad Vikri on 03/08/26.
//

import Vapor

struct OrderItemCreateDTO: Content {
    var deviceID: UUID?
    var brand: String?
    var model: String?
    var color: String?
    var complaint: String
    var serviceFee: Int64?
    var parts: [OrderPartCreateDTO]?
}

struct OrderCreateDTO: Content {
    var customer: CustomerInputDTO
    var items: [OrderItemCreateDTO]
}

struct OrderCreateResponseDTO: Content {
    var order: OrderDTO
    var items: [OrderItemDTO]
}
