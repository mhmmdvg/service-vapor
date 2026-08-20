//
//  CustomerController.swift
//  CashierService
//
//  Created by Muhammad Vikri on 02/08/26.
//

import Fluent
import Vapor

struct CustomerController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let customers = routes.grouped("customers")

        customers.get(use: self.index)
    }

    @Sendable
    func index(req: Request) async throws -> APIResponse<[CustomerDTO]> {

        let customers = try await Customer.query(on: req.db).all().map {
            $0.toDTO()
        }

        return APIResponse(
            success: true,
            message: "Success get all customers",
            data: customers
        )
    }
}
