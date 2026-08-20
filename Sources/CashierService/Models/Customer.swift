//
//  Customer.swift
//  CashierService
//
//  Created by Muhammad Vikri on 02/08/26.
//

import Fluent
import Foundation

final class Customer: Model, @unchecked Sendable {
    static let schema = "customers"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "phone")
    var phone: String

    /// Opsional: nggak diminta waktu create order, cuma dipakai kalau customer
    /// memang kasih email.
    @OptionalField(key: "email")
    var email: String?
    
    @Field(key: "address")
    var address: String
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    init() { }
    
    init(
        id: UUID? = nil,
        name: String,
        phone: String,
        email: String? = nil,
        address: String
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.phone = phone
        self.address = address
    }

    func toDTO() -> CustomerDTO {
        .init(
            id: self.id,
            name: self.name,
            phone: self.phone,
            email: self.email,
            address: self.address,
            createdAt: self.createdAt
        )
    }
}
