//
//  OrderItem.swift
//  CashierService
//
//  Created by Muhammad Vikri on 03/08/26.
//

import Fluent
import Foundation
import Vapor

final class OrderItem: Model, @unchecked Sendable {
    static let schema: String = "order_items"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "order_id")
    var order: Order

    @Parent(key: "device_id")
    var device: Device

    @OptionalField(key: "complaint")
    var complaint: String?

    @Enum(key: "status")
    var status: OrderStatus
    
    @Children(for: \.$orderItem)
    var statusHistory: [OrderItemStatusHistory]

    @Children(for: \.$orderItem)
    var parts: [OrderPart]

    /// Biaya jasa/servis, diinput manual oleh cashier (di luar harga spare part).
    @OptionalField(key: "service_fee")
    var serviceFee: Int64?

    /// Total tagihan = serviceFee + total harga spare part yang dipakai, dihitung ulang otomatis.
    @OptionalField(key: "final_cost")
    var finalCost: Int64?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() {}

    func toDTO() -> OrderItemDTO {
        .init(
            id: self.id,
            orderID: self.$order.id,
            deviceID: self.$device.id,
            complaint: self.complaint,
            status: self.status,
            serviceFee: self.serviceFee,
            finalCost: self.finalCost
        )
    }
}

extension OrderItem {
    /// Hitung ulang final cost = serviceFee + total harga spare part yang dipakai, lalu simpan.
    @discardableResult
    func recalculateFinalCost(on db: any Database) async throws -> Int64 {
        let parts = try await OrderPart.query(on: db)
            .filter(\.$orderItem.$id == self.requireID())
            .all()

        let partsTotal = parts.reduce(Int64(0)) { $0 + $1.priceAtUse * Int64($1.qty) }
        let total = (self.serviceFee ?? 0) + partsTotal

        self.finalCost = total
        try await self.save(on: db)

        return total
    }

    /// Pakai satu spare part untuk order item ini, mengurangi stock-nya. Dipakai baik saat
    /// create order (spare part yang sudah pasti dipakai tanpa diagnosa) maupun lewat endpoint
    /// tambah part setelah order berjalan. Tidak menghitung ulang finalCost — panggil
    /// `recalculateFinalCost` setelah semua part selesai ditambahkan.
    @discardableResult
    func attachPart(sparePartID: SparePart.IDValue, qty: Int, on db: any Database) async throws -> OrderPart {
        guard qty > 0 else {
            throw Abort(.badRequest, reason: "Qty spare part harus lebih dari 0")
        }

        guard let sparePart = try await SparePart.find(sparePartID, on: db) else {
            throw Abort(.notFound, reason: "Spare part not found")
        }

        guard sparePart.stock >= qty else {
            throw Abort(.badRequest, reason: "Stok spare part '\(sparePart.name)' tidak mencukupi")
        }

        sparePart.stock -= qty
        try await sparePart.save(on: db)

        let orderPart = OrderPart()
        orderPart.$orderItem.id = try self.requireID()
        orderPart.$sparePart.id = sparePartID
        orderPart.qty = qty
        orderPart.priceAtUse = sparePart.sellPrice
        try await orderPart.save(on: db)

        return orderPart
    }
}
