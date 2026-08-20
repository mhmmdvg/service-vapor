//
//  SparePartController.swift
//  CashierService
//
//  Created by Muhammad Vikri on 07/08/26.
//

import Fluent
import Vapor
import VaporToOpenAPI

struct SparePartController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let spareParts = routes.grouped("spare-parts")

        spareParts.get(use: self.index)
            .openAPI(
                summary: "List Spare Parts",
                description: "Ambil semua spare part beserta stock dan harga",
                response: .type(APIResponse<[SparePartDTO]>.self)
            )
        spareParts.post(use: self.create)
            .openAPI(
                summary: "Create Spare Part",
                description: "Tambah spare part baru ke inventory",
                body: .type(SparePartDTO.self),
                response: .type(APIResponse<SparePartDTO>.self)
            )
    }

    @Sendable
    func index(req: Request) async throws -> APIResponse<[SparePartDTO]> {
        let spareParts = try await SparePart.query(on: req.db).all().map {
            $0.toDTO()
        }

        return APIResponse(
            success: true,
            message: "Success get all spare parts",
            data: spareParts
        )
    }

    @Sendable
    func create(req: Request) async throws -> APIResponse<SparePartDTO> {
        let dto = try req.content.decode(SparePartDTO.self)
        let model = dto.toModel()

        try await model.save(on: req.db)

        return APIResponse(
            success: true,
            message: "Spare part created",
            data: model.toDTO()
        )
    }
}
