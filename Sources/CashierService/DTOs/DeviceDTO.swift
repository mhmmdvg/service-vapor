//
//  DeviceDTO.swift
//  CashierService
//
//  Created by Muhammad Vikri on 02/08/26.
//

import Fluent
import Vapor

struct DeviceDTO: Content {
    var id: UUID?
    var customerID: Customer.IDValue
    var brand: String
    var model: String
    var color: String
    
    func toModel() -> Device {
        let model = Device()
        
        model.$customer.id = self.customerID
        model.brand = self.brand
        model.model = self.model
        model.color = self.color
        
        return model
    }
}
