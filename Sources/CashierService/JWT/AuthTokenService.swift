//
//  AuthTokenService.swift
//  CashierService
//
//  Created by Muhammad Vikri on 13/08/26.
//

import Fluent
import Foundation
import JWT
import Vapor

enum AuthTokenService {
    /// Umur access token, bisa dioverride lewat env `ACCESS_TOKEN_TTL` (detik).
    static var accessTokenLifetime: TimeInterval {
        Environment.get("ACCESS_TOKEN_TTL").flatMap(TimeInterval.init) ?? 900
    }

    /// Umur refresh token, bisa dioverride lewat env `REFRESH_TOKEN_TTL` (detik).
    static var refreshTokenLifetime: TimeInterval {
        Environment.get("REFRESH_TOKEN_TTL").flatMap(TimeInterval.init)
            ?? 30 * 24 * 3600
    }

    /// Bikin access token baru + satu baris refresh token baru untuk user ini.
    static func issuePair(
        for user: User,
        req: Request,
        on db: any Database
    ) async throws -> TokenPairDTO {
        let userID = try user.requireID()
        let now = Date()

        let accessToken = try await req.jwt.sign(
            UserPayload(
                userID: userID,
                role: user.role,
                expiration: .init(
                    value: now.addingTimeInterval(accessTokenLifetime)
                )
            )
        )

        let session = RefreshToken(
            userID: userID,
            expiresAt: now.addingTimeInterval(refreshTokenLifetime)
        )
        try await session.save(on: db)

        let refreshToken = try await req.jwt.sign(
            RefreshPayload(
                userID: userID,
                tokenID: try session.requireID(),
                expiration: .init(value: session.expiresAt)
            )
        )

        return TokenPairDTO(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: Int(accessTokenLifetime)
        )
    }

    /// Cabut semua sesi aktif milik user (dipakai saat deteksi token reuse).
    static func revokeAllSessions(
        userID: User.IDValue,
        on db: any Database
    ) async throws {
        try await RefreshToken.query(on: db)
            .filter(\.$user.$id == userID)
            .filter(\.$revokedAt == nil)
            .set(\.$revokedAt, to: Date())
            .update()
    }
}
