//
//  SearchQuery.swift
//  CashierService
//
//  Created by Muhammad Vikri on 20/08/26.
//

import Fluent
import Vapor

/// Query param `?search=` yang sudah divalidasi dan aman dipakai sebagai pola `ILIKE`.
///
/// Pencarian dikerjakan di sisi database (substring, case-insensitive) supaya
/// paginasi dan `total` tetap benar. Fuzzy matching di memori butuh semua order
/// di-load dulu buat diskor, jadi tidak dipakai di sini.
struct SearchQuery {
    static let maxLength = 100

    /// Teks asli setelah di-trim, dipakai buat pesan error / logging.
    let term: String

    /// Pola siap pakai buat `ILIKE`, wildcard dari user sudah di-escape.
    var pattern: String { "%\(Self.escaped(self.term))%" }

    /// Mengembalikan `nil` kalau query param-nya memang tidak dikirim atau cuma spasi.
    init?(_ req: Request) throws {
        guard let raw = req.query[String.self, at: "search"] else { return nil }

        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        guard trimmed.count <= Self.maxLength else {
            throw Abort(
                .badRequest,
                reason: "Query `search` maksimal \(Self.maxLength) karakter"
            )
        }

        self.term = trimmed
    }

    /// `%` dan `_` yang diketik user diperlakukan sebagai karakter biasa,
    /// bukan wildcard `LIKE`.
    private static func escaped(_ value: String) -> String {
        value
            .replacingOccurrences(of: #"\"#, with: #"\\"#)
            .replacingOccurrences(of: "%", with: #"\%"#)
            .replacingOccurrences(of: "_", with: #"\_"#)
    }
}

extension QueryBuilder<Order> {
    /// Saring order berdasarkan kode order, nama customer, atau nomor HP customer.
    /// Butuh join ke `customers`, dan karena relasinya many-to-one jumlah barisnya
    /// tidak berubah — `count()` tetap akurat.
    @discardableResult
    func filter(search: SearchQuery?) -> Self {
        guard let search else { return self }

        let pattern = search.pattern

        return
            self
            .join(Customer.self, on: \Order.$customer.$id == \Customer.$id)
            .group(.or) { group in
                group.filter(\Order.$orderCode, .custom("ILIKE"), pattern)
                group.filter(Customer.self, \.$name, .custom("ILIKE"), pattern)
                group.filter(Customer.self, \.$phone, .custom("ILIKE"), pattern)
            }
    }
}

/// Cuma dipakai buat dokumentasi query param di OpenAPI.
struct OrderListQueryDTO: Content {
    var page: Int?
    var perPage: Int?
    var search: String?
}
