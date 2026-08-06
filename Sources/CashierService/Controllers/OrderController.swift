//
//  OrderController.swift
//  CashierService
//
//  Created by Muhammad Vikri on 03/08/26.
//

import Fluent
import JWT
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
        let payload = try req.auth.require(UserPayload.self)

        return try await req.db.transaction { db in
            let dto = try req.content.decode(OrderCreateDTO.self)
            let customer: Customer

            if let customerID = dto.customer.customerID {
                guard
                    let existingCustomer = try await Customer.find(
                        customerID,
                        on: db
                    )
                else {
                    throw Abort(
                        .notFound,
                        reason: "Customer dengan ID tersebut tidak ditemukan"
                    )
                }
                customer = existingCustomer
            } else {
                guard let name = dto.customer.name, !name.isEmpty else {
                    throw Abort(
                        .badRequest,
                        reason: "Nama customer wajib diisi untuk customer baru"
                    )
                }

                let newCustomer = Customer()
                newCustomer.name = name
                newCustomer.phone = dto.customer.phone ?? ""
                newCustomer.email = dto.customer.email ?? ""
                newCustomer.address = dto.customer.address ?? ""
                try await newCustomer.save(on: db)

                customer = newCustomer
            }

            let order = Order()
            order.orderCode = "SV-\(Int(Date().timeIntervalSince1970))"
            order.qrToken = UUID().uuidString
            order.$customer.id = try customer.requireID()
            order.$cashier.id = payload.userID
            try await order.save(on: db)

            for itemDTO in dto.items {
                let device: Device

                if let deviceID = itemDTO.deviceID {
                    guard
                        let existingDevice = try await Device.find(
                            deviceID,
                            on: db
                        )
                    else {
                        throw Abort(.notFound, reason: "Device not found")
                    }
                    device = existingDevice
                } else {
                    guard
                        let brand = itemDTO.brand, !brand.isEmpty,
                        let model = itemDTO.model, !model.isEmpty
                    else {
                        throw Abort(
                            .badRequest,
                            reason:
                                "Brand and model are required when creating a new device."
                        )
                    }

                    let newDevice = Device()
                    newDevice.$customer.id = try customer.requireID()
                    newDevice.brand = brand
                    newDevice.model = model
                    newDevice.color = itemDTO.color ?? ""

                    try await newDevice.save(on: db)

                    device = newDevice
                }

                let item = OrderItem()
                item.$order.id = order.id!
                item.$device.id = try device.requireID()
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
