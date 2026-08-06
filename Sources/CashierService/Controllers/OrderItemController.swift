//
//  OrderItemController.swift
//  CashierService
//
//  Created by Muhammad Vikri on 06/08/26.
//

import Fluent
import JWT
import Vapor
import VaporToOpenAPI

struct OrderItemController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let items = routes.grouped("order-items")

        items.group(":orderItemID") { item in
            item.patch(use: self.update)
                .openAPI(
                    summary: "Update Order Item",
                    description: "Update order item status dan biaya",
                    body: .type(OrderItemUpdateDTO.self),
                    response: .type(APIResponse<OrderItemDTO>.self)
                )
        }
    }

    @Sendable
    func update(req: Request) async throws -> APIResponse<OrderItemDTO> {
        let payload = try req.auth.require(UserPayload.self)
        let dto = try req.content.decode(OrderItemUpdateDTO.self)

        guard let orderItemID = req.parameters.get("orderItemID", as: UUID.self)
        else {
            throw Abort(.badRequest, reason: "Invalid order item ID")
        }

        return try await req.db.transaction { db in
            guard let item = try await OrderItem.find(orderItemID, on: db)
            else {
                throw Abort(.notFound, reason: "Order item not found")
            }

            if let newStatus = dto.status, newStatus != item.status {
                let history = OrderItemStatusHistory()

                history.$orderItem.id = try item.requireID()
                history.status = newStatus
                history.note = dto.note
                history.$user.id = payload.userID

                try await history.save(on: db)

                item.status = newStatus
            }

            if let finalCost = dto.finalCost {
                item.finalCost = finalCost
            }

            try await item.save(on: db)

            return APIResponse(
                status: true,
                message: "Order item updated",
                data: item.toDTO()
            )
        }
    }
}
