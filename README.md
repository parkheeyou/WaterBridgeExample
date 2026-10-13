# WaterBridgeExample

WaterBridgeKit README의 사용법을 적용한 iOS 17+ SwiftUI 예제입니다.

## 실행

1. `WaterBridgeExample.xcodeproj`를 Xcode 16 이상(Swift 6.1 이상)에서 엽니다.
2. Swift Package 의존성 다운로드가 완료될 때까지 기다립니다.
3. `WaterBridgeExample` scheme과 iOS 시뮬레이터를 선택해 실행합니다.
4. 실기기는 Signing & Capabilities에서 본인의 Development Team을 선택합니다.

WaterBridgeKit은 프로젝트 내부의 `Packages/WaterBridgeKit`에 Swift Package로 포함되어 있습니다. Xcode는 이 내부 패키지를 참조하므로 예제 프로젝트 폴더만으로 사용할 수 있습니다. 패키지의 TCA 및 PLCrashReporter 의존성은 최초 실행 시 내려받습니다.

포함된 패키지는 원본 라이브러리의 복사본입니다. 원본 변경 사항은 자동 반영되지 않으며, 라이브러리 수정은 `Packages/WaterBridgeKit` 내부에서 진행하거나 원본에서 변경 사항을 가져와야 합니다.

## 확인할 기능

- URL 입력 → WaterWebView: HTTP/HTTPS URL을 검증하고 스킴 생략 시 HTTPS를 붙입니다. 웹뷰의 뒤로 스와이프와 앱 화면의 뒤로 이동, 초기 URL 새로고침을 사용할 수 있습니다.
- 브릿지 테스트 페이지: 앱에 포함한 HTML에서 `window.webkit.messageHandlers.Bridge.postMessage`를 호출합니다. `routeApiList`, `nativeInfo`, 커스텀 `appInfo`, 미지원 API 응답을 확인합니다. `appInfo`는 요청의 data를 응답의 requestData에 돌려줍니다.
- 로그: DEBUG에서 홈 및 웹뷰 오른쪽 아래 로그 콘솔을 제공합니다. 홈의 샘플 이벤트 버튼은 EVENT 로그를 기록합니다. 웹뷰 및 브릿지 로그는 라이브러리가 자동 수집합니다. Release에서는 콘솔과 로그 수집이 비활성화됩니다.
- 크래시: 앱 진입점에서 수집기를 시작합니다. 다음 실행에서 복구된 `.crash.log`를 목록으로 조회하고 본문 확인, 공유, 전체 삭제할 수 있습니다. 기본 최근 10개를 보관합니다.

실제 크래시 수집은 디버거를 해제한 뒤 앱을 실행하여 확인하세요. 앱에 강제 크래시 버튼은 포함하지 않았습니다. 보고서가 없으면 빈 상태 화면이 표시됩니다.

HTTP 개발 페이지도 열 수 있도록 웹 콘텐츠에 한정한 ATS 예외(`NSAllowsArbitraryLoadsInWebContent`)를 설정했습니다. 배포 앱에서는 대상 서버의 HTTPS 정책에 맞춰 조정하세요.

`WaterWebView`는 최초 생성 시 URL을 로드하므로 새로고침은 뷰 식별자를 바꿔 웹뷰를 다시 생성합니다. 로컬 HTML 테스트는 인터넷 없이 열리지만 패키지 최초 설치 및 외부 URL 로딩에는 네트워크가 필요합니다.

## 권한 요청 예제

홈의 권한 요청 예제에서 카메라, 마이크, 앱 사용 중 위치, 사진 라이브러리 권한을 요청할 수 있습니다. 최초 요청은 시스템 권한 창을 표시하고, 거부한 권한은 앱의 설정 이동 안내를 표시합니다. 설정에서 복귀하면 상태가 갱신됩니다. 사진의 제한된 접근은 허용 상태로 취급하며, 기기 관리 제한과 전역 위치 서비스 꺼짐은 별도로 안내합니다.

라이브러리 API와 사용 목적 설정은 `Packages/WaterBridgeKit/README.md`의 iOS 권한 섹션을 참고하세요. 실제 카메라·마이크 기능이나 위치 수집은 수행하지 않고 권한만 요청합니다. 실기기에서 시스템 창, 거부 후 설정 이동, 설정 변경 후 상태 갱신을 확인하세요.
