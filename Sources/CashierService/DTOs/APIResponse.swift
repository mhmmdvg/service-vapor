//
//  APIResponse.swift
//  CashierService
//
//  Created by Muhammad Vikri on 02/08/26.
//

import Vapor

struct APIResponse<T: Content>: Content {
    var status: Bool
    var message: String
    var data: T? = nil
}
