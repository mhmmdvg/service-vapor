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
    /// Biaya jasa, boleh langsung diisi kalau sudah jelas tanpa perlu diagnosa dulu.
    var serviceFee: Int64?
    /// Spare part yang sudah pasti dipakai sejak awal, tanpa perlu diagnosa dulu.
    var parts: [OrderPartCreateDTO]?
}

struct OrderCreateDTO: Content {
    var customer: CustomerInputDTO
    var items: [OrderItemCreateDTO]
}

/// Response create order: order beserta order item yang baru dibuat (dengan ID-nya),
/// dipakai buat lanjut isi service fee / spare part per item.
struct OrderCreateResponseDTO: Content {
    var order: OrderDTO
    var items: [OrderItemDTO]
}
