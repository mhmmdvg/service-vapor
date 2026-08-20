//
//  ErrorEnvelopeMiddleware.swift
//  CashierService
//
//  Created by Muhammad Vikri on 03/08/26.
//

import Vapor

struct ErrorEnvelopeMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder)
        async throws -> Response
    {
        do {
            return try await next.respond(to: request)
        } catch {
            request.logger.report(error: error)
            dump(error)

            let status: HTTPResponseStatus
            let message: String

            if let abortError = error as? (any AbortError) {
                status = abortError.status
                message = abortError.reason
            } else {
                status = .internalServerError
                message = error.localizedDescription
            }

            // Pakai envelope yang sama dengan response sukses supaya client cuma
            // perlu satu parser, sekaligus dapat `meta.request_id` buat trace error.
            let response = try await APIResponse<String>(
                success: false,
                message: message
            )
            .encodeResponse(for: request)
            response.status = status

            return response
        }
    }
}
