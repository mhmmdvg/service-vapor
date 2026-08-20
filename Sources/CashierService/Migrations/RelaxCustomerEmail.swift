//
//  RelaxCustomerEmail.swift
//  CashierService
//
//  Created by Muhammad Vikri on 20/08/26.
//

import Fluent
import SQLKit
import Vapor

/// Email customer nggak lagi diminta waktu create order, jadi kolomnya dilepas
/// dari `NOT NULL` dan `UNIQUE`. Sebelum ini setiap customer baru tanpa email
/// disimpan sebagai string kosong, dan customer kedua langsung kena unique
/// constraint. Data email yang sudah ada sengaja dipertahankan.
struct RelaxCustomerEmail: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("customers")
            .deleteUnique(on: "email")
            .update()

        let sql = try self.sql(database)
        try await sql.raw("""
            ALTER TABLE "customers" ALTER COLUMN "email" DROP NOT NULL
            """).run()

        // String kosong peninggalan create order yang lama disamakan dengan
        // customer baru yang memang tidak punya email.
        try await sql.raw("""
            UPDATE "customers" SET "email" = NULL WHERE "email" = ''
            """).run()
    }

    /// Unique-nya sengaja tidak dipasang lagi: begitu ada lebih dari satu
    /// customer tanpa email, constraint itu tidak mungkin dipenuhi.
    func revert(on database: any Database) async throws {
        let sql = try self.sql(database)
        try await sql.raw("""
            UPDATE "customers" SET "email" = '' WHERE "email" IS NULL
            """).run()
        try await sql.raw("""
            ALTER TABLE "customers" ALTER COLUMN "email" SET NOT NULL
            """).run()
    }

    private func sql(_ database: any Database) throws -> any SQLDatabase {
        guard let sql = database as? any SQLDatabase else {
            throw Abort(
                .internalServerError,
                reason: "Migrasi ini butuh database SQL"
            )
        }

        return sql
    }
}
