//
//  LoginDTO.swift
//  CashierService
//
//  Created by Muhammad Vikri on 03/08/26.
//

import Vapor

struct LoginDTO: Content {
    let email: String
    let password: String
    
    func toModel() -> User {
        let model = User()
        
        model.email = self.email
        model.passwordHash = self.password
        
        return model
    }
}

struct LoginResponseDTO: Content {
    let accessToken: String
    let user: LoginUserDTO
}

struct LoginUserDTO: Content {
    let email: String
    let name: String
    let role: UserRole
}
