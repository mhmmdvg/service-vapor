//
//  TrackingController.swift
//  CashierService
//
//  Created by Muhammad Vikri on 06/08/26.
//

import Vapor
import Fluent
import VaporToOpenAPI

struct TrackingController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let tracking = routes.grouped("track")
        tracking.get(":qrToken", use: self.index)
            .openAPI(
                summary: "Track Order",
                description: "Cek status & histori progress semua device dalam satu order, diakses lewat qrToken dari struk.",
                response: .type(APIResponse<OrderTrackingDTO>.self)
            )
            .openAPINoAuth()
    }
    
    @Sendable
    func index(req: Request) async throws -> APIResponse<OrderTrackingDTO> {
        guard let qrToken = req.parameters.get("qrToken") else {
            throw Abort(.badRequest, reason: "QR Token is required")
        }

        let query = Order.query(on: req.db)
            .filter(\.$qrToken == qrToken)
            .with(\.$items) { item in
                item.with(\.$device)
                item.with(\.$statusHistory)
                item.with(\.$parts) { $0.with(\.$sparePart) }
            }

        guard let order = try await query.first() else {
            throw Abort(.notFound, reason: "Order not found")
        }

        return APIResponse(
            success: true,
            message: "Successfully fetched order tracking",
            data: order.toTrackingDTO()
        )
    }
}
