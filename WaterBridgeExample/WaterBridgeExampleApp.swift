import SwiftUI
import WaterBridgeKit

@main
struct WaterBridgeExampleApp: App {
    init() {
        do {
            let result = try WaterCrashReporter.shared.start()
            if let url = result.recoveredReportURL {
                WaterDebugLogger.event("이전 실행의 크래시 보고서 복구: \(url.lastPathComponent)")
            }
        } catch {
            WaterDebugLogger.log("크래시 수집기 시작 실패: \(error.localizedDescription)", category: .crash, level: .error)
        }
    }

    var body: some Scene {
        WindowGroup { ContentView() }
    }
}
