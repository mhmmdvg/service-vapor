//
//  OrderDetailDTO.swift
//  CashierService
//
//  Created by Muhammad Vikri on 07/08/26.
//

import Vapor

struct OrderDetailDTO: Content {
    var orderCode: String
    var qrToken: String
    var createdAt: Date?
    var customerName: String
    var customerPhone: String
    var cashierName: String
    var items: [OrderDetailItemDTO]
}

struct OrderDetailItemDTO: Content {
    var deviceBrand: String
    var deviceModel: String
    var status: OrderStatus
    var complaint: String?
    var finalCost: Int64?
}

extension Order {
    func toDetailDTO() -> OrderDetailDTO {
        .init(
            orderCode: self.orderCode,
            qrToken: self.qrToken,
            createdAt: self.createdAt,
            customerName: self.customer.name,
            customerPhone: self.customer.phone,
            cashierName: self.cashier.name,
            items: self.items.map { it in
                OrderDetailItemDTO(
                    deviceBrand: it.device.brand,
                    deviceModel: it.device.model,
                    status: it.status,
                    complaint: it.complaint,
                    finalCost: it.finalCost
                )
            }
        )
    }
}
