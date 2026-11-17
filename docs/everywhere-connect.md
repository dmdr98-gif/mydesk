<!-- SPDX-License-Identifier: AGPL-3.0-only -->
# everywhere 연결 안내

everywhere의 자체 hbbs/hbbr 서버는 아직 배포되지 않았습니다. 서버 주소를
내장하지 않은 빌드는 **서버 미설정** 상태로 시작합니다. 이 상태에서는 ID로
상대를 찾을 수 없지만, 같은 LAN에서 직접 IP로 접속할 수 있습니다.
설정의 **ID/릴레이 서버** 메뉴는 계속 사용할 수 있습니다.

서버 없이 시작하려면 [Windows PC·Android 실기 확인표](serverless-testing.ko.md)를
따릅니다. 현재 제품 빌드 대상은 Windows x64와 Android arm64입니다. Linux/macOS의
권한·Wayland 관련 업스트림 코드는 남아 있지만 everywhere 배포와 실기는 확인하지
않았습니다. 해당 플랫폼의 안내 링크도 이 문서로 연결하며 지원 완료를 뜻하지 않습니다.

## 자체 서버 설정

접속하는 Android와 접속을 받는 Windows에 같은 서버 정보를 입력합니다.

1. Windows에서는 **설정 → 네트워크 → ID/릴레이 서버**, Android에서는
   **설정 → ID/릴레이 서버**를 엽니다.
2. 서버 운영자에게 받은 값을 입력하고 저장합니다.

| 항목 | 입력할 값 | 예시 |
| --- | --- | --- |
| ID 서버 | hbbs의 호스트 또는 호스트:포트. 기본 TCP/UDP 포트는 21116 | `id.example.net:21116` |
| 릴레이 서버 | hbbr의 호스트 또는 호스트:포트. 기본 TCP 포트는 21117 | `relay.example.net:21117` |
| Key | 해당 hbbs의 `id_ed25519.pub` 내용인 공개키 | 운영자가 제공한 공개키 전체 |
| API 서버 | 별도로 운영하는 계정/주소록 API의 URL | `https://api.example.net` |

예시 도메인은 실제 서버가 아닙니다. 개인키 파일 `id_ed25519`는 클라이언트에
입력하지 않습니다. 기본 포트라면 호스트만 입력해도 됩니다. 릴레이 서버를
비워 두면 hbbs가 전달하는 릴레이 정보를 사용합니다.

hbbs/hbbr만으로는 계정·주소록 API가 제공되지 않습니다. API 서버가 없으면
해당 칸을 비워 두고 ID 접속을 사용합니다. 사용자 지정 ID 서버에 API 주소가
없으면 기존 클라이언트 동작에 따라 `http://<ID 서버>:21114`를 추론할 수
있으며, 이 주소에 API가 없다면 계정 기능은 동작하지 않습니다.

설정 후 두 기기에서 연결 상태를 확인하고, Android의 상대 ID 입력란에
Windows에 표시된 ID를 넣습니다. Windows에서 요청을 승인하거나 Windows에
설정한 비밀번호를 입력합니다. 인터넷을 통해 사용하려면 운영자가 hbbs/hbbr의
필요한 포트와 방화벽을 구성해야 합니다.

## 서버 없이 같은 LAN에서 직접 IP 접속

1. Windows와 Android를 서로 통신 가능한 같은 LAN/Wi-Fi에 연결합니다.
2. Windows everywhere의 **설정 → 보안 → 직접 IP 접속 허용**을 켭니다.
   현재 한국어 UI에서는 **직접 IP 액세스 허용**으로 표시됩니다. 서비스도
   실행 중이어야 합니다. 기본 직접 접속 포트는 **TCP 21118**입니다.
3. Windows의 LAN IPv4 주소를 확인합니다. 예를 들어 `ipconfig`의 Wi-Fi 또는
   이더넷 어댑터에서 `192.168.1.20` 같은 주소를 확인합니다.
4. Windows 방화벽에서 everywhere의 개인 네트워크 수신 또는 TCP 21118을
   허용합니다. 게스트 Wi-Fi의 기기 격리가 켜져 있으면 서로 접속할 수 없습니다.
5. Android의 상대 ID 입력란에 `192.168.1.20` 또는
   `192.168.1.20:21118`을 입력하고 연결합니다. 포트를 변경했다면 그 포트를
   지정합니다. Windows에서 승인하거나 접속 비밀번호를 입력합니다.

