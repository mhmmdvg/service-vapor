//
//  OrderSummaryDTO.swift
//  CashierService
//
//  Created by Muhammad Vikri on 07/08/26.
//

import Vapor

enum OrderSummaryStatus: String, Codable, CaseIterable {
    case inProgress
    case completed
}

/// Ringkasan satu order untuk tampilan list (in progress / history), bukan detail lengkap.
struct OrderSummaryDTO: Content {
    var id: UUID?
    var orderCode: String
    var createdAt: Date?
    var customerName: String
    var itemsCount: Int
    var totalCost: Int64
    var status: OrderSummaryStatus
}

extension Order {
    /// Butuh relasi `customer` dan `items` sudah di-eager-load.
    func toSummaryDTO(status: OrderSummaryStatus) -> OrderSummaryDTO {
        .init(
            id: self.id,
            orderCode: self.orderCode,
            createdAt: self.createdAt,
            customerName: self.customer.name,
            itemsCount: self.items.count,
            totalCost: self.items.reduce(Int64(0)) { $0 + ($1.finalCost ?? 0) },
            status: status
        )
    }
}
