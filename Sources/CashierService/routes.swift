import Fluent
import Vapor
import JWT

func routes(_ app: Application) throws {
    let protected = app.grouped(
        UserPayload.authenticator(),
        UserPayload.guardMiddleware(throwing: Abort(.unauthorized, reason: "User not authenticated"))
    )
    app.get { req async in
        "It works!"
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }
    
    try app.register(collection: LoginController())
    try protected.register(collection: UserController())
    try protected.register(collection: CustomerController())
    try protected.register(collection: DeviceController())
    try protected.register(collection: OrderController())
}
