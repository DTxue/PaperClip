import PencilKit

@MainActor
enum PencilToolPickerRegistry {
    private static var pickers: [String: PKToolPicker] = [:]

    static func picker(named autosaveName: String) -> PKToolPicker {
        if let picker = pickers[autosaveName] { return picker }
        let picker = PKToolPicker()
        picker.stateAutosaveName = autosaveName
        pickers[autosaveName] = picker
        return picker
    }
}
