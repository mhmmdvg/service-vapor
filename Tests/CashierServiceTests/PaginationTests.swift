@testable import CashierService
import Testing
import Vapor

@Suite("Pagination")
struct PaginationTests {
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

    @Test("Halaman pertama dari 152 baris")
    func firstPage() {
        let info = PageInfo(page: 1, perPage: 20, total: 152)

        #expect(info.totalPages == 8)
        #expect(info.hasNext)
        #expect(!info.hasPrev)
    }

    @Test("Halaman terakhir tidak punya next")
    func lastPage() {
        let info = PageInfo(page: 8, perPage: 20, total: 152)

        #expect(info.totalPages == 8)
        #expect(!info.hasNext)
        #expect(info.hasPrev)
    }

    @Test("Total pas kelipatan per_page tidak bikin halaman kosong")
    func exactMultiple() {
        let info = PageInfo(page: 2, perPage: 20, total: 40)

        #expect(info.totalPages == 2)
        #expect(!info.hasNext)
    }

    @Test("Hasil kosong")
    func empty() {
        let info = PageInfo(page: 1, perPage: 20, total: 0)

        #expect(info.totalPages == 0)
        #expect(!info.hasNext)
        #expect(!info.hasPrev)
    }

    @Test("Halaman di luar jangkauan")
    func beyondLastPage() {
        let info = PageInfo(page: 9, perPage: 20, total: 152)

        #expect(!info.hasNext)
        #expect(info.hasPrev)
    }

    @Test("Query kosong pakai default")
    func defaults() async throws {
        let (app, req) = try await self.request("/orders")
        defer { Task { try await app.asyncShutdown() } }

        let page = try PageRequest(req)

        #expect(page.page == 1)
        #expect(page.perPage == PageRequest.defaultPerPage)
        #expect(page.offset == 0)
    }

    @Test("Offset dihitung dari page & per_page")
    func offset() async throws {
        let (app, req) = try await self.request("/orders?page=3&per_page=5")
        defer { Task { try await app.asyncShutdown() } }

        let page = try PageRequest(req)

        #expect(page.offset == 10)
    }

    @Test("Query tidak valid ditolak", arguments: [
        "/orders?page=0",
        "/orders?page=-1",
        "/orders?per_page=0",
        "/orders?per_page=101",
        "/orders?page=abc",
        "/orders?per_page=20.5",
    ])
    func rejectsInvalidQuery(uri: String) async throws {
        let (app, req) = try await self.request(uri)
        defer { Task { try await app.asyncShutdown() } }

        #expect(throws: (any Error).self) {
            try PageRequest(req)
        }
    }
}
