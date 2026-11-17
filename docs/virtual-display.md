<!-- SPDX-License-Identifier: AGPL-3.0-only -->
# everywhere 가상 디스플레이 현황

확인일: 2026-11-17 KST. 기준: 클라이언트 `b5d711a45`의 기존 구현. P4-01의 소스 조사를 정리한 문서이며, Windows 드라이버 설치·서명·실기 검증 결과는 아니다.

## 현재 지원 경로

기본 구현은 **Amyuni USB Mobile Monitor**다. `IDD_IMPL`은 `amyuni_idd`로 고정되어 있고, RustDesk IddDriver 경로도 소스에 남아 있다. 런타임에서 드라이버를 선택하는 설정은 없다. 지원 검사 기준은 Windows 10 build 19041 이상이다. 다른 OS에서는 지원 검사 결과가 false다. 근거: `src/virtual_display_manager.rs:9`, `is_virtual_display_supported:26`.

| 구현 | 설치·제어 경로 | 현재 제한 |
| --- | --- | --- |
| Amyuni | 앱 실행 폴더의 `usbmmidd_v2/usbmmIdd.inf`를 사용한다. `deviceinstaller64.exe`가 있으면 해당 도구, 그렇지 않으면 SetupAPI로 설치한다. 장치 IOCTL로 모니터를 추가·제거한다. | 최대 4개. 외부 프로그램이 같은 드라이버를 제어하면 앱의 추가 개수와 실제 장치 수가 다를 수 있다. |
| RustDesk IddDriver | `dylib_virtual_display.dll`을 동적으로 불러 장치 생성·드라이버 설치·모드 변경 함수를 호출한다. INF 경로는 `RustDeskIddDriver/RustDeskIddDriver.inf`다. | 기본 선택 경로가 아니다. 모니터 0은 headless용, 1~4는 원격 요청용이다. 기본 모드는 1920×1080/60Hz다. |

근거: `src/virtual_display_manager.rs:140`, `:158`, `:201`, `:258`, `:399`, `:423`, `:489`, `:535`, `:648`; `libs/virtual_display/src/lib.rs:31`, `:95`, `:136`; `libs/virtual_display/dylib/src/win10/mod.rs:4`.

## 권한과 배포 상태

가상 디스플레이 메뉴에 필요한 호스트 정보는 **Windows 서비스가 실행 중일 때만** 제공된다(`get_platform_additions`, `src/virtual_display_manager.rs:45`). 클라이언트 메뉴도 설치된 Windows 호스트인지 검사한다(`showVirtualDisplayMenu`, `flutter/lib/common/widgets/toolbar.dart:1464`). 드라이버 설치는 장치·SetupAPI 작업이므로 관리자 권한이 가능한 설치형 서비스 환경에서 확인해야 한다. 현재 메뉴만으로 권한 상승과 드라이버 설치 성공이 보장되지는 않는다.

제품용 `windows-build.yml`에는 Amyuni/RustDesk IddDriver 패키지를 다운로드·스테이징하는 단계가 없다. MSI 생성은 이미 준비된 `everywhere` 폴더를 입력으로 사용한다(`.github/workflows/windows-build.yml:200`, `:227`). 따라서 **현재 기본 MSI만 설치하면 가상 디스플레이 드라이버까지 설치된다고 간주하면 안 된다**.

RustDesk IddDriver의 `download_driver`는 실제 다운로드가 구현되지 않은 함수이고 다운로드 주소도 빈 값이다(`libs/virtual_display/dylib/src/lib.rs:26`, `libs/virtual_display/dylib/src/win10/mod.rs:5`). 기존 README가 가리키는 프로젝트는 `rustdesk-org/RustDeskIddDriver`다(`libs/virtual_display/dylib/README.md`). Amyuni는 INF·장치 이름으로 식별될 뿐, 이번 조사에서 배포 권한을 입증하는 라이선스는 확보하지 않았다. **두 드라이버 모두 사용할 정확한 버전·패키지 출처·서명·재배포 조건 확인이 필요**하다. StarDesk 패키지의 드라이버를 가져오지 않는다.

## 옵션과 UX 흐름

