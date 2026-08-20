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
                description:
                    "Ambil semua order, urut dari yang terbaru. Berpaginasi lewat query `page` dan `per_page` (default \(PageRequest.defaultPerPage), maksimal \(PageRequest.maxPerPage)). Query `search` menyaring berdasarkan kode order, nama customer, atau nomor HP customer",
                query: .type(OrderListQueryDTO.self),
                response: .type(APIResponse<[OrderDTO]>.self)
            )
        orders.get("history", use: self.history)
            .openAPI(
                summary: "List Order History",
                description:
                    "Ambil order yang seluruh order item-nya sudah completed, dipakai buat layar riwayat order. Berpaginasi lewat query `page` dan `per_page`, bisa disaring lewat query `search`",
                query: .type(OrderListQueryDTO.self),
                response: .type(APIResponse<[OrderSummaryDTO]>.self)
            )
        orders.get("in-progress", use: self.inProgress)
            .openAPI(
                summary: "List in-progress order",
                description:
                    "List order yang masih progress. Berpaginasi lewat query `page` dan `per_page`, bisa disaring lewat query `search`",
                query: .type(OrderListQueryDTO.self),
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
        let page = try PageRequest(req)
        let search = try SearchQuery(req)

        let total = try await Order.query(on: req.db)
            .filter(search: search)
            .count()
        let orders = try await Order.query(on: req.db)
            .filter(search: search)
            .with(\.$customer)
            .with(\.$cashier)
            .sort(\.$createdAt, .descending)
            .limit(page.perPage)
            .offset(page.offset)
            .all()
            .map { $0.toDTO() }

        return APIResponse(
            success: true,
            message: "Success get all orders",
            data: orders,
            pageInfo: PageInfo(
                page: page.page,
                perPage: page.perPage,
                total: total
            )
        )
    }

    @Sendable
    func history(req: Request) async throws -> APIResponse<[OrderSummaryDTO]> {
        try await self.summaryPage(
            status: .completed,
            message: "Success get order history",
            req: req
        )
    }

    @Sendable
    func inProgress(req: Request) async throws -> APIResponse<[OrderSummaryDTO]>
    {
        try await self.summaryPage(
            status: .inProgress,
            message: "Success get in progress orders",
            req: req
        )
    }

    /// Ambil satu halaman order sesuai status ringkasannya. Order-nya disaring lewat
    /// daftar id dari tabel order_items dulu, jadi yang di-load dengan relasinya cuma
    /// order yang benar-benar masuk halaman ini.
    private func summaryPage(
        status: OrderSummaryStatus,
        message: String,
        req: Request
    ) async throws -> APIResponse<[OrderSummaryDTO]> {
        let page = try PageRequest(req)
        let search = try SearchQuery(req)
        let ids = try await self.orderIDs(for: status, on: req.db)

        // Tanpa search, semua id di sini berasal dari order_items yang punya FK
        // ke orders, jadi jumlahnya sama dengan jumlah order yang cocok. Begitu
        // ada search, totalnya harus dihitung ulang lewat query.
        let total: Int
        if ids.isEmpty {
            total = 0
        } else if search == nil {
            total = ids.count
        } else {
            total = try await Order.query(on: req.db)
                .filter(\.$id ~~ ids)
                .filter(search: search)
                .count()
        }

        let pageInfo = PageInfo(
            page: page.page,
            perPage: page.perPage,
            total: total
        )

        guard total > 0 else {
            return APIResponse(
                success: true,
                message: message,
                data: [],
                pageInfo: pageInfo
            )
        }

        let orders = try await Order.query(on: req.db)
            .filter(\.$id ~~ ids)
            .filter(search: search)
            .with(\.$customer)
            .with(\.$items)
            .sort(\.$createdAt, .descending)
            .limit(page.perPage)
            .offset(page.offset)
            .all()

        return APIResponse(
            success: true,
            message: message,
            data: orders.map { $0.toSummaryDTO(status: status) },
            pageInfo: pageInfo
        )
    }

    /// `inProgress`: order yang masih punya item belum completed.
    /// `completed`: order yang punya item dan semua item-nya sudah completed.
    private func orderIDs(
        for status: OrderSummaryStatus,
        on db: any Database
    ) async throws -> [UUID] {
        let unfinished = try await OrderItem.query(on: db)
            .filter(\.$status != .completed)
            .unique()
            .all(\.$order.$id)

        switch status {
        case .inProgress:
            return unfinished
        case .completed:
            let unfinishedIDs = Set(unfinished)
            let withItems = try await OrderItem.query(on: db)
                .unique()
                .all(\.$order.$id)

            return withItems.filter { !unfinishedIDs.contains($0) }
        }
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
            success: true,
            message: "Successfully fetched order detail",
            data: order.toDetailDTO()
        )

    }

    @Sendable
    func create(req: Request) async throws -> APIResponse<
        OrderCreateResponseDTO
    > {
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
                newCustomer.address = dto.customer.address ?? ""
                try await newCustomer.save(on: db)

                customer = newCustomer
            }

            guard let cashier = try await User.find(payload.userID, on: db)
            else {
                throw Abort(.notFound, reason: "Cashier tidak ditemukan")
            }

            let order = Order()
            order.orderCode = "SV-\(Int(Date().timeIntervalSince1970))"
            order.qrToken = UUID().uuidString
            order.$customer.id = try customer.requireID()
            order.$customer.value = customer
            order.$cashier.id = try cashier.requireID()
            order.$cashier.value = cashier

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

                if itemDTO.serviceFee != nil || itemDTO.parts?.isEmpty == false
                {
                    try await item.recalculateFinalCost(on: db)
                }

                createdItems.append(item.toDTO())
            }

            return APIResponse(
                success: true,
                message: "Success create order",
                data: OrderCreateResponseDTO(
                    order: order.toDTO(),
                    items: createdItems
                )
            )
        }
    }

}
