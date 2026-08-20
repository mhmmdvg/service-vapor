//
//  APIResponse.swift
//  CashierService
//
//  Created by Muhammad Vikri on 02/08/26.
//

import Foundation
import Vapor

struct APIResponse<T: Content>: Content {
    var success: Bool
    var message: String
    var data: T? = nil
    /// Hanya diisi endpoint list yang berpaginasi.
    var pageInfo: PageInfo? = nil
    /// Tidak perlu diisi controller, otomatis diisi waktu response di-encode.
    var meta: ResponseMeta? = nil
}

extension APIResponse {
    /// Vapor memanggil ini buat tiap handler yang mengembalikan `APIResponse`, jadi
    /// `meta` diisi di satu tempat dan controller tidak perlu tahu soal request id.
    func encodeResponse(for request: Request) async throws -> Response {
        var body = self
        body.meta = ResponseMeta(request: request)

        let response = Response()
        try response.content.encode(body)

        return response
    }
}

struct ResponseMeta: Content {
    var timestamp: String
    var requestID: String

    /// `request.id` juga dipakai Vapor di log metadata, jadi request id di response
    /// bisa langsung dicocokkan dengan barisan lognya.
    init(request: Request) {
        self.timestamp = Date().formatted(Self.timestampStyle)
        self.requestID = request.id
    }

    private static let timestampStyle = Date.ISO8601FormatStyle(
        timeZoneSeparator: .colon,
        includingFractionalSeconds: true,
        timeZone: .current
    )
}
