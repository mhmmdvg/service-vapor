//
//  OrderDetailDTO.swift
//  CashierService
//
//  Created by Muhammad Vikri on 07/08/26.
//

import Vapor

struct OrderDetailDTO: Content {
    var id: UUID?
    var orderCode: String
    var qrToken: String
    var createdAt: Date?
    var customerName: String
    var customerPhone: String
    var cashierName: String
    var items: [OrderDetailItemDTO]
}

struct OrderDetailItemDTO: Content {
    var id: UUID?
    var deviceBrand: String
    var deviceModel: String
    var status: OrderStatus
    var complaint: String?
    var serviceFee: Int64?
    var finalCost: Int64?
    var parts: [OrderPartDetailDTO]
}

extension Order {
    func toDetailDTO() -> OrderDetailDTO {
        .init(
            id: self.id,
            orderCode: self.orderCode,
            qrToken: self.qrToken,
            createdAt: self.createdAt,
            customerName: self.customer.name,
            customerPhone: self.customer.phone,
            cashierName: self.cashier.name,
            items: self.items.map { it in
                OrderDetailItemDTO(
                    id: it.id,
                    deviceBrand: it.device.brand,
                    deviceModel: it.device.model,
                    status: it.status,
                    complaint: it.complaint,
                    serviceFee: it.serviceFee,
                    finalCost: it.finalCost,
                    parts: it.parts.map { $0.toDetailDTO() }
                )
            }
        )
    }
}
