import Foundation
@testable import OpenMeteoKit

/// Hand-written JSON in `Fixtures/`, in the exact shapes Open-Meteo returns, for Istanbul on October 8, 2026.
enum Fixture {
    struct Missing: Error {
        let name: String
    }

    static func data(_ name: String) throws -> Data {
        guard let url = Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures") else {
            throw Missing(name: name)
        }
        return try Data(contentsOf: url)
    }

    static func decode<T: Decodable>(_ type: T.Type, from name: String) throws -> T {
        try JSONDecoder().decode(T.self, from: data(name))
    }

    /// Istanbul's time zone, which every fixture uses.
    static let istanbul = TimeZone(identifier: "Europe/Istanbul")!

    /// A local time in Istanbul.
    static func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = istanbul
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }
}

/// A canned HTTP response.
struct StubResponse: Sendable {
    var status: Int
    var headers: [String: String]
    var body: Data

    static func json(_ fixture: String, status: Int = 200) throws -> StubResponse {
        try StubResponse(status: status, headers: ["Content-Type": "application/json"], body: Fixture.data(fixture))
    }

    static func status(_ status: Int, body: String = "") -> StubResponse {
        StubResponse(status: status, headers: [:], body: Data(body.utf8))
    }
}

typealias StubHandler = @Sendable (URLRequest) throws -> StubResponse

/// Answers requests from a handler registered for the request's host, so every test can run in parallel with its
/// own host. Nothing ever reaches the network.
final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url, let host = url.host, let handler = StubRegistry.shared.handler(for: host) else {
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
            return
        }
        StubRegistry.shared.record(request, for: host)
        do {
            let stub = try handler(request)
            guard let response = HTTPURLResponse(url: url, statusCode: stub.status, httpVersion: "HTTP/1.1", headerFields: stub.headers) else {
                client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
                return
            }
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: stub.body)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

final class StubRegistry: @unchecked Sendable {
    static let shared = StubRegistry()

    private let lock = NSLock()
    private var handlers: [String: StubHandler] = [:]
    private var requests: [String: [URLRequest]] = [:]

    func register(_ handler: @escaping StubHandler, for host: String) {
        lock.withLock { handlers[host] = handler }
    }

    func handler(for host: String) -> StubHandler? {
        lock.withLock { handlers[host] }
    }

    func record(_ request: URLRequest, for host: String) {
        lock.withLock { requests[host, default: []].append(request) }
    }

    func requests(for host: String) -> [URLRequest] {
        lock.withLock { requests[host] ?? [] }
    }
}

/// A client wired to the stub, on a host of its own.
struct StubbedClient {
    let host: String
    let client: OpenMeteoClient

    init(apiKey: String? = nil, handler: @escaping StubHandler) {
        host = "stub-" + UUID().uuidString.lowercased() + ".open-meteo.test"
        StubRegistry.shared.register(handler, for: host)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        client = OpenMeteoClient(configuration: OpenMeteoConfiguration(
            endpoints: .host(URL(string: "https://" + host)!),
            apiKey: apiKey,
            session: URLSession(configuration: configuration)
        ))
    }

    /// Every request the client sent, in order.
    var requests: [URLRequest] {
        StubRegistry.shared.requests(for: host)
    }

    /// The last request's path.
    var lastPath: String? {
        requests.last?.url?.path
    }

    /// The last request's query items, decoded.
    var lastQuery: [URLQueryItem] {
        guard let url = requests.last?.url,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else { return [] }
        return components.queryItems ?? []
    }

    /// The value of a query item of the last request.
    func lastQueryValue(_ name: String) -> String? {
        lastQuery.first(where: { $0.name == name })?.value
    }
}