직접 IP 접속은 ID 등록이나 랑데부 서버 없이 동작합니다. 따라서 상태가
**서버 미설정**이어도 사용할 수 있습니다. 여기의 21118은 Windows 앱의
직접 IP 리스너이며 hbbs 서버의 WebSocket 포트와는 별개의 용도입니다.

## 빌드에 서버 기본값 넣기

Windows 및 Android 제품 CI는 GitHub Actions Variables를 먼저, 같은 이름의
Secrets를 다음으로 확인합니다. 둘 다 없으면 빈 값으로 빌드합니다.

| 이름 | 용도 |
| --- | --- |
| `EVERYWHERE_RENDEZVOUS` | 기본 hbbs 주소. 여러 주소는 쉼표로 구분하며 빈 항목은 무시 |
| `EVERYWHERE_PUBKEY` | 기본 hbbs 공개키 |
| `EVERYWHERE_API` | 기본 API URL |

Rust의 `option_env!`로 컴파일할 때 읽으므로 변경 후에는 다시 빌드해야 합니다.
앱 설정에서 입력한 서버 정보는 기존 우선순위대로 빌드 기본값보다 우선합니다.
서버·공개키를 주입하지 않으면 기본 서버 목록과 공개키는 비어 있으며,
API URL도 RustDesk 공개 API로 대체하지 않습니다.

Android 워크플로는 `everywhere-android-arm64` 아티팩트에
`everywhere-<VERSION>-aarch64.apk`를 14일 보관합니다. `ANDROID_SIGNING_KEY`
(keystore의 Base64), `ANDROID_ALIAS`, `ANDROID_KEY_STORE_PASSWORD`,
`ANDROID_KEY_PASSWORD` Secrets를 모두 제공하면 해당 키로 서명합니다.
키가 없으면 CI의 디버그 키로 서명한 release APK를 생성합니다. 업로드 전에
APK 서명, `com.everywhere.app` applicationId, arm64 ABI와 Rust 라이브러리를
검사합니다. 서명 검사는 Android SDK의
[apksigner](https://developer.android.com/tools/apksigner)를 사용합니다.

디버그 키는 CI 실행마다 달라질 수 있으므로 테스트 APK의 덮어쓰기 설치가
실패할 수 있습니다. 이 경우 기존 앱을 삭제하면 로컬 설정도 사라집니다.
업데이트를 유지할 배포에는 고정된 자체 서명키를 사용해야 합니다.
서명키 파일은 저장소나 아티팩트에 포함하지 않습니다.

## RustDesk 공개 서버를 기본으로 쓰지 않는 이유

`rs-ny.rustdesk.com`은 everywhere 운영 서버가 아니라 RustDesk의 공개 데모
서버입니다. 프로젝트의 현재 전제상 2026년부터 제어측의 RustDesk 계정 로그인이
필요하므로, 자체 계정·서버를 사용할 포크가 이 인프라에 의존해서는 안 됩니다.
따라서 공개 데모 서버 주소·공개키와 `https://admin.rustdesk.com` API 주소를
기본값에서 제거했습니다. 자체 서버가 준비될 때까지는 운영자가 제공한 서버를
설정하거나 LAN 직접 IP 접속을 사용합니다.

## 업데이트·소스·정책 안내

자체 업데이트 서비스와 신뢰키가 준비될 때까지 앱의 자동/수동 온라인 업데이트
확인과 메타데이터 다운로드를 비활성화합니다. 기존 업데이트 옵션이 저장돼 있어도
RustDesk 버전 확인 API로 요청하지 않습니다. 새 버전 설치는 운영자가 제공한
everywhere 설치파일로 진행하며 Android 덮어쓰기에는 같은 서명키가 필요합니다.

앱의 소스·도움말·라이선스 링크는 [everywhere 저장소](https://github.com/dmdr98-gif/mydesk),
[AGPL-3.0](../LICENCE), [오픈소스 고지](../NOTICE.md)로 연결합니다. 제품 개인정보
처리방침과 운영 웹사이트는 아직 확정되지 않아 RustDesk 정책 페이지를 제품 정책으로
표시하지 않습니다. 정식 배포 전에 운영 정책을 확정해야 합니다.
