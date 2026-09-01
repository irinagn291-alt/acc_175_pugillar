import XCTest
@testable import Pugillar

private struct ProbeDTO: Decodable {
    var energy: LooseDouble
}

private actor ScriptedCarrier: PugillarCarrying {
    private var results: [Result<(Data, URLResponse), Error>]
    private var requests: [URLRequest] = []

    init(results: [Result<(Data, URLResponse), Error>]) {
        self.results = results
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        guard !results.isEmpty else { throw URLError(.cannotConnectToHost) }
        return try results.removeFirst().get()
    }

    func recordedRequests() -> [URLRequest] {
        requests
    }
}

final class PugillarClientTests: XCTestCase {
    private let url = URL(string: "https://navox-ydonosor.pro/probe")!

    func test_setsUserAgentOnEveryRequest() async throws {
        let carrier = ScriptedCarrier(results: [
            .success((Data("{\"energy\":1}".utf8), http(200))),
        ])
        let client = PugillarClient(carrier: carrier)
        _ = try await client.getJSON(ProbeDTO.self, from: url)
        let request = await carrier.recordedRequests().first
        XCTAssertEqual(request?.value(forHTTPHeaderField: "User-Agent"), PugillarClient.userAgent)
        XCTAssertEqual(request?.timeoutInterval, 15)
        XCTAssertEqual(PugillarClient.userAgent, "Pugillar/1.0 (iOS; +https://navox-ydonosor.pro)")
        XCTAssertEqual(PugillarClient.contactURL.absoluteString, "https://navox-ydonosor.pro/contact-us")
    }

    func test_retriesTransientTransportOnce() async throws {
        let carrier = ScriptedCarrier(results: [
            .failure(URLError(.timedOut)),
            .success((Data("{\"energy\":\"4.5\"}".utf8), http(200))),
        ])
        let client = PugillarClient(carrier: carrier)
        let dto = try await client.getJSON(ProbeDTO.self, from: url)
        XCTAssertEqual(dto.energy.value, 4.5)
        let count = await carrier.recordedRequests().count
        XCTAssertEqual(count, 2)
    }

    func test_doesNotRetry404() async {
        let carrier = ScriptedCarrier(results: [
            .success((Data(), http(404))),
            .success((Data("{\"energy\":1}".utf8), http(200))),
        ])
        let client = PugillarClient(carrier: carrier)
        do {
            _ = try await client.getJSON(ProbeDTO.self, from: url)
            XCTFail("expected notFound")
        } catch {
            XCTAssertEqual(error as? PugillarClientError, .notFound)
        }
        let count = await carrier.recordedRequests().count
        XCTAssertEqual(count, 1)
    }

    func test_malformedJSONIsDecodingError() async {
        let carrier = ScriptedCarrier(results: [
            .success((Data("{".utf8), http(200))),
        ])
        let client = PugillarClient(carrier: carrier)
        do {
            _ = try await client.getJSON(ProbeDTO.self, from: url)
            XCTFail("expected decoding")
        } catch {
            XCTAssertEqual(error as? PugillarClientError, .decoding)
        }
    }

    func test_looseDoubleAcceptsNumberAndString() throws {
        let number = try JSONDecoder().decode(ProbeDTO.self, from: Data("{\"energy\":12.5}".utf8))
        let string = try JSONDecoder().decode(ProbeDTO.self, from: Data("{\"energy\":\"12.5\"}".utf8))
        let missing = try JSONDecoder().decode(ProbeDTO.self, from: Data("{\"energy\":null}".utf8))
        XCTAssertEqual(number.energy.value, 12.5)
        XCTAssertEqual(string.energy.value, 12.5)
        XCTAssertNil(missing.energy.value)
    }

    private func http(_ status: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!
    }
}
