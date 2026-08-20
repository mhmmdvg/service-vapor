@testable import CashierService
import Foundation
import Testing

@Suite("Snake case JSON")
struct ContentCodingTests {
    /// Nama properti yang benar-benar dipakai DTO, termasuk yang berakhiran akronim.
    private struct SampleDTO: Codable {
        var id = 0
        var email = 0
        var customerID = 0
        var cashierID = 0
        var userID = 0
        var deviceID = 0
        var sparePartID = 0
        var orderItemID = 0
        var orderCode = 0
        var qrToken = 0
        var createdAt = 0
        var revokedAt = 0
        var serviceFee = 0
        var finalCost = 0
        var priceAtUse = 0
        var passwordHash = 0
        var customerName = 0
        var deviceBrand = 0
        var itemsCount = 0
        var accessToken = 0
        var refreshToken = 0
        var expiresIn = 0
        var pageInfo = 0
        var perPage = 0
        var totalPages = 0
        var hasNext = 0
        var requestID = 0
    }

    /// Strategi buat swagger.json harus persis sama dengan yang dipakai
    /// JSONEncoder buat body beneran, kalau tidak dokumentasinya bohong.
    @Test("Konversi kunci sama dengan Foundation")
    func matchesFoundation() throws {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase

        let encoded = try JSONSerialization.jsonObject(
            with: encoder.encode(SampleDTO())
        )
        let foundationKeys = try #require(encoded as? [String: Int]).keys.sorted()
        let ourKeys = Mirror(reflecting: SampleDTO()).children
            .compactMap { $0.label?.snakeCased() }
            .sorted()

        #expect(!foundationKeys.isEmpty)
        #expect(ourKeys == foundationKeys)
    }

    @Test("Akronim di akhir tidak dipecah")
    func trailingAcronym() {
        #expect("customerID".snakeCased() == "customer_id")
        #expect("orderCode".snakeCased() == "order_code")
        #expect("id".snakeCased() == "id")
        #expect("qrToken".snakeCased() == "qr_token")
    }

    @Test("Response DTO ter-encode snake_case")
    func encodesResponse() throws {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase

        let response = APIResponse(
            success: true,
            message: "ok",
            data: [Int](),
            pageInfo: PageInfo(page: 1, perPage: 20, total: 152)
        )
        let json = try JSONSerialization.jsonObject(
            with: encoder.encode(response)
        )
        let object = try #require(json as? [String: Any])
        let pageInfo = try #require(object["page_info"] as? [String: Any])

        #expect(object["success"] as? Bool == true)
        #expect(pageInfo["per_page"] as? Int == 20)
        #expect(pageInfo["total_pages"] as? Int == 8)
        #expect(pageInfo["has_next"] as? Bool == true)
    }

    @Test("Request body dibaca dari snake_case")
    func decodesRequest() throws {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let body = Data(
            #"{"refresh_token": "abc.def.ghi"}"#.utf8
        )
        let dto = try decoder.decode(RefreshTokenDTO.self, from: body)

        #expect(dto.refreshToken == "abc.def.ghi")
    }
}
