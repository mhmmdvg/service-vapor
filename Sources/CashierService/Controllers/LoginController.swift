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
                description: "Login menggunakan email dan password, mengembalikan JWT token",
                body: .type(LoginDTO.self), 
                response: .type(APIResponse<LoginResponseDTO>.self) 
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
}
