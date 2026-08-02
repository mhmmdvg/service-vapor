//
//  SeedUser.swift
//  CashierService
//
//  Created by Muhammad Vikri on 02/08/26.
//

import Fluent
import Vapor

struct SeedUser: AsyncMigration {
    func prepare(on database: any Database) async throws {
        let hashedPassword = try Bcrypt.hash("password")
        
        let admin = User()
        admin.name = "Administrator"
        admin.email = "admin@mail.com"
        admin.passwordHash = hashedPassword
        admin.role = .admin
        admin.phone = "08123456789"
        
        try await admin.save(on: database)
    }
    
    func revert(on database: any Database) async throws {
        try await User.query(on: database)
            .filter(\.$email == "admin@mail.com")
            .delete()
    }
}
