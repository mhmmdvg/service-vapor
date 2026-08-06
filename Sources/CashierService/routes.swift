import Fluent
import Vapor
import JWT
import VaporToOpenAPI

func routes(_ app: Application) throws {
    let protected = app
        .grouped(
            UserPayload.authenticator(),
            UserPayload.guardMiddleware(throwing: Abort(.unauthorized, reason: "User not authenticated"))
        )
        .groupedOpenAPI(auth: .bearer())
    
    app.get { req async in
        "It works!"
    }
    
    app.get("hello") { req async -> String in
        "Hello, world!"
    }
    
    app.get("swagger.json") { req in
        req.application.routes.openAPI(
            info: InfoObject(
                title: "CashierService API",
                description: "API untuk aplikasi kasir service HP",
                version: "1.0.0"
            )
        )
    }
    .excludeFromOpenAPI()
    
    try app.register(collection: LoginController())
    try app.register(collection: TrackingController())
    try protected.register(collection: UserController())
    try protected.register(collection: CustomerController())
    try protected.register(collection: DeviceController())
    try protected.register(collection: OrderController())
    try protected.register(collection: OrderItemController())
}
