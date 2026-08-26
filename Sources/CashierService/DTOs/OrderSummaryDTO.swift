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
    /// Status ringkasan yang dihitung dari item order-nya sendiri, buat endpoint yang tidak
    /// menyaring per status duluan — `GET /orders`, yang mencampur order jalan dan selesai
    /// dalam satu halaman.
    ///
    /// Butuh relasi `items` sudah ter-load: panggil query-nya dengan `.with(\.$items)`.
    ///
    /// Order tanpa item dianggap masih jalan. Belum ada yang bisa diselesaikan, dan itu konsisten
    /// dengan `orderIDs(for:)` yang juga tidak memasukkannya ke daftar completed.
    var summaryStatus: OrderSummaryStatus {
        guard !self.items.isEmpty else { return .inProgress }

        return self.items.allSatisfy { $0.status == .completed }
            ? .completed
            : .inProgress
    }

    /// Ringkasan dengan status yang dihitung sendiri lewat ``summaryStatus``.
    func toSummaryDTO() -> OrderSummaryDTO {
        self.toSummaryDTO(status: self.summaryStatus)
    }

    /// Dipakai daftar yang statusnya sudah pasti dari cara query-nya disaring, jadi tidak perlu
    /// dihitung ulang per order.
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
