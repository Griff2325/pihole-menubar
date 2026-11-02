import Foundation

struct Summary {
    var total = 0
    var blocked = 0
    var percentBlocked = 0.0
    var domainsOnBlocklist = 0
    var activeClients = 0
}

enum BlockingState: Equatable {
    case enabled
    case disabled(secondsLeft: Int?)
}

enum PiHoleError: LocalizedError {
    case badURL, auth, http(Int), decode
    var errorDescription: String? {
        switch self {
        case .badURL: return "Invalid address"
        case .auth: return "Wrong password"
        case .http(let c): return "Pi-hole returned HTTP \(c)"
        case .decode: return "Unexpected reply from Pi-hole"
        }
    }
}

/// Minimal Pi-hole v6 API client. Logs in lazily and re-logs in when the session expires.
actor PiHoleClient {
    private var sid: String?
    private var sidHost: String?
    private let session: URLSession = {
        let c = URLSessionConfiguration.ephemeral
        c.timeoutIntervalForRequest = 6
        return URLSession(configuration: c)
    }()

    func fetch(host: String, password: String) async throws -> (Summary, BlockingState) {
        let s: [String: Any] = try await get(host, password, "/api/stats/summary")
        let b: [String: Any] = try await get(host, password, "/api/dns/blocking")
        let q = s["queries"] as? [String: Any] ?? [:]
        let g = s["gravity"] as? [String: Any] ?? [:]
        let c = s["clients"] as? [String: Any] ?? [:]
        let summary = Summary(
            total: q["total"] as? Int ?? 0,
            blocked: q["blocked"] as? Int ?? 0,
            percentBlocked: (q["percent_blocked"] as? NSNumber)?.doubleValue ?? 0,
            domainsOnBlocklist: g["domains_being_blocked"] as? Int ?? 0,
            activeClients: c["active"] as? Int ?? 0)
        let state: BlockingState = (b["blocking"] as? String) == "enabled"
            ? .enabled : .disabled(secondsLeft: (b["timer"] as? NSNumber)?.intValue)
        return (summary, state)
    }

    /// seconds == nil means "until I turn it back on".
    func setBlocking(host: String, password: String, enabled: Bool, seconds: Int?) async throws {
        let body: [String: Any] = ["blocking": enabled, "timer": enabled ? NSNull() : (seconds as Any? ?? NSNull())]
        let _: [String: Any] = try await send(host, password, "POST", "/api/dns/blocking", body)
    }

    // MARK: - plumbing

    private func get(_ host: String, _ pw: String, _ path: String) async throws -> [String: Any] {
        try await send(host, pw, "GET", path, nil)
    }

    private func send(_ host: String, _ pw: String, _ method: String, _ path: String,
                      _ body: [String: Any]?) async throws -> [String: Any] {
        for attempt in 0..<2 {
            if sid == nil || sidHost != host { sid = nil; try await login(host, pw) }
            let (data, code) = try await raw(host, method, path, body, sid: sid)
            if code == 401 { sid = nil; if attempt == 0 { continue } else { throw PiHoleError.auth } }
            guard (200..<300).contains(code) else { throw PiHoleError.http(code) }
            guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { throw PiHoleError.decode }
            return obj
        }
        throw PiHoleError.auth
    }

    private func login(_ host: String, _ pw: String) async throws {
        let (data, code) = try await raw(host, "POST", "/api/auth", ["password": pw], sid: nil)
        if code == 401 { throw PiHoleError.auth }
        guard (200..<300).contains(code),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let s = (obj["session"] as? [String: Any])?["sid"] as? String else { throw PiHoleError.auth }
        sid = s
        sidHost = host
    }

    private func raw(_ host: String, _ method: String, _ path: String,
                     _ body: [String: Any]?, sid: String?) async throws -> (Data, Int) {
        guard let url = URL(string: "http://\(host)\(path)") else { throw PiHoleError.badURL }
        var r = URLRequest(url: url)
        r.httpMethod = method
        if let sid { r.setValue(sid, forHTTPHeaderField: "sid") }
        if let body {
            r.setValue("application/json", forHTTPHeaderField: "Content-Type")
            r.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        let (data, resp) = try await session.data(for: r)
        return (data, (resp as? HTTPURLResponse)?.statusCode ?? 0)
    }
}
