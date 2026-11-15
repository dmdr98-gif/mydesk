<!-- SPDX-License-Identifier: AGPL-3.0-only -->
# everywhere 브랜딩 예외

제품명은 항상 소문자 `everywhere`, 조직은 `com.everywhere`, Android applicationId는
`com.everywhere.app`이다. 아래 예외는 호환 식별자·원출처·법적 고지를 보존하기 위한 것이다.
단순 검색 결과를 0으로 만들기 위해 이 이름들을 일괄 치환하지 않는다.

| 유지 항목 / 위치 | 이유 |
| --- | --- |
| `Cargo.toml`: package/default-run `rustdesk`, lib `librustdesk`; `libs/portable/Cargo.toml`: `rustdesk-portable-packer` | Cargo 타깃·링크·브리지 ABI 유지. 빌드 내부 `target/release/rustdesk.exe`, `target/release/rustdesk-portable-packer.exe`를 제품명으로 복사/이동한다. |
| `librustdesk.dll`, `librustdesk.so`, Android `librustdesk.so`, C ABI의 `rustdesk_*`, `get_rustdesk_app_name`, 생성 브리지의 타입명 | Dart 동적 로더·C++ GetProcAddress·JNI 연결 유지. Windows CMake project명과 내부 변수/헤더 가드도 유지한다. |
| `flutter/android/app/build.gradle` namespace 및 `src/{main,debug,profile}/AndroidManifest.xml` package `com.carriez.flutter_hbb`; `src/main/kotlin/com/carriez/flutter_hbb/`, `ffi.FFI`, Rust의 기존 JNI 심볼 | Kotlin 클래스·JNI 경로를 바꾸지 않는다. 설치 식별자만 별도 applicationId를 사용한다. FileProvider 선언/하드코딩된 authorities는 앱 소스에 없으며 권한 설정 URI는 `context.packageName`을 사용한다. |
| `org.rustdesk.rustdesk/host`, `/side_buttons`, `rustdeskLocalFonts`, 클래스·함수·타입·옵션 키 이름 | Flutter 플랫폼 채널 및 기존 JS/네이티브·설정 인터페이스 유지. |
| `src/lang/*.rs`의 키와 번역 원문, Flutter/Kotlin의 `translate(...)` 키 | 기존 `src/lang.rs`가 표시 직전 앱 이름으로 치환한다. Web도 `flutter/lib/web/bridge.dart`에서 치환한다. 번역 파일과 특히 `it.rs`는 변경하지 않는다. |
| 번역 키 `powered_by_me`, `upgrade_rustdesk_server_pro*` | 업스트림 엔진 출처와 별도 서버 제품을 뜻한다. 해당 문자열은 원래 출처를 유지한다. |
| `RuntimeBroker_rustdesk.exe`, `RustDeskPrivacyWindowClass`, `RustDeskPrivacyWindow`, `rustdesk_idd`, `RustDeskIddDriver`, `RustDeskPrinterDriver`, `RustDesk v4 Printer Driver` | 외부 주입 DLL·드라이버·장치 탐색과 동기화된 이름이다. 서비스/제품 표시명이 아니다. MSI의 `Components/RustDesk.wxs` 파일명도 유지한다. |
| `libs/portable/{generate.py,src/bin_reader.rs}`의 `rustdesk` 매직; `src/update_metadata.rs`의 서명 컨텍스트; `rustdesk-verified-` 접두사와 `RUSTDESK_APPNAME` 전달 변수 | 포터블 컨테이너·검증된 업데이트 형식 호환성. 제품 산출물/실행 파일명은 everywhere를 사용한다. |
| `/@rustdesk/` 문서 가상 경로, `RustDesk://FsJob//Printer/`, `.rustdesk-*` 임시 이름, `rustdesk:wakelock` | 파일 전송·프린터·임시 파일·OS 진단의 내부 식별자. 문서 로그 정리는 이전 접두사도 인식한다. |
| `src/platform/windows.rs`의 비공개 커스텀 클라이언트 staging/Sciter 추출 경로, `test_rustdesk.log`, 테스트 fixture 및 진단의 내부 함수명 | 기존 경로·도구 호환성 유지. 설치 폴더·서비스·설정 폴더와 구분한다. |
| Cargo authors, 기존 Copyright/Purslane Tech Pte. Ltd., `LICENCE`, `res/msi/Package/License.rtf`, `WixExt_en-us.wxl`의 출처 고지 | 원 저작권/법적 고지를 삭제하거나 everywhere 소유로 바꾸지 않는다. everywhere MSI 전처리에서 기존 RTF를 그대로 보존한다. |
| `rustdesk.com`, GitHub upstream URL, 의존성·서버·업데이트 주소와 관련 검증/테스트 | 실제 업스트림 목적지를 제품명으로 치환하면 잘못된 주소가 된다. UI의 `rustdesk.com` 링크 및 상용 서버 안내도 여기에 포함한다. 자체 목적지/업데이트 정책은 P1-02/P1-03에서 확정한다. |
| README의 명시된 업스트림 본문, `docs/README-*`, 기존 플랫폼 패키지·수동 upstream 워크플로·주석 | 출처/과거 빌드 절차 보존. README 상단의 포크 소개와 제품 CI는 everywhere를 사용한다. 저장소 이름/URL 및 `README-mydesk.md` 파일명은 그대로다. |

Windows 서비스 등록·서비스 제어, 설치 폴더/바로가기/레지스트리/방화벽, 트레이 mutex
`Local\everywhere_tray`, IPC `\\.\pipe\everywhere\query*` 및 `%AppData%\everywhere\config`는
`APP_NAME`/`get_app_name()`에서 파생된다. WiX도 `$(var.Product)`를 사용한다.
창 클래스는 C++과 Rust 양쪽에서 `EVERYWHERE_FLUTTER_RUNNER_WIN32_WINDOW`로 일치시켰다.

MSI UpgradeCode는 기존 UUIDv5 규칙으로 새 제품명에서 생성하며
`bbb0fb2c-8895-551d-b50e-bfb2e12bc75e`이다. 업스트림의
`d3dc41e3-3c37-5d52-bb47-f6673705c01b`와 달라 독립 제품으로 설치된다.

아이콘 원본은 자체 작성한 임시 픽셀 e 도안 `branding/mark.json`이다.
`bash scripts/gen-branding.sh`는 Python 표준 라이브러리만 사용하며 PNG/ICO에 SPDX 메타데이터를 넣는다.
MSI Resources 사본은 기존 ignore 규칙대로 빌드 시 생성한다. 배포 전 정식 도안 확정은 TODO다.

남은 비대상 플랫폼 표시명은 별도 작업이 필요하다: `flutter/{linux,macos,ios}`의 패키지/러너,
`Cargo.toml`의 macOS bundle 메타데이터, `src/server/wayland.rs`의 직접 오류 문구,
`src/clipboard.rs`의 KDE 임시 클립보드 문구, 기존 Linux/macOS 리소스·설치 스크립트.
이 파일들의 제품 패키징까지 everywhere로 전환했다고 주장하지 않는다.
