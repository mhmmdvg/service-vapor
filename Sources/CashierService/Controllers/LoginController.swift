//
//  LoginController.swift
//  CashierService
//
//  Created by Muhammad Vikri on 06/08/26.
//

import Fluent
import JWT
import Vapor
import VaporToOpenAPI

struct LoginController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        routes.post("login", use: self.index)
            .openAPI(
                summary: "Login",
                description: "Login menggunakan email dan password, mengembalikan access token + refresh token",
                body: .type(LoginDTO.self),
                response: .type(APIResponse<LoginResponseDTO>.self)
            )
            .openAPINoAuth()

        routes.post("refresh", use: self.refresh)
            .openAPI(
                summary: "Refresh Token",
                description:
                    "Tukar refresh token dengan pasangan token baru. Refresh token lama langsung dicabut (rotasi); kalau token yang sudah dipakai dikirim lagi, semua sesi user dicabut",
                body: .type(RefreshTokenDTO.self),
                response: .type(APIResponse<TokenPairDTO>.self)
            )
            .openAPINoAuth()

        routes.post("logout", use: self.logout)
            .openAPI(
                summary: "Logout",
                description: "Cabut refresh token milik sesi ini",
                body: .type(RefreshTokenDTO.self),
                response: .type(APIResponse<String>.self)
            )
            .openAPINoAuth()
    }
    
    @Sendable
    func index(req: Request) async throws -> APIResponse<LoginResponseDTO> {
        let dto = try req.content.decode(LoginDTO.self)

        guard
            let user = try await User.query(on: req.db)
                .filter(\.$email == dto.email)
                .first()
        else {
            throw Abort(.unauthorized, reason: "User not found")
        }

        let isValid = try await req.password.async.verify(
            dto.password,
            created: user.passwordHash
        )
        guard isValid else {
            throw Abort(.unauthorized, reason: "Email or password is wrong")
        }

        let tokens = try await AuthTokenService.issuePair(
            for: user,
            req: req,
            on: req.db
        )

        return APIResponse(
            success: true,
            message: "Login successfully",
            data: LoginResponseDTO(
                accessToken: tokens.accessToken,
                refreshToken: tokens.refreshToken,
                expiresIn: tokens.expiresIn,
                user: LoginUserDTO(
                    email: user.email,
                    name: user.name,
                    role: user.role
                )
            )
        )
    }

    @Sendable
    func refresh(req: Request) async throws -> APIResponse<TokenPairDTO> {
        let dto = try req.content.decode(RefreshTokenDTO.self)
        let payload = try await self.verifyRefreshToken(dto.refreshToken, req: req)

        guard
            let session = try await RefreshToken.find(
                payload.tokenID,
                on: req.db
            ),
            session.$user.id == payload.userID
        else {
            throw Abort(.unauthorized, reason: "Refresh token tidak dikenali")
        }

        // Token yang sudah dirotasi dipakai lagi: anggap bocor, cabut semua sesi.
        // Pencabutan dijalankan di luar transaksi rotasi supaya tidak ikut
        // ter-rollback waktu request ini di-throw.
        guard session.revokedAt == nil else {
            try await AuthTokenService.revokeAllSessions(
                userID: payload.userID,
                on: req.db
            )
            throw Abort(
                .unauthorized,
                reason: "Refresh token sudah dipakai, semua sesi dicabut. Silakan login ulang"
            )
        }

        guard session.expiresAt > Date() else {
            throw Abort(.unauthorized, reason: "Refresh token sudah expired")
        }

        guard let user = try await User.find(payload.userID, on: req.db) else {
            throw Abort(.unauthorized, reason: "User tidak ditemukan")
        }

        return try await req.db.transaction { db in
            session.revokedAt = Date()
            try await session.update(on: db)

            let tokens = try await AuthTokenService.issuePair(
                for: user,
                req: req,
                on: db
            )

            return APIResponse(
                success: true,
                message: "Success refresh token",
                data: tokens
            )
        }
    }

    @Sendable
    func logout(req: Request) async throws -> APIResponse<String> {
        let dto = try req.content.decode(RefreshTokenDTO.self)
        let payload = try await self.verifyRefreshToken(dto.refreshToken, req: req)

        // Sesi yang di-logout dihapus, bukan ditandai revoked, supaya client yang
        // mengirim ulang token itu tidak salah dianggap kebocoran token.
        if let session = try await RefreshToken.find(payload.tokenID, on: req.db),
            session.$user.id == payload.userID
        {
            try await session.delete(on: req.db)
        }

        return APIResponse(success: true, message: "Logout successfully")
    }

    private func verifyRefreshToken(
        _ token: String,
        req: Request
    ) async throws -> RefreshPayload {
        do {
            return try await req.jwt.verify(token, as: RefreshPayload.self)
        } catch {
            throw Abort(
                .unauthorized,
                reason: "Refresh token tidak valid atau sudah expired"
            )
        }
    }
}
