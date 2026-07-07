import SwiftUI

extension Binding where Value == Bool {
    /// 将可选状态桥接为 SwiftUI `isPresented` Binding。
    /// 关闭系统弹窗/sheet 时统一清空源对象，避免各页面重复手写 get/set。
    init<Wrapped: Sendable>(isPresenting optional: Binding<Wrapped?>) {
        self.init(
            get: { optional.wrappedValue != nil },
            set: { isPresented in
                if !isPresented {
                    optional.wrappedValue = nil
                }
            }
        )
    }
}
