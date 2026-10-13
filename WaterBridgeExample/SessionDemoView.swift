import SwiftUI
import WaterBridgeKit
import WebKit

struct SessionDemoView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var domain = "example.com"
    @State private var cookieName = "water_session"
    @State private var webAddress = "https://example.com"
    @State private var apiAddress = "https://example.com"
    @State private var synchronizer: WaterSessionSynchronizer?
    @State private var demoSynchronizer: WaterSessionSynchronizer?
    @State private var demoNativeCount = 0
    @State private var demoWebCount = 0
    @State private var destinations: [URL] = []
    @State private var nativeCount = 0
    @State private var webCount = 0
    @State private var message = "서버의 도메인과 로그인 쿠키 이름을 지정하세요."
    @State private var isBusy = false

    var body: some View {
        NavigationStack(path: $destinations) {
            Form {
                Section("세션 공유 설정") {
                    TextField("로그인 도메인", text: $domain)
                    TextField("로그인 쿠키 이름", text: $cookieName)
                    Text("예: example.com / JSESSIONID. 선택한 이름과 도메인의 쿠키만 공유합니다. 서버가 CSRF 쿠키도 필요로 하면 라이브러리 설정에 이름을 함께 추가하세요.")
                        .font(.footnote).foregroundStyle(.secondary)
                    Button("동기화 시작") { perform { try await start() } }
                }
                .disabled(isBusy || synchronizer != nil)
                Section("로그인 서버 연결") {
                    TextField("웹 로그인 URL", text: $webAddress)
                    Button("웹 로그인 페이지 열기") {
                        do { destinations.append(try validatedURL(webAddress)) }
                        catch { message = error.localizedDescription }
                    }
                    TextField("세션 확인 API URL", text: $apiAddress)
                    Button("앱 API 요청으로 세션 확인") {
                        perform {
                            guard let synchronizer else { return }
                            let url = try validatedURL(apiAddress)
                            let (_, response) = try await synchronizer.makeTransport().data(for: URLRequest(url: url))
                            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                            await updateCounts()
                            message = "앱 API 응답: HTTP \(status). 로그인 유효성은 서버 응답으로 확인하세요."
                        }
                    }
                    Button("로컬 세션 삭제", role: .destructive) {
                        perform {
                            await synchronizer?.clearSession()
                            await updateCounts()
                            message = "앱·웹의 지정된 쿠키를 삭제했습니다. 서버 세션 만료는 별도 로그아웃 API를 호출해야 합니다."
                        }
                    }
                }.disabled(synchronizer == nil || isBusy)
                Section("쿠키 동기화 테스트") {
                    Text("별도의 메모리 저장소에서 데모 쿠키로 양방향 동기화를 확인합니다.")
                        .font(.footnote).foregroundStyle(.secondary)
                    Button("앱 쿠키 변경 → 웹으로 공유") {
                        perform {
                            let demo = try await prepareDemo()
                            try await demo.setCookiesFromNative([makeDemoCookie(value: "demo-native")])
                            await updateDemoCounts()
                            message = "데모 앱 쿠키를 웹에 반영했습니다."
                        }
                    }
                    Button("웹 쿠키 변경 → 앱으로 공유") {
                        perform {
                            let demo = try await prepareDemo()
                            await demo.websiteDataStore.httpCookieStore.setCookie(try makeDemoCookie(value: "demo-web"))
                            await demo.synchronizeFromWeb()
                            await updateDemoCounts()
                            message = "데모 웹 쿠키를 앱에 반영했습니다."
                        }
                    }
                    Button("데모 세션 삭제", role: .destructive) {
                        perform {
                            await demoSynchronizer?.clearSession()
                            await updateDemoCounts()
                            message = "데모 앱·웹 쿠키를 삭제했습니다."
                        }
                    }
                    LabeledContent("데모 앱 쿠키", value: "\(demoNativeCount)개")
                    LabeledContent("데모 웹 쿠키", value: "\(demoWebCount)개")
                }.disabled(isBusy)
                Section("동기화 상태") {
                    LabeledContent("앱 쿠키", value: "\(nativeCount)개")
                    LabeledContent("웹 쿠키", value: "\(webCount)개")
                    Text(message).font(.footnote)
                    Button("동기화 및 상태 갱신") { perform { await updateCounts() } }
                        .disabled(synchronizer == nil || isBusy)
                    Text("쿠키 값은 화면과 로그에 표시하지 않습니다. 쿠키 개수만으로 로그인 성공 여부를 판단하지 않습니다.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .navigationTitle("세션 동기화")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("닫기") { dismiss() }.disabled(isBusy) }
            }
            .navigationDestination(for: URL.self) { url in
                BrowserView(url: url, sessionSynchronizer: synchronizer)
            }
            .onChange(of: destinations) { _, path in
                if path.isEmpty { perform { await updateCounts() } }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active, synchronizer != nil { perform { await updateCounts() } }
            }
        }
        .onDisappear {
            let session = synchronizer
            let demo = demoSynchronizer
            Task {
                await session?.stopObserving()
                await demo?.stopObserving()
            }
        }
    }

    private func start() async throws {
        let newSynchronizer = try WaterSessionSynchronizer(
            allowedDomains: [domain.trimmingCharacters(in: .whitespacesAndNewlines)],
            cookieNames: [cookieName.trimmingCharacters(in: .whitespacesAndNewlines)]
        )
        await newSynchronizer.start()
        synchronizer = newSynchronizer
        await updateCounts()
        message = "동기화를 시작했습니다. 웹 로그인 또는 앱 API 요청을 진행하세요."
    }

    private func updateCounts() async {
        guard let synchronizer else { return }
        await synchronizer.synchronizeFromWeb()
        let counts = await synchronizer.cookieCounts()
        nativeCount = counts.native
        webCount = counts.web
    }

    private func prepareDemo() async throws -> WaterSessionSynchronizer {
        if let demoSynchronizer { return demoSynchronizer }
        let demo = try WaterSessionSynchronizer(
            allowedDomains: ["example.com"], cookieNames: ["waterbridge_demo_session"],
            websiteDataStore: .nonPersistent()
        )
        await demo.start()
        demoSynchronizer = demo
        return demo
    }

    private func updateDemoCounts() async {
        guard let demoSynchronizer else { return }
        let counts = await demoSynchronizer.cookieCounts()
        demoNativeCount = counts.native
        demoWebCount = counts.web
    }

    private func makeDemoCookie(value: String) throws -> HTTPCookie {
        guard let cookie = HTTPCookie(properties: [
            .domain: "example.com",
            .path: "/", .name: "waterbridge_demo_session",
            .value: value, .secure: "TRUE", .expires: Date().addingTimeInterval(3600),
            HTTPCookiePropertyKey("HttpOnly"): "TRUE"
        ]) else { throw DemoError.invalidCookie }
        return cookie
    }

    private func validatedURL(_ address: String) throws -> URL {
        guard let url = URL(string: address), url.scheme?.lowercased() == "https",
              let host = url.host?.lowercased(),
              url.user == nil, url.password == nil else { throw DemoError.invalidURL }
        let configured = domain.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ". "))
        guard host == configured || host.hasSuffix("." + configured) else { throw DemoError.invalidURL }
        return url
    }

    private func perform(_ action: @escaping @MainActor () async throws -> Void) {
        guard !isBusy else { return }
        isBusy = true
        Task {
            defer { isBusy = false }
            do { try await action() }
            catch { message = error.localizedDescription }
        }
    }

    private enum DemoError: LocalizedError {
        case invalidURL, invalidCookie
        var errorDescription: String? {
            switch self {
            case .invalidURL: "설정한 도메인에 속하는 HTTPS URL을 입력하세요."
            case .invalidCookie: "쿠키 설정을 확인해 주세요."
            }
        }
    }
}
