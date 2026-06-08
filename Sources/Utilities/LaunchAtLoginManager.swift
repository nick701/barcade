import ServiceManagement

enum LaunchAtLoginManager {
    static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            guard SMAppService.mainApp.status != .enabled else {
                return
            }
            try SMAppService.mainApp.register()
        } else {
            guard SMAppService.mainApp.status != .notRegistered else {
                return
            }
            try SMAppService.mainApp.unregister()
        }
    }
}
