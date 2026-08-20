//
//  CustomerDTO.swift
//  CashierService
//
//  Created by Muhammad Vikri on 02/08/26.
//

import Fluent
import Vapor

struct CustomerDTO: Content {
    var id: UUID?
    var name: String
    var phone: String
    var email: String?
    var address: String
    var createdAt: Date?
    
    func toModel() -> Customer {
        let model = Customer()
        
        model.name = self.name
        model.phone = self.phone
        model.email = self.email
        model.address = self.address
        
        return model
    }
}

struct CustomerInputDTO: Content {
    var customerID: UUID?
    var name: String?
    var phone: String?
    var address: String?
}
