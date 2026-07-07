import SwiftUI

struct CropDimmingOverlay: View {
    let imageFrame: CGRect
    let normRect: CGRect

    private var sel: CGRect {
        normRect.rect(in: imageFrame)
    }

    var body: some View {
        ZStack {
            dimRect(x: imageFrame.minX, y: imageFrame.minY,
                    w: imageFrame.width,
                    h: max(sel.minY - imageFrame.minY, 0))
            dimRect(x: imageFrame.minX, y: sel.maxY,
                    w: imageFrame.width,
                    h: max(imageFrame.maxY - sel.maxY, 0))
            dimRect(x: imageFrame.minX, y: sel.minY,
                    w: max(sel.minX - imageFrame.minX, 0),
                    h: sel.height)
            dimRect(x: sel.maxX, y: sel.minY,
                    w: max(imageFrame.maxX - sel.maxX, 0),
                    h: sel.height)

            Rectangle()
                .stroke(Color.accentColor, lineWidth: 2)
                .frame(width: sel.width, height: sel.height)
                .position(x: sel.midX, y: sel.midY)

            cropRuleOfThirdsGrid
                .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var cropRuleOfThirdsGrid: Path {
        let gx = sel.width / 3
        let gy = sel.height / 3
        return Path { path in
            for offset in [gx, gx * 2] {
                path.move(to: CGPoint(x: sel.minX + offset, y: sel.minY))
                path.addLine(to: CGPoint(x: sel.minX + offset, y: sel.maxY))
            }
            for offset in [gy, gy * 2] {
                path.move(to: CGPoint(x: sel.minX, y: sel.minY + offset))
                path.addLine(to: CGPoint(x: sel.maxX, y: sel.minY + offset))
            }
        }
    }

    private func dimRect(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat) -> some View {
        Color.black.opacity(0.6)
            .frame(width: max(w, 0), height: max(h, 0))
            .position(x: x + max(w, 0) / 2, y: y + max(h, 0) / 2)
    }
}
