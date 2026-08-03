//
//  OrderController.swift
//  CashierService
//
//  Created by Muhammad Vikri on 03/08/26.
//

import Fluent
import Vapor

struct OrderController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let orders = routes.grouped("orders")

        orders.get(use: self.index)
        orders.post(use: self.create)
    }

    @Sendable
    func index(req: Request) async throws -> APIResponse<[OrderDTO]> {
        let orders = try await Order.query(on: req.db).all().map { $0.toDTO() }

        return APIResponse(
            status: true,
            message: "Success get all orders",
            data: orders
        )
    }
    
    @Sendable
    func create(req: Request) async throws -> APIResponse<OrderDTO> {
        return try await req.db.transaction { db in
            let dto = try req.content.decode(OrderCreateDTO.self)
            
            let order = Order()
            order.orderCode = "SV-\(Int(Date().timeIntervalSince1970))"
            order.qrToken = UUID().uuidString
            order.$customer.id = dto.customerID
//            order.$cashier.id =
            try await order.save(on: db)
            
            for itemDTO in dto.devices {
                let item = OrderItem()
                
                item.$order.id = order.id!
                item.$device.id = itemDTO.deviceID
                item.complaint = itemDTO.complaint
                item.status = .received
                item.finalCost = 0
                try await item.save(on: db)
            }
            
            return APIResponse(
                status: true,
                message: "Success create order",
                data: order.toDTO()
            )
        }
    }
    

}
