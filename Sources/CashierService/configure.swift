import NIOSSL
import Fluent
import FluentPostgresDriver
import Vapor
import JWT

/// configures your application
func configure(_ app: Application) async throws {
    let jwtSecret = Environment.get("JWT_SECRET") ?? "jwt-secret"

//    // Bind every interface, not just loopback, so the Android emulator and physical
//    // devices on the LAN can reach the dev server. Override with SERVER_HOSTNAME.
//    app.http.server.configuration.hostname = Environment.get("SERVER_HOSTNAME") ?? "0.0.0.0"
//    app.http.server.configuration.port = Environment.get("SERVER_PORT").flatMap(Int.init) ?? 8080

    // uncomment to serve files from /Public folder
     app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    app.databases.use(DatabaseConfigurationFactory.postgres(configuration: .init(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber,
        username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
        password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
        database: Environment.get("DATABASE_NAME") ?? "vapor_database",
        tls: .prefer(try .init(configuration: .clientDefault)))
    ), as: .psql)

    await app.jwt.keys.add(hmac: .init(from: jwtSecret), digestAlgorithm: .sha256)
    app.middleware.use(ErrorEnvelopeMiddleware())
    
    
//    app.migrations.add(CreateTodo())
    
    app.migrations.add(CreateUser())
    app.migrations.add(SeedUser())
    app.migrations.add(CreateRefreshToken())
    app.migrations.add(CreateCustomer())
    app.migrations.add(SeedCustomer())
    app.migrations.add(CreateDevice())
    app.migrations.add(CreateOrder())
    app.migrations.add(CreateOrderItem())
    app.migrations.add(AddServiceFeeToOrderItem())
    app.migrations.add(CreatePayment())
    app.migrations.add(CreateOrderItemStatusHistory())
    app.migrations.add(CreateSparePart())
    app.migrations.add(CreateOrderPart())
    
    

    // register routes
    try routes(app)
}
