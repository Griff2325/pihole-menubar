import SwiftUI

enum Status {
    case unconfigured, loading
    case on(Summary)
    case off(Summary, secondsLeft: Int?)
    case offline(String)
}

@MainActor
final class Model: ObservableObject {
    @Published var status: Status = .loading
    @Published var host: String { didSet { UserDefaults.standard.set(host, forKey: "host") } }
    @Published var password: String

    private let client = PiHoleClient()
    private var timer: Timer?
    private var generation = 0

    init() {
        host = UserDefaults.standard.string(forKey: "host") ?? "pihole.local"
        password = Keychain.load()
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    func saveSettings(host: String, password: String) {
        self.host = host.trimmingCharacters(in: .whitespaces)
        self.password = password
        Keychain.save(password)
        refresh()
    }

    func refresh() {
        guard !password.isEmpty else { status = .unconfigured; return }
        let (h, p) = (host, password)
        generation += 1
        let gen = generation
        Task {
            do {
                let (summary, state) = try await client.fetch(host: h, password: p)
                guard gen == generation else { return }
                switch state {
                case .enabled: status = .on(summary)
                case .disabled(let s): status = .off(summary, secondsLeft: s)
                }
            } catch {
                guard gen == generation else { return }
                status = .offline(error.localizedDescription)
            }
        }
    }

    func setBlocking(enabled: Bool, seconds: Int? = nil) {
        let (h, p) = (host, password)
        Task {
            try? await client.setBlocking(host: h, password: p, enabled: enabled, seconds: seconds)
            refresh()
        }
    }

    func openDashboard() {
        if let url = URL(string: "http://\(host)/admin") { NSWorkspace.shared.open(url) }
    }
}
