import SwiftUI
import WaterBridgeKit

struct ContentView: View {
    @State private var address = "https://example.com"
    @State private var destinations: [URL] = []
    @State private var validationError: String?
    @State private var showsReports = false

    var body: some View {
        NavigationStack(path: $destinations) {
            Form {
                Section {
                    Label("WaterBridgeKit", systemImage: "water.waves")
                        .font(.title2.bold())
                    Text("URL을 입력해 웹페이지를 열고 웹과 네이티브 간 통신을 확인하세요.")
                        .foregroundStyle(.secondary)
                }
                Section("웹페이지 열기") {
                    TextField("https://example.com", text: $address)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onSubmit(openAddress)
                    if let validationError {
                        Text(validationError).foregroundStyle(.red)
                    }
                    Button("웹뷰로 이동", systemImage: "arrow.up.right.square", action: openAddress)
                }
                Section("라이브러리 예제") {
                    Button("브릿지 테스트 페이지", systemImage: "link") {
                        guard let url = Bundle.main.url(forResource: "bridge-demo", withExtension: "html") else {
                            validationError = "브릿지 테스트 파일을 찾을 수 없습니다."
                            return
                        }
                        WaterDebugLogger.event("브릿지 테스트 페이지 열기")
                        destinations.append(url)
                    }
                    Button("크래시 보고서", systemImage: "doc.text.magnifyingglass") {
                        showsReports = true
                    }
                    Button("샘플 이벤트 로그 기록", systemImage: "text.badge.plus") {
                        WaterDebugLogger.event("사용자가 샘플 이벤트 버튼을 선택했습니다.")
                    }
                }
                Section("사용 안내") {
                    Text("브릿지 채널: Bridge\n기본 API: routeApiList, nativeInfo\n앱 추가 API: appInfo")
                    Text("DEBUG 빌드에서는 오른쪽 아래 로그 버튼으로 WEBVIEW, BRIDGE, EVENT, CRASH 로그를 확인할 수 있습니다.")
                    Text("크래시 보고서는 다음 앱 실행에서 복구됩니다. 디버거가 연결된 동안에는 크래시 수집이 비활성화됩니다.")
                }.font(.footnote)
            }
            .navigationTitle("WaterBridge 예제")
            .navigationDestination(for: URL.self) { url in
                BrowserView(url: url)
            }
            .sheet(isPresented: $showsReports) { CrashReportsView() }
            .waterDebugConsole()
        }
    }

    private func openAddress() {
        let value = address.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = value.contains("://") ? value : "https://" + value
        guard !value.isEmpty,
              let url = URL(string: normalized),
              let scheme = url.scheme?.lowercased(),
              ["https", "http"].contains(scheme),
              let host = url.host, !host.isEmpty,
              url.user == nil, url.password == nil,
              !value.contains(where: { $0.isWhitespace }) else {
            validationError = "올바른 HTTP 또는 HTTPS URL을 입력하세요."
            return
        }
        validationError = nil
        address = normalized
        WaterDebugLogger.event("URL 입력 화면에서 웹뷰로 이동")
        destinations.append(url)
    }
}

private struct BrowserView: View {
    let url: URL
    @State private var reloadID = UUID()

    private var configuration: WaterBridgeConfiguration {
        WaterBridgeConfiguration(additionalRoutes: [
            WaterBridgeRoute(api: "water://appInfo", version: 1) { message in
                WaterBridgeResponse.success(data: [
                    "appName": "WaterBridgeExample",
                    "version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
                    "requestData": message.data as? [String: Any] ?? [:]
                ]).value
            }
        ])
    }

    var body: some View {
        WaterWebView(url: url, configuration: configuration)
            .id(reloadID)
            .navigationTitle(url.isFileURL ? "브릿지 테스트" : (url.host ?? "웹뷰"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("새로고침", systemImage: "arrow.clockwise") {
                    WaterDebugLogger.event("웹뷰 새로고침")
                    reloadID = UUID()
                }
            }
    }
}
