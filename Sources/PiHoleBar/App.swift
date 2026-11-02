import SwiftUI

@main
struct PiHoleBarApp: App {
    @StateObject private var model = Model()

    var body: some Scene {
        MenuBarExtra {
            PanelView().environmentObject(model)
        } label: {
            Image(systemName: model.iconName)
        }
        .menuBarExtraStyle(.window)
    }
}

struct PanelView: View {
    @EnvironmentObject var model: Model
    @State private var showSettings = false
    @State private var hostField = ""
    @State private var passField = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if showSettings || isUnconfigured { settings } else { content }
            Divider()
            HStack {
                Button("Open Dashboard") { model.openDashboard() }
                Spacer()
                Button { toggleSettings() } label: { Image(systemName: "gearshape") }
                    .help("Settings")
                Button("Quit") { NSApplication.shared.terminate(nil) }
            }
        }
        .padding(14)
        .frame(width: 270)
    }

    private var isUnconfigured: Bool { if case .unconfigured = model.status { return true } else { return false } }

    private func toggleSettings() {
        hostField = model.host; passField = model.password
        showSettings.toggle()
    }

    @ViewBuilder private var content: some View {
        switch model.status {
        case .loading, .unconfigured:
            ProgressView().frame(maxWidth: .infinity)
        case .offline(let msg):
            Label("Can't reach Pi-hole", systemImage: "exclamationmark.triangle.fill").foregroundStyle(.orange)
            Text(msg).font(.caption).foregroundStyle(.secondary)
        case .on(let s):
            header("Blocking on", "checkmark.shield.fill", .green)
            stats(s)
            Menu("Disable blocking…") {
                Button("For 5 minutes") { model.setBlocking(enabled: false, seconds: 300) }
                Button("For 30 minutes") { model.setBlocking(enabled: false, seconds: 1800) }
                Button("Until I turn it back on") { model.setBlocking(enabled: false) }
            }
        case .off(let s, let left):
            header(left.map { "Blocking off, back in \(($0 + 59) / 60) min" } ?? "Blocking off", "shield.slash.fill", .red)
            stats(s)
            Button("Turn blocking back on") { model.setBlocking(enabled: true) }
        }
    }

    private func header(_ text: String, _ icon: String, _ color: Color) -> some View {
        Label(text, systemImage: icon).font(.headline).foregroundStyle(color)
    }

    private func stats(_ s: Summary) -> some View {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 4) {
            row("Queries today", s.total.formatted())
            row("Blocked", "\(s.blocked.formatted()) (\(String(format: "%.1f", s.percentBlocked))%)")
            row("On blocklists", s.domainsOnBlocklist.formatted())
            row("Active clients", s.activeClients.formatted())
        }
    }

    private func row(_ k: String, _ v: String) -> some View {
        GridRow { Text(k).foregroundStyle(.secondary); Text(v).monospacedDigit() }.font(.callout)
    }

    private var settings: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pi-hole").font(.headline)
            TextField("Address (e.g. pihole.local)", text: $hostField)
            SecureField("Admin password", text: $passField)
            Button("Save") {
                model.saveSettings(host: hostField, password: passField)
                showSettings = false
            }.keyboardShortcut(.defaultAction)
        }
        .textFieldStyle(.roundedBorder)
        .onAppear { hostField = model.host; passField = model.password }
    }
}
