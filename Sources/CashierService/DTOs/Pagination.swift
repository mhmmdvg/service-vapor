//
//  Pagination.swift
//  CashierService
//
//  Created by Muhammad Vikri on 15/08/26.
//

import Vapor

struct PageInfo: Content {
    var page: Int
    var perPage: Int
    var total: Int
    var totalPages: Int
    var hasNext: Bool
    var hasPrev: Bool

    init(page: Int, perPage: Int, total: Int) {
        let totalPages = perPage > 0 ? (total + perPage - 1) / perPage : 0

        self.page = page
        self.perPage = perPage
        self.total = total
        self.totalPages = totalPages
        self.hasNext = page < totalPages
        self.hasPrev = page > 1 && total > 0
    }
}

/// Query param `?page=&per_page=` yang sudah divalidasi.
struct PageRequest {
    static let defaultPerPage = 5
    static let maxPerPage = 100

    var page: Int
    var perPage: Int

    var offset: Int { (self.page - 1) * self.perPage }

    init(_ req: Request) throws {
        self.page = try Self.intQuery("page", on: req) ?? 1
        self.perPage = try Self.intQuery("per_page", on: req) ?? Self.defaultPerPage

        guard self.page >= 1 else {
            throw Abort(.badRequest, reason: "Query `page` minimal 1")
        }
        guard self.perPage >= 1, self.perPage <= Self.maxPerPage else {
            throw Abort(
                .badRequest,
                reason: "Query `per_page` harus antara 1 sampai \(Self.maxPerPage)"
            )
        }
    }

    /// Nilai yang bukan angka ditolak, bukan diam-diam jatuh ke default.
    private static func intQuery(_ key: String, on req: Request) throws -> Int? {
        guard let raw = req.query[String.self, at: key] else { return nil }

        guard let value = Int(raw) else {
            throw Abort(.badRequest, reason: "Query `\(key)` harus berupa angka")
        }

        return value
    }
}

/// Cuma dipakai buat dokumentasi query param di OpenAPI.
struct PageQueryDTO: Content {
    var page: Int?
    var perPage: Int?
}
