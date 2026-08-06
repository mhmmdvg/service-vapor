//
//  ErrorEnvelopeMiddleware.swift
//  CashierService
//
//  Created by Muhammad Vikri on 03/08/26.
//

import Vapor

struct ErrorResponse: Content {
    var status: Bool
    var message: String
}

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

            let errorResponse = ErrorResponse(status: false, message: message)

            let response = Response(status: status)
            try response.content.encode(errorResponse)
            return response
        }
    }
}
