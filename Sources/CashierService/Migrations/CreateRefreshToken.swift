//
//  CreateRefreshToken.swift
//  CashierService
//
//  Created by Muhammad Vikri on 13/08/26.
//

import Fluent

struct CreateRefreshToken: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("refresh_tokens")
            .id()
            .field(
                "user_id",
                .uuid,
                .required,
                .references("users", "id", onDelete: .cascade)
            )
            .field("expires_at", .datetime, .required)
            .field("revoked_at", .datetime)
            .field("created_at", .datetime)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("refresh_tokens").delete()
    }
}
