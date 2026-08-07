//
//  OrderController.swift
//  CashierService
//
//  Created by Muhammad Vikri on 03/08/26.
//

import Fluent
import JWT
import Vapor
import VaporToOpenAPI

struct OrderController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let orders = routes.grouped("orders")

        orders.get(use: self.index)
            .openAPI(
                summary: "List Orders",
                description: "Ambil semua order",
                response: .type(APIResponse<[OrderDTO]>.self)
            )
        orders.get("history", use: self.history)
            .openAPI(
                summary: "List Order History",
                description:
                    "Ambil order yang seluruh order item-nya sudah completed, dipakai buat layar riwayat order",
                response: .type(APIResponse<[OrderSummaryDTO]>.self)
            )
        orders.post(use: self.create)
            .openAPI(
                summary: "Create Order",
                description:
                    "Buat order baru beserta order item (device) di dalamnya. Biaya jasa dan spare part boleh langsung diisi per item kalau sudah pasti tanpa perlu diagnosa dulu; kalau belum, biarkan kosong dan lengkapi belakangan lewat PATCH order item / endpoint tambah spare part",
                body: .type(OrderCreateDTO.self),
                response: .type(APIResponse<OrderCreateResponseDTO>.self)
            )
        orders.group(":orderID") { order in
            order.get(use: self.show)
                .openAPI(
                    summary: "Get Order Detail",
                    description:
                        "Detail order lengkap, dipakai layar konfirmasi setelah create order dan buat cetak struk",
                    response: .type(APIResponse<OrderDetailDTO>.self)
                )
        }
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
    func history(req: Request) async throws -> APIResponse<[OrderSummaryDTO]> {
        let orders = try await Order.query(on: req.db)
            .with(\.$customer)
            .with(\.$items)
            .all()

        let history = orders
            .filter { !$0.items.isEmpty && $0.items.allSatisfy { $0.status == .completed } }
            .sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
            .map { $0.toSummaryDTO(status: .completed) }

        return APIResponse(
            status: true,
            message: "Success get order history",
            data: history
        )
    }

    @Sendable
    func show(req: Request) async throws -> APIResponse<OrderDetailDTO> {
        guard let orderID = req.parameters.get("orderID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid order ID")
        }

        let query = Order.query(on: req.db)
            .filter(\.$id == orderID)
            .with(\.$customer)
            .with(\.$cashier)
            .with(\.$items) { item in
                item.with(\.$device)
                item.with(\.$parts) { $0.with(\.$sparePart) }
            }

        guard let order = try await query.first() else {
            throw Abort(.notFound, reason: "Order not found")
        }

        return APIResponse(
            status: true,
            message: "Successfully fetched order detail",
            data: order.toDetailDTO()
        )

    }

    @Sendable
    func create(req: Request) async throws -> APIResponse<OrderCreateResponseDTO> {
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

            var createdItems: [OrderItemDTO] = []

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
                item.serviceFee = itemDTO.serviceFee
                try await item.save(on: db)

                for partDTO in itemDTO.parts ?? [] {
                    try await item.attachPart(
                        sparePartID: partDTO.sparePartID,
                        qty: partDTO.qty,
                        on: db
                    )
                }

                if itemDTO.serviceFee != nil || itemDTO.parts?.isEmpty == false {
                    try await item.recalculateFinalCost(on: db)
                }

                createdItems.append(item.toDTO())
            }

            return APIResponse(
                status: true,
                message: "Success create order",
                data: OrderCreateResponseDTO(
                    order: order.toDTO(),
                    items: createdItems
                )
            )
        }
    }

}
