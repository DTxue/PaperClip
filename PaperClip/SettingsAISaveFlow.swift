import SwiftUI

extension AISettingsView {
    var currentSettingsSnapshot: AISettingsSnapshot {
        AISettingsSnapshot(
            apiKey: apiKey,
            doubaoEndpointID: doubaoEndpointID,
            deepSeekAPIKey: deepSeekAPIKey
        )
    }

    func scheduleSettingsSave() {
        guard normalizedSettingsSnapshot() != lastSavedSettings else {
            settingsSaveAction.cancel()
            return
        }
        settingsSaveAction.schedule(after: .milliseconds(500)) {
            saveSettings()
        }
    }

    func normalizedSettingsSnapshot() -> AISettingsSnapshot {
        let normalizedAPIKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedDoubaoEndpointID = AIService.migratedDoubaoInferenceID(doubaoEndpointID)
        let normalizedDeepSeekAPIKey = deepSeekAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        return AISettingsSnapshot(
            apiKey: normalizedAPIKey,
            doubaoEndpointID: normalizedDoubaoEndpointID,
            deepSeekAPIKey: normalizedDeepSeekAPIKey
        )
    }

    func saveSettings() {
        let settings = normalizedSettingsSnapshot()

        if apiKey != settings.apiKey { apiKey = settings.apiKey }
        if doubaoEndpointID != settings.doubaoEndpointID {
            doubaoEndpointID = settings.doubaoEndpointID
        }
        if deepSeekAPIKey != settings.deepSeekAPIKey {
            deepSeekAPIKey = settings.deepSeekAPIKey
        }

        guard settings != lastSavedSettings else { return }

        KeychainService.save(settings.apiKey, for: .doubaoAPIKey)
        KeychainService.save(settings.doubaoEndpointID, for: .doubaoModelID)
        KeychainService.save(settings.deepSeekAPIKey, for: .deepSeekAPIKey)
        lastSavedSettings = settings
    }
}
