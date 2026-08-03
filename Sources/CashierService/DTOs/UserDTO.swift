//
//  UserDTO.swift
//  CashierService
//
//  Created by Muhammad Vikri on 02/08/26.
//

import Vapor

struct UserPublicDTO: Content {
    var id: UUID?
    var name: String
    var email: String
    var phone: String?
    var role: UserRole
    var createdAt: Date?
    
    init(user: User) {
        self.id = user.id
        self.name = user.name
        self.email = user.email
        self.phone = user.phone
        self.role = user.role
        self.createdAt = user.createdAt
    }
}


struct UserRegisterDTO: Content {
    var id: UUID?
    var name: String
    var email: String
    var password: String
    var phone: String?
    var role: UserRole
    
    func toModel() -> User {
        let model = User()
        
        model.id = self.id
        model.name = self.name
        model.email = self.email
        model.passwordHash = self.password
        model.phone = self.phone
        model.role = self.role
        
        return model
    }
}
