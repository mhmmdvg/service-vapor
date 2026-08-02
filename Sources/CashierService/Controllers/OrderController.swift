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
}
