//
//  OrderTrackingDTO.swift
//  CashierService
//
//  Created by Muhammad Vikri on 06/08/26.
//

import Vapor

struct OrderTrackingDTO: Content {
    var orderCode: String
    var createdAt: Date?
    var items: [OrderItemTrackingDTO]
}

struct OrderItemTrackingDTO: Content {
    var id: UUID?
    var deviceBrand: String
    var deviceModel: String
    var complaint: String?
    var status: OrderStatus
    var finalCost: Int64?
    var statusHistory: [StatusHistoryPointDTO]
}

struct StatusHistoryPointDTO: Content {
    var status: OrderStatus
    var createdAt: Date?
}

extension Order {
    func toTrackingDTO() -> OrderTrackingDTO {
        .init(
            orderCode: self.orderCode,
            createdAt: self.createdAt,
            items: self.items.map { $0.toTrackingDTO() }
        )
    }
}

extension OrderItem {
    func toTrackingDTO() -> OrderItemTrackingDTO {
        .init(
            id: self.id,
            deviceBrand: self.device.brand,
            deviceModel: self.device.model,
            complaint: self.complaint,
            status: self.status,
            finalCost: self.finalCost,
            statusHistory: self.statusHistory
                .sorted { ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast) }
                .map { StatusHistoryPointDTO(status: $0.status, createdAt: $0.createdAt) }
        )
    }
}
