//
//  UserController.swift
//  CashierService
//
//  Created by Muhammad Vikri on 02/08/26.
//

import Fluent
import Vapor

struct UserController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let users = routes.grouped("users")

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
