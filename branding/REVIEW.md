<!-- SPDX-License-Identifier: AGPL-3.0-only -->
# E1 everywhere 작업 기록

제품 표시명은 `everywhere`, 조직은 `com.everywhere`, Android 설치 ID는
`com.everywhere.app`이다. 저장소 이름은 유지한다. 커밋·push·코드 생성기는 실행하지 않았다.
서브모듈 gitlink는 기존 커밋 그대로이며 내부 `src/config.rs`의 기본값 두 줄만 수정했다.

변경 파일과 회귀 영향 범위를 최종 diff 기준으로 점검했다. 아래의 각 기존 코드 경로 변경은
제품 이름·패키지·아이콘을 일치시키기 위해 필요하며, 원격 연결/입력/코덱 로직은 바꾸지 않았다.

| 변경 파일 (저장소 상대 경로) | 동작 변화와 필요한 이유 |
| --- | --- |
| `libs/hbb_common/src/config.rs` | 기본 앱 이름/조직 변경. 이름에서 파생되는 설정·로그·IPC·서비스 경로가 별도 제품 공간을 사용한다. 기존 설정의 자동 이전은 추가하지 않았다. |
| `Cargo.toml`, `libs/portable/Cargo.toml` | Windows 파일 속성과 패키지 설명을 변경하고 원저작권을 보존한다. 내부 crate/lib/packer 타깃 이름은 유지한다. |
| `flutter/windows/CMakeLists.txt`, `runner/{Runner.rc,main.cpp,win32_window.cpp,service_control.h}` | 실행 파일명, 메타데이터, 창 제목 기본값/클래스와 서비스 오류 문구 변경. 창 검색과 단일 인스턴스 경로의 클래스가 같아야 한다. |
| `src/platform/windows.rs` | C++과 같은 창 클래스명, 메시지 상자 제목/서비스 오류 문구. 서비스 제어 로직 자체는 유지한다. |
| `build.py`, `.github/workflows/windows-build.yml` | Flutter 및 기존 Sciter Windows 산출물, 배포 폴더, 패킹 시작 파일, MSI 입력/출력, CI 아티팩트 이름 변경. 내부 Cargo 산출물을 제품 이름으로 복사/이동한다. |
| `res/msi/preprocess.py`, `res/msi/Package/Language/Package.en-us.wxl` | 제품명·제조사·기본 배포 폴더 및 로컬라이즈된 설치 문구 변경. 기존 Product 변수에서 서비스/설치 폴더/바로가기가 파생된다. 새 이름으로 별도 UpgradeCode를 생성하며 원 RTF는 변경하지 않는다. |
| `flutter/android/app/build.gradle`, `src/main/AndroidManifest.xml` | applicationId, 앱/접근성 label, 딥링크, 디버그 부팅 action 변경. namespace/Kotlin/JNI는 유지한다. |
| `flutter/android/app/src/main/kotlin/com/carriez/flutter_hbb/{BootReceiver,MainService,DocumentLogs}.kt` | 부팅 action을 실제 packageName과 맞추고 알림·가상 화면·토스트·내보낸 로그 이름을 변경한다. 로그 정리 regex는 이전 접두사도 인식한다. |
| `flutter/android/app/src/main/res/values/{strings,ic_launcher_background}.xml`, `drawable/floating_window.xml`, `mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/{ic_launcher,ic_launcher_foreground,ic_launcher_round,ic_stat_logo}.png` | 사용자 표시 문구, 런처/적응형/알림/플로팅 아이콘 교체. PNG 20개를 포함한다. |
| `flutter/lib/desktop/widgets/tabbar_widget.dart`, `flutter/lib/web/bridge.dart`, `flutter/pubspec.yaml` | 고정 탭 제목을 앱 이름으로 대체하고 Web 기본 이름·표시 직전 번역 치환을 맞춘다. 패키지 설명에도 포크 출처를 명시한다. |
| `libs/portable/generate.py`, `libs/portable/src/main.rs` | 기본 입력 폴더/시작 실행 파일/추출 폴더 fallback 변경. 컨테이너 형식은 보존한다. |
| `src/auth_2fa.rs`, `src/whiteboard/{windows,linux,macos}.rs` | 인증 앱 등록에 표시하는 issuer와 화이트보드 창 제목 변경. 인증 비밀값이나 OTP 계산은 바꾸지 않는다. |
| `res/{icon.ico,tray-icon.ico,icon.png,logo.svg,logo-header.svg}`, `flutter/windows/runner/resources/app_icon.ico`, `flutter/assets/{icon.svg,icon.png}` | 자체 임시 e 도안으로 표시 리소스를 생성한다. `flutter/assets/icon.png`는 신규 파일이다. |
| `README.md`, `NOTICE.md`, `UPSTREAM.md`, `.github/workflows/README-mydesk.md` | everywhere 소개·독립 포크/AGPL 고지·CI 설명 갱신. 원출처 본문과 저작권은 보존한다. |
| `.gitignore`, 신규 `scripts/gen-branding.sh`, `branding/{mark.json,ALLOWLIST.md,REVIEW.md}` | 새 Flutter PNG를 추적하고 원본 도안·재생성 절차·호환 예외·검증 기록을 제공한다. 기존 MSI Resources 사본은 빌드 시 생성하는 ignore 대상이다. |

