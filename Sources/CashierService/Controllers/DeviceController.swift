//
//  DeviceController.swift
//  CashierService
//
//  Created by Muhammad Vikri on 02/08/26.
//

import Fluent
import Vapor

struct DeviceController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let devices = routes.grouped("devices")

        devices.get(use: self.index)
    }

    @Sendable
    func index(req: Request) async throws -> APIResponse<[DeviceDTO]> {
        let devices = try await Device.query(on: req.db).all().map {
            $0.toDTO()
        }

        return APIResponse(
            success: true,
            message: "Success get all Devices",
            data: devices
        )

    }
}
