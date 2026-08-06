//
//  UserPayload.swift
//  CashierService
//
//  Created by Muhammad Vikri on 03/08/26.
//

import Foundation
import JWT
import Vapor

struct UserPayload: JWTPayload, Authenticatable {
    var userID: UUID
    var role: UserRole
    var expiration: ExpirationClaim
    
    enum CodingKeys: String, CodingKey {
        case userID = "sub"
        case role = "role"
        case expiration = "exp"
    }
    
    func verify(using algorithm: some JWTAlgorithm) async throws {
        try self.expiration.verifyNotExpired()
    }
}
