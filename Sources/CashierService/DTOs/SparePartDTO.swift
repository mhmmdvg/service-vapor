//
//  SparePartDTO.swift
//  CashierService
//
//  Created by Muhammad Vikri on 03/08/26.
//

import Fluent
import Vapor

struct SparePartDTO: Content {
    var id: UUID?
    var name: String
    var stock: Int
    var costPrice: Int64
    var sellPrice: Int64
    var sku: String
    
    func toModel() -> SparePart {
        let model = SparePart()
        
        model.name = self.name
        model.stock = self.stock
        model.costPrice = self.costPrice
        model.sellPrice = self.sellPrice
        model.sku = self.sku
        
        return model
    }
}
