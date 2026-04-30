import SwiftUI

@main
struct MVVMDemoApp: App {
    private let environment = AppEnvironment.live

    var body: some Scene {
        WindowGroup {
            ContentView(environment: environment)
        }
    }
}
