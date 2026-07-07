import CoreGraphics
import Foundation

@main
struct CanvasSizeReportSupportTests {
    static func main() {
        expect(
            CanvasSizeReportSupport.reportableSize(CGSize(width: 1, height: 20)) == nil,
            "1-point width should not be reportable"
        )
        expect(
            CanvasSizeReportSupport.reportableSize(CGSize(width: 20, height: 20)) == CGSize(width: 20, height: 20),
            "valid canvas size should be reportable"
        )

        let baseline = [
            0: CGSize(width: 768, height: 1024),
            1: CGSize(width: 768, height: 1024)
        ]

        expect(
            !CanvasSizeReportSupport.hasMeaningfulChange(from: baseline, to: baseline),
            "identical reports should not be treated as changed"
        )

        expect(
            !CanvasSizeReportSupport.hasMeaningfulChange(
                from: baseline,
                to: [
                    0: CGSize(width: 768.25, height: 1023.75),
                    1: CGSize(width: 767.6, height: 1024.4)
                ]
            ),
            "sub-pixel layout jitter should not trigger a report"
        )

        expect(
            CanvasSizeReportSupport.hasMeaningfulChange(
                from: baseline,
                to: [
                    0: CGSize(width: 770, height: 1024),
                    1: CGSize(width: 768, height: 1024)
                ]
            ),
            "real size changes should trigger a report"
        )

        expect(
            CanvasSizeReportSupport.hasMeaningfulChange(
                from: baseline,
                to: [
                    0: CGSize(width: 768, height: 1024),
                    2: CGSize(width: 768, height: 1024)
                ]
            ),
            "page set changes should trigger a report"
        )

        print("CanvasSizeReportSupportTests: 5 passed")
    }

    @discardableResult
    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) -> Bool {
        if !condition() {
            print("FAIL: \(message)")
            exit(1)
        }
        return true
    }
}
