import Foundation

enum MistakeCameraAuthorizationState {
    case notDetermined
    case authorized
    case denied
    case restricted
}

enum MistakeScannerAccessAction: Equatable {
    case requestAccess
    case presentScanner
    case showPermissionError
}

enum MistakeScannerAccessPolicy {
    static func action(
        for state: MistakeCameraAuthorizationState
    ) -> MistakeScannerAccessAction {
        switch state {
        case .notDetermined:
            return .requestAccess
        case .authorized:
            return .presentScanner
        case .denied, .restricted:
            return .showPermissionError
        }
    }
}
