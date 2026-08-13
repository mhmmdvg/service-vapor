//
//  RefreshPayload.swift
//  CashierService
//
//  Created by Muhammad Vikri on 13/08/26.
//

import Foundation
import JWT

/// Payload refresh token. Sengaja tidak punya `role` supaya token ini tidak bisa
/// dipakai sebagai access token (decode ke `UserPayload` akan gagal), dan
/// sebaliknya access token tidak punya `jti` jadi tidak bisa dipakai refresh.
struct RefreshPayload: JWTPayload {
    var userID: UUID
    var tokenID: UUID
    var expiration: ExpirationClaim

    enum CodingKeys: String, CodingKey {
        case userID = "sub"
        case tokenID = "jti"
        case expiration = "exp"
    }

    func verify(using algorithm: some JWTAlgorithm) async throws {
        try self.expiration.verifyNotExpired()
    }
}
