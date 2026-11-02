import AppKit

/// Single-color outline pie (circle with one slice pulled out). Template image, so macOS tints it for light/dark.
enum PieIcon {
    static func make(dimmed: Bool) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let img = NSImage(size: size, flipped: false) { _ in
            let c = NSPoint(x: 9, y: 9), r: CGFloat = 7
            NSColor.black.withAlphaComponent(dimmed ? 0.4 : 1).setStroke()
            // pie body: everything except a 60-degree wedge at the upper right
            let body = NSBezierPath()
            body.move(to: c)
            body.appendArc(withCenter: c, radius: r, startAngle: 60, endAngle: 360)
            body.close()
            // the pulled-out slice, nudged outward
            let slice = NSBezierPath()
            let o = NSPoint(x: c.x + 1.2, y: c.y + 1.2)
            slice.move(to: o)
            slice.appendArc(withCenter: o, radius: r, startAngle: 0, endAngle: 60)
            slice.close()
            for p in [body, slice] { p.lineWidth = 1.4; p.lineJoinStyle = .round; p.stroke() }
            return true
        }
        img.isTemplate = true
        return img
    }
}