| 항목 | 의미·근거 |
| --- | --- |
| `IDD_IMPL` | 컴파일된 구현 선택 상수. 사용자 설정 옵션이 아님(`src/virtual_display_manager.rs:9`). |
| `idd_impl` | 호스트가 보내는 구현 식별자(`get_platform_additions:50`). |
| `amyuni_virtual_displays` | 호스트가 관측한 Amyuni 모니터 개수(`get_platform_additions:62`). |
| `rustdesk_virtual_displays` | RustDesk IddDriver의 원격용 모니터 인덱스 목록(`get_platform_additions:53`). |
| `ToggleVirtualDisplay` | 세션에서 추가·제거를 요청하는 메시지. 설정 파일의 영구 옵션이 아님(`src/ui_session_interface.rs:455`; `src/server/connection.rs:3915`). |
| `privacy-mode` | 프라이버시 모드가 켜진 동안 가상 모니터 메뉴 조작을 비활성화한다(`flutter/lib/common/widgets/toolbar.dart:1483`). |

데스크톱 화면 메뉴와 Android 원격 세션 메뉴가 같은 가상 디스플레이 컨트롤을 사용한다. Amyuni는 `− / 개수 / +`와 전체 제거를 제공하고, RustDesk IddDriver는 모니터별 토글과 전체 제거를 제공한다. 요청은 브리지 → `ToggleVirtualDisplay` → Windows 호스트 `toggle_virtual_display`로 전달된다. 실패하면 호스트가 메시지 상자로 응답한다. 근거: `flutter/lib/common/widgets/toolbar.dart:1477`; `flutter/lib/desktop/widgets/remote_toolbar.dart:1773`; `flutter/lib/mobile/pages/remote_page.dart:1505`; `src/server/connection.rs:4785`.

headless 자동 추가는 이미 존재한다. 설치된 지원 Windows에서 디스플레이가 없으면 `plug_in_headless`를 시도하며, Amyuni는 접속 시 필요한 경로에서만 실행한다(`src/server/display_service.rs:976`, `:982`). 마지막 원격 화면 연결 종료 시 해상도 복원과 `reset_all` 경로가 있다(`src/server/connection.rs:7093`). 실제 드라이버·세션 전환에 따른 제거 결과는 실기 확인이 필요하다.

## 알려진 제한과 다음 작업

- 기본 Amyuni는 정확한 모니터 소유권 추적이 어렵다. 마지막 하나뿐인 화면 제거를 거부할 수 있으며, 강제 전체 정리 시 다른 프로그램이 만든 화면에도 영향을 줄 수 있다(`src/virtual_display_manager.rs:414`, `:666`).
- RustDesk IddDriver의 모드 변경은 현재 60Hz 값을 사용한다(`change_resolution:353`). 120/144Hz를 지원하는 제품 프리셋과 GPU·드라이버별 보장은 아직 없다.
- headless 자동 추가 코드는 존재하므로 P4-02는 재구현보다 **드라이버 배포·실패 안내·해상도/주사율 UX·생명주기 검증**부터 진행한다.
- 서버는 필요하지 않지만 설치형 Windows 호스트와 별도 컨트롤러, 승인된 드라이버가 필요하다. 연결 방법은 [직접 IP 연결 안내](everywhere-connect.md#서버-없이-같은-lan에서-직접-ip-접속)를 따른다.

## Steven님 실기 확인표

| 확인 | 기대 결과 |
| --- | --- |
| Windows 10/11 설치형 서비스 실행, 드라이버 미설치 | 앱이 종료되지 않고 실패 이유를 안내한다. |
| 승인된 드라이버 설치·장치 관리자 확인 | 드라이버 서명·장치 상태 정상. 앱 재시작 후에도 탐지한다. |
| 모니터 연결 상태에서 추가·제거 | 모니터 수와 화면 전환이 일치하며 물리 화면을 제거하지 않는다. |
| 물리 모니터 분리 후 직접 IP 접속 | 자동 가상 화면 생성 및 원격 화면 표시. |
| 해상도 변경·프라이버시 모드·연결 종료 | 지원 모드만 적용되고 마지막 연결 종료 후 정리가 일관된다. |
| 재접속·재부팅·RDP 전환 | 검은 화면·모니터 중복·남은 가상 화면 여부를 기록한다. |

이번 변경은 문서만 추가한다. 기존 파일과 런타임 동작을 변경하지 않았으며, 드라이버 설치나 Windows 빌드를 실행하지 않았다.
