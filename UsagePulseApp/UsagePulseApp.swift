import SwiftUI

@main
struct UsagePulseApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
        }
        .windowResizability(.contentSize)

        Settings {
            SettingsView()
                .environmentObject(model)
                .frame(width: 520, height: 540)
        }
    }
}

