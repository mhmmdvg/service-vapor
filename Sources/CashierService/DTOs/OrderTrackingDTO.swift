//
//  OrderTrackingDTO.swift
//  CashierService
//
//  Created by Muhammad Vikri on 06/08/26.
//

import Vapor

struct OrderTrackingDTO: Content {
    /// Lets a cashier scanning the receipt open the order itself, rather than only its progress.
    /// Harmless to expose on this unauthenticated route: the id is not a credential, and every
    /// endpoint that takes one still requires a token.
    var id: UUID?
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
    var serviceFee: Int64?
    var finalCost: Int64?
    var statusHistory: [StatusHistoryPointDTO]
    var parts: [OrderPartDetailDTO]
}

struct StatusHistoryPointDTO: Content {
    var status: OrderStatus
    var createdAt: Date?
}

extension Order {
    func toTrackingDTO() -> OrderTrackingDTO {
        .init(
            id: self.id,
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
            serviceFee: self.serviceFee,
            finalCost: self.finalCost,
            statusHistory: self.statusHistory
                .sorted { ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast) }
                .map { StatusHistoryPointDTO(status: $0.status, createdAt: $0.createdAt) },
            parts: self.parts.map { $0.toDetailDTO() }
        )
    }
}
