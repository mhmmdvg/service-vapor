//
//  UserController.swift
//  CashierService
//
//  Created by Muhammad Vikri on 02/08/26.
//

import Fluent
import JWT
import Vapor

struct UserController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let users = routes.grouped("users")

        routes.post("login", use: self.login)

        users.get(use: self.index)
        users.post(use: self.create)
        users.group(":userID") { user in
            user.delete(use: self.delete)
        }
    }

    @Sendable
    func index(req: Request) async throws -> APIResponse<[UserPublicDTO]> {
        let users = try await User.query(on: req.db).all().map { $0.toDTO() }

        return APIResponse(
            status: true,
            message: "Success get all user",
            data: users
        )
    }

    @Sendable
    func login(req: Request) async throws -> APIResponse<LoginResponseDTO> {
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

        let payload = UserPayload(
            userID: user.id!,
            role: user.role,
            expiration: .init(value: Date().addingTimeInterval(3600))
        )
        let token = try await req.jwt.sign(payload)

        return APIResponse(
            status: true,
            message: "Login successfully",
            data: LoginResponseDTO(
                accessToken: token,
                user: LoginUserDTO(
                    email: user.email,
                    name: user.name,
                    role: user.role
                )
            )
        )
    }

    @Sendable
    func create(req: Request) async throws -> APIResponse<UserPublicDTO> {
        let user = try req.content.decode(UserRegisterDTO.self).toModel()
        try await user.save(on: req.db)

        return APIResponse(
            status: true,
            message: "Create user successfully",
            data: user.toDTO()
        )
    }

    @Sendable
    func delete(req: Request) async throws -> APIResponse<UserPublicDTO> {
        guard
            let user = try await User.find(
                req.parameters.get("userID"),
                on: req.db
            )
        else {
            throw Abort(.notFound, reason: "User not found")
        }

        try await user.delete(on: req.db)

        return APIResponse(
            status: true,
            message: "User deleted successfully",
            data: nil
        )
    }
}
