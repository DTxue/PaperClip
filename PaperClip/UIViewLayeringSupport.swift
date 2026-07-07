import UIKit

enum UIViewLayeringSupport {
    @MainActor
    static func bringSubviewToFrontIfNeeded(_ view: UIView, in parentView: UIView) {
        guard view.superview === parentView,
              parentView.subviews.last !== view
        else { return }
        parentView.bringSubviewToFront(view)
    }
}
