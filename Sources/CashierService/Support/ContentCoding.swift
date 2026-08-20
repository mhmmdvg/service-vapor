//
//  ContentCoding.swift
//  CashierService
//
//  Created by Muhammad Vikri on 15/08/26.
//

import Foundation
import Vapor
import VaporToOpenAPI

/// Semua body JSON (request maupun response) pakai snake_case, jadi properti DTO
/// tetap ditulis camelCase seperti biasa di Swift tanpa perlu `CodingKeys` manual.
func configureContentCoding() {
    ContentConfiguration.global.use(
        encoder: JSONEncoder.custom(
            dates: .iso8601,
            keys: .convertToSnakeCase
        ),
        for: .json
    )
    ContentConfiguration.global.use(
        decoder: JSONDecoder.custom(
            dates: .iso8601,
            keys: .convertFromSnakeCase
        ),
        for: .json
    )

    // SwiftOpenAPI punya konversi snake_case sendiri yang memecah tiap huruf kapital
    // ("customerID" jadi "customer_i_d"), beda dengan Foundation. Dipakaikan versi
    // di bawah supaya swagger.json cocok dengan JSON yang benar-benar dikirim.
    KeyEncodingStrategy.default = .custom { $0.snakeCased() }
}

extension String {
    /// Menyamai `JSONEncoder.KeyEncodingStrategy.convertToSnakeCase`: pemisah
    /// disisipkan di awal kata, dan huruf kapital berurutan dianggap satu kata
    /// ("customerID" jadi "customer_id", "orderCode" jadi "order_code").
    func snakeCased() -> String {
        var result = ""
        var index = self.startIndex

        while index < self.endIndex {
            let character = self[index]
            let next = self.index(after: index)

            if character.isUppercase, !result.isEmpty {
                let previous = self[self.index(before: index)]
                let nextIsLowercase =
                    next < self.endIndex && self[next].isLowercase

                if !previous.isUppercase || nextIsLowercase {
                    result += "_"
                }
            }

            result += character.lowercased()
            index = next
        }

        return result
    }
}
