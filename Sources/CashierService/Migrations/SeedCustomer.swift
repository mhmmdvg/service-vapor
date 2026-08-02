//
//  SeedCustomer.swift
//  CashierService
//
//  Created by Muhammad Vikri on 02/08/26.
//

import Fluent
import Vapor

struct SeedCustomer: AsyncMigration {
    func prepare(on database: any Database) async throws {
        let customer = Customer()
        
        customer.name = "Muhammad Vikri"
        customer.email = "vikri@mail.com"
        customer.phone = "08123456789"
        customer.address = "Jalan Jalan"
        
        try await customer.save(on: database)
    }
    
    func revert(on database: any Database) async throws {
        try await Customer.query(on: database)
            .filter(\.$email == "vikri@mail.com")
            .delete()
    }
}
