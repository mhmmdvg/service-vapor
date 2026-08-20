@testable import CashierService
import Testing
import Vapor

@Suite("SearchQuery")
struct SearchQueryTests {
    private func request(_ uri: String) async throws -> (Application, Request) {
        let app = try await Application.make(.testing)
        let request = Request(
            application: app,
            method: .GET,
            url: URI(string: uri),
            on: app.eventLoopGroup.next()
        )

        return (app, request)
    }

    private func search(_ uri: String) async throws -> SearchQuery? {
        let (app, req) = try await self.request(uri)
        defer { Task { try await app.asyncShutdown() } }

        return try SearchQuery(req)
    }

    @Test("Tanpa query param hasilnya nil")
    func absent() async throws {
        #expect(try await self.search("/orders?page=2") == nil)
    }

    @Test("Query kosong atau cuma spasi dianggap tidak ada", arguments: [
        "/orders?search=",
        "/orders?search=%20%20",
    ])
    func blank(uri: String) async throws {
        #expect(try await self.search(uri) == nil)
    }

    @Test("Spasi di ujung dibuang")
    func trims() async throws {
        let search = try await self.search("/orders?search=%20budi%20")

        #expect(search?.term == "budi")
        #expect(search?.pattern == "%budi%")
    }

    @Test("Wildcard dari user di-escape, bukan dieksekusi", arguments: [
        ("/orders?search=100%25", #"%100\%%"#),
        ("/orders?search=SV_1", #"%SV\_1%"#),
        ("/orders?search=a%5Cb", #"%a\\b%"#),
    ])
    func escapesWildcards(uri: String, expected: String) async throws {
        #expect(try await self.search(uri)?.pattern == expected)
    }

    @Test("Query kepanjangan ditolak")
    func rejectsTooLong() async throws {
        let (app, req) = try await self.request(
            "/orders?search=\(String(repeating: "a", count: SearchQuery.maxLength + 1))"
        )
        defer { Task { try await app.asyncShutdown() } }

        #expect(throws: (any Error).self) {
            try SearchQuery(req)
        }
    }

    @Test("Query pas di batas panjang diterima")
    func acceptsMaxLength() async throws {
        let term = String(repeating: "a", count: SearchQuery.maxLength)

        #expect(try await self.search("/orders?search=\(term)")?.term == term)
    }
}
