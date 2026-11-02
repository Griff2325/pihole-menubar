import SwiftUI

/// Renders the README images offscreen with made-up numbers (no real network data).
@MainActor
enum Screenshots {
    static let sample = Summary(total: 18_452, blocked: 3_907, percentBlocked: 21.2,
                                domainsOnBlocklist: 276_901, activeClients: 9)

    static func render(to dir: String) {
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        for scheme in [ColorScheme.light, .dark] {
            let tag = scheme == .dark ? "dark" : "light"
            save(panel(.on(sample), scheme), "\(dir)/popover-on-\(tag).png")
            save(panel(.off(sample, secondsLeft: 240), scheme), "\(dir)/popover-off-\(tag).png")
            save(strip(scheme), "\(dir)/menubar-\(tag).png")
        }
    }

    private static func panel(_ s: Status, _ scheme: ColorScheme) -> some View {
        PanelView().environmentObject(Model(preview: s))
            .background(scheme == .dark ? Color(white: 0.16) : Color(white: 0.96))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(24)
            .background(scheme == .dark ? Color(red: 0.1, green: 0.2, blue: 0.35) : Color(red: 0.55, green: 0.7, blue: 0.9))
            .environment(\.colorScheme, scheme)
    }

    private static func strip(_ scheme: ColorScheme) -> some View {
        let fg: Color = scheme == .dark ? .white : .black
        func cell(_ s: Status, _ label: String) -> some View {
            VStack(spacing: 6) {
                MenuBarIcon(status: s).font(.system(size: 15)).foregroundStyle(fg)
                Text(label).font(.system(size: 11)).foregroundStyle(fg.opacity(0.7))
            }
        }
        return HStack(spacing: 28) {
            cell(.on(sample), "blocking on")
            cell(.off(sample, secondsLeft: nil), "blocking off")
            cell(.offline(""), "can't reach")
        }
        .padding(.horizontal, 28).padding(.vertical, 14)
        .background(scheme == .dark ? Color(white: 0.12) : Color(white: 0.9))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(10)
        .environment(\.colorScheme, scheme)
    }

    private static func save<V: View>(_ view: V, _ path: String) {
        let r = ImageRenderer(content: view)
        r.scale = 2
        guard let img = r.nsImage, let t = img.tiffRepresentation,
              let png = NSBitmapImageRep(data: t)?.representation(using: .png, properties: [:]) else { return }
        try? png.write(to: URL(fileURLWithPath: path))
    }
}
