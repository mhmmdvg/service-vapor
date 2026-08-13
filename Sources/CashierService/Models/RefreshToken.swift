//
//  RefreshToken.swift
//  CashierService
//
//  Created by Muhammad Vikri on 13/08/26.
//

import Fluent
import Foundation

/// Satu baris = satu sesi refresh token yang masih dipegang client.
/// Token yang dikirim ke client berupa JWT, `id` di sini dipakai sebagai `jti`
/// supaya token bisa dicabut (logout / rotasi / deteksi reuse).
final class RefreshToken: Model, @unchecked Sendable {
    static let schema: String = "refresh_tokens"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "user_id")
    var user: User

    @Field(key: "expires_at")
    var expiresAt: Date

    @OptionalField(key: "revoked_at")
    var revokedAt: Date?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() {}

    init(userID: User.IDValue, expiresAt: Date) {
        self.$user.id = userID
        self.expiresAt = expiresAt
    }

    var isActive: Bool {
        self.revokedAt == nil && self.expiresAt > Date()
    }
}
