import SwiftUI
import VisionKit

struct MistakeDocumentScanner: UIViewControllerRepresentable {
    let onComplete: (VNDocumentCameraScan) -> Void
    let onCancel: () -> Void
    let onFailure: (Error) -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(
        _ uiViewController: VNDocumentCameraViewController,
        context: Context
    ) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(owner: self)
    }

    final class Coordinator: NSObject, @MainActor VNDocumentCameraViewControllerDelegate {
        private let owner: MistakeDocumentScanner

        init(owner: MistakeDocumentScanner) {
            self.owner = owner
        }

        @MainActor
        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            owner.onComplete(scan)
        }

        @MainActor
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            owner.onCancel()
        }

        @MainActor
        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            owner.onFailure(error)
        }
    }
}

@MainActor
final class MistakeDocumentScanSession {
    private let scan: VNDocumentCameraScan
    private var nextPageIndex = 0

    init(scan: VNDocumentCameraScan) {
        self.scan = scan
    }

    func nextCropSource() -> MistakeCropSource? {
        guard nextPageIndex < scan.pageCount else { return nil }
        let pageIndex = nextPageIndex
        nextPageIndex += 1
        return MistakeCropSource(
            image: scan.imageOfPage(at: pageIndex),
            originalFileName: "扫描页 \(pageIndex + 1)"
        )
    }
}
