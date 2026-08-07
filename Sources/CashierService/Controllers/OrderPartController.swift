//
//  OrderPartController.swift
//  CashierService
//
//  Created by Muhammad Vikri on 07/08/26.
//

import Fluent
import JWT
import Vapor
import VaporToOpenAPI

struct OrderPartController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let parts = routes.grouped("order-items", ":orderItemID", "parts")

        parts.post(use: self.add)
            .openAPI(
                summary: "Add Spare Part to Order Item",
                description:
                    "Pakai spare part untuk order item, mengurangi stock spare part dan menghitung ulang final cost dari total harga part yang dipakai",
                body: .type(OrderPartCreateDTO.self),
                response: .type(APIResponse<OrderItemPartsDTO>.self)
            )

        parts.group(":orderPartID") { part in
            part.delete(use: self.remove)
                .openAPI(
                    summary: "Remove Spare Part from Order Item",
                    description:
                        "Batalkan pemakaian spare part pada order item, mengembalikan stock dan menghitung ulang final cost",
                    response: .type(APIResponse<OrderItemPartsDTO>.self)
                )
        }
    }

    @Sendable
    func add(req: Request) async throws -> APIResponse<OrderItemPartsDTO> {
        _ = try req.auth.require(UserPayload.self)
        let dto = try req.content.decode(OrderPartCreateDTO.self)

        guard let orderItemID = req.parameters.get("orderItemID", as: UUID.self)
        else {
            throw Abort(.badRequest, reason: "Invalid order item ID")
        }

        return try await req.db.transaction { db in
            guard let item = try await OrderItem.find(orderItemID, on: db)
            else {
                throw Abort(.notFound, reason: "Order item not found")
            }

            try await item.attachPart(sparePartID: dto.sparePartID, qty: dto.qty, on: db)

            let total = try await item.recalculateFinalCost(on: db)

            let parts = try await OrderPart.query(on: db)
                .filter(\.$orderItem.$id == orderItemID)
                .with(\.$sparePart)
                .all()

            return APIResponse(
                status: true,
                message: "Spare part added to order item",
                data: OrderItemPartsDTO(
                    orderItemID: orderItemID,
                    serviceFee: item.serviceFee,
                    finalCost: total,
                    parts: parts.map { $0.toDetailDTO() }
                )
            )
        }
    }

    @Sendable
    func remove(req: Request) async throws -> APIResponse<OrderItemPartsDTO> {
        _ = try req.auth.require(UserPayload.self)

        guard let orderItemID = req.parameters.get("orderItemID", as: UUID.self),
            let orderPartID = req.parameters.get("orderPartID", as: UUID.self)
        else {
            throw Abort(.badRequest, reason: "Invalid order item or order part ID")
        }

        return try await req.db.transaction { db in
            guard let item = try await OrderItem.find(orderItemID, on: db)
            else {
                throw Abort(.notFound, reason: "Order item not found")
            }

            guard
                let orderPart = try await OrderPart.query(on: db)
                    .filter(\.$id == orderPartID)
                    .filter(\.$orderItem.$id == orderItemID)
                    .first()
            else {
                throw Abort(.notFound, reason: "Order part not found")
            }

            guard let sparePart = try await SparePart.find(orderPart.$sparePart.id, on: db)
            else {
                throw Abort(.notFound, reason: "Spare part not found")
            }

            sparePart.stock += orderPart.qty
            try await sparePart.save(on: db)

            try await orderPart.delete(on: db)

            let total = try await item.recalculateFinalCost(on: db)

            let parts = try await OrderPart.query(on: db)
                .filter(\.$orderItem.$id == orderItemID)
                .with(\.$sparePart)
                .all()

            return APIResponse(
                status: true,
                message: "Spare part removed from order item",
                data: OrderItemPartsDTO(
                    orderItemID: orderItemID,
                    serviceFee: item.serviceFee,
                    finalCost: total,
                    parts: parts.map { $0.toDetailDTO() }
                )
            )
        }
    }
}
