import Foundation

/// Role: Shelf. Typed transport failures. This product has no remote catalog.
enum PugillarClientError: Error, Equatable, Sendable {
    case notFound
    case decoding
    case transport
    case cancelled
    case invalidResponse
}

/// Role: Shelf. One HTTP hop. Injected so tests never leave the process.
protocol PugillarCarrying: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

/// Role: Shelf. URLSession hop, 15 s timeout, app User-Agent on every request.
struct PugillarSessionCarrier: PugillarCarrying {
    let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 15
        configuration.httpAdditionalHeaders = ["User-Agent": PugillarClient.userAgent]
        self.session = URLSession(configuration: configuration)
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}

/// Role: Shelf. JSON number or numeric string; missing stays nil.
struct LooseDouble: Sendable, Equatable {
    var value: Double?
}

extension LooseDouble: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = nil
            return
        }
        if let number = try? container.decode(Double.self) {
            value = number
            return
        }
        if let number = try? container.decode(Int.self) {
            value = Double(number)
            return
        }
        if let text = try? container.decode(String.self) {
            value = Double(text)
            return
        }
        value = nil
    }
}

/// Role: Shelf. Owns the session. Offline diptych — contact URL opens in Safari, not here.
actor PugillarClient {
    static let userAgent = "Pugillar/1.0 (iOS; +https://navox-ydonosor.pro)"
    static let contactURL = URL(string: "https://navox-ydonosor.pro/contact-us")!

    private let carrier: any PugillarCarrying

    init(carrier: any PugillarCarrying) {
        self.carrier = carrier
    }

    init() {
        self.carrier = PugillarSessionCarrier()
    }

    func getJSON<DTO: Decodable>(_ type: DTO.Type, from url: URL) async throws -> DTO {
        try Task.checkCancellation()
        let body = try await fetch(request(for: url))
        do {
            return try JSONDecoder().decode(DTO.self, from: body)
        } catch is CancellationError {
            throw PugillarClientError.cancelled
        } catch {
            throw PugillarClientError.decoding
        }
    }

    private func request(for url: URL) -> URLRequest {
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        return request
    }

    private func fetch(_ request: URLRequest) async throws -> Data {
        do {
            return try await send(request)
        } catch let error as PugillarClientError {
            throw error
        } catch is CancellationError {
            throw PugillarClientError.cancelled
        } catch {
            if Self.cancelled(error) {
                throw PugillarClientError.cancelled
            }
            guard Self.transient(error) else { throw PugillarClientError.transport }
            do {
                return try await send(request)
            } catch let error as PugillarClientError {
                throw error
            } catch is CancellationError {
                throw PugillarClientError.cancelled
            } catch {
                if Self.cancelled(error) { throw PugillarClientError.cancelled }
                throw PugillarClientError.transport
            }
        }
    }

    private func send(_ request: URLRequest) async throws -> Data {
        try Task.checkCancellation()
        let (data, response) = try await carrier.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw PugillarClientError.invalidResponse
        }
        if http.statusCode == 404 {
            throw PugillarClientError.notFound
        }
        guard (200 ..< 300).contains(http.statusCode) else {
            throw PugillarClientError.transport
        }
        return data
    }

    private static func transient(_ error: Error) -> Bool {
        guard let urlError = error as? URLError else { return false }
        switch urlError.code {
        case .timedOut, .networkConnectionLost, .notConnectedToInternet,
             .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
            return true
        default:
            return false
        }
    }

    private static func cancelled(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        return (error as? URLError)?.code == .cancelled
    }
}