Windows 배포 이름은 `everywhere.exe`, `everywhere-1.5.3-x86_64.exe`,
`everywhere-1.5.3-x86_64.msi`이며 버전은 빌드 입력을 따른다.
MSI의 새 UpgradeCode는 `bbb0fb2c-8895-551d-b50e-bfb2e12bc75e`다.

검증 결과:

- `cargo check -p hbb_common`: 통과.
- `cargo test -p hbb_common -- --skip socket_client::tests::test_test_if_valid_server`:
  단위 106개 및 통합 8개 통과, 문서 예제 2개는 기존 ignore. 테스트 설정 폴더를 임시 위치로 지정했다.
- `XDG_CONFIG_HOME="$(mktemp -d /tmp/everywhere-linux-config.XXXXXX)" bash scripts/check-linux.sh`:
  종료 코드 0. 기본 홈 경로로 실행하면 샌드박스 쓰기 제한으로 설정 저장 테스트가 실패하므로
  설정 환경변수만 테스트용 임시 경로로 지정했다. 제품 코드/테스트를 우회 수정하지 않았다.
- 전체 Linux Flutter 컴파일은 개발 패키지 부족, `flutter analyze`는 SDK 부재로 SKIP.
  따라서 전체 Rust 앱·Dart·Windows·Android 컴파일 완료를 의미하지 않는다.
- `actionlint .github/workflows/windows-build.yml`, Python 3개 파일 구문 검사,
  `bash -n scripts/gen-branding.sh`, 부모/서브모듈 `git diff --check`: 통과.
- MSI 전체 전처리를 임시 배포 fixture로 실행했다. 이름·제조사·UpgradeCode·서비스/폴더/바로가기 변수,
  XML 파싱 및 기존 라이선스 바이트 보존을 확인했다. 실제 WiX/MSBuild는 실행하지 않았다.
- 포터블 컨테이너를 실제 생성해 시작 파일/기존 매직을 확인했다. Windows 빌드 함수의
  명령/이동 경로를 모의 실행해 x86_64 산출물 이름을 확인했다. 실제 Windows 바이너리는 빌드하지 않았다.
- 아이콘 생성 스크립트를 실제 실행했다. 이미지 산출물 28개를 디코딩하고 ICO 7개 해상도 및
  재실행 시 동일 해시를 확인했다. 기본 PNG도 육안 확인했다.

브랜딩 검색은 전체 소스 4,121줄에서 4,070줄로 감소했다.
전체 저장소의 사용자 노출 잔여 0건은 달성하지 않았다. 허용한 업스트림 고지·링크·서버 제품 표기,
호환 식별자 및 미전환 Linux/macOS/iOS 경로는 [ALLOWLIST.md](ALLOWLIST.md)에 목록화했다.

실기 확인/TODO:

- Windows CI에서 실제 EXE/MSI 빌드, 파일 속성·아이콘·소문자 창 제목·트레이·단일 인스턴스 확인.
  설치/수리/업그레이드/제거 후 `Program Files\everywhere`, `%AppData%\everywhere`, 서비스
  `everywhere`, 바로가기·방화벽·부팅 자동실행을 확인한다. 기존 업스트림 설치와의 분리도 확인한다.
- Android APK의 설치 ID와 Kotlin 클래스 경로, 병합 manifest의 타사 provider authorities,
  JNI 초기화, 접근성 안내·알림·플로팅 아이콘, 재부팅/디버그 action, `everywhere://` 연결을 확인한다.
  기존 앱과 별개로 설치되며 앱 데이터/권한을 자동 이전하지 않는다. 새 로그 이름/정리도 확인한다.
- Web TS/JS 코어는 저장소에 없으므로 maintainer 트리와 연결해서 브리지 표시명을 실기 확인한다.
- P1-02/P1-03에서 자체 서버/소스 제공/웹사이트/업데이트 목적지 및 개인정보 고지를 확정한다.
  정식 로고, 서명, 비대상 플랫폼 패키징은 후속 작업이다.
