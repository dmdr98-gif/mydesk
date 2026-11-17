<!-- SPDX-License-Identifier: AGPL-3.0-only -->
# everywhere 원격 터미널 검증 현황

확인일: 2026-11-17 KST. 기준: 클라이언트 `b5d711a45`의 기존 구현. P7-01 중 구조·권한·종료 경로와 실기 항목을 정리했다. Windows ConPTY 실행 및 사용자 간 권한 분리는 아직 실기 미검증이다.

## 구조

터미널은 별도의 인증된 연결 종류다. Flutter `TerminalModel`이 Open/Resize/Data/Close 요청을 브리지로 보내고, 호스트 `TerminalServiceProxy`가 `service_id`별 PTY 세션을 처리한다. 기본 크기는 80열×24행이며 실제 뷰 크기를 알면 그 값을 사용한다. 근거: `flutter/lib/models/terminal_model.dart:230`; `src/server/connection.rs:6306`, `:6326`; `src/server/terminal_service.rs:1008`.

Windows의 현재 사용자 경로는 `portable-pty`를 사용한다. 지정 Windows 사용자 토큰이 필요한 경우 같은 실행 파일을 `--terminal-helper`로 실행하고 제한된 Named Pipe를 통해 서비스와 연결한다. helper가 해당 사용자 환경에서 ConPTY와 셸을 생성한다. Pipe DACL에는 SYSTEM과 대상 사용자를 허용하는 경로가 있다. 근거: `src/server/terminal_service.rs:1377`; `src/server/terminal_helper.rs:415`, `:703`, `:819`, `:857`.

기본 셸은 PowerShell Core의 정해진 파일 경로 → Windows PowerShell → `COMSPEC`/cmd 순서로 결정한다. 현재 Flutter 열기 요청에는 셸 선택 항목이 없다. PowerShell은 UTF-8 입출력 설정, cmd는 코드페이지 65001을 적용하는 코드가 이미 있다. 출력은 서버에서 분할 UTF-8 바이트를 모아 전달하고 Flutter에서 디코딩한다. 근거: `src/server/terminal_helper.rs:296`, `:321`, `:344`; `src/server/terminal_service.rs:585`, `:635`; `flutter/lib/models/terminal_model.dart:488`.

## 권한과 설정

| 항목 | 동작·근거 |
| --- | --- |
| `enable-terminal` | 호스트 터미널 허용 옵션. 계정 제어 권한이 있으면 `Permission::terminal`을 해석하고, 없으면 로컬 권한을 따른다(`src/server/connection.rs:2718`). |
| 로그인 시 허용 검사 | 터미널 권한이 없으면 `No permission of terminal`로 거부한다(`src/server/connection.rs:2951`). |
| Windows OS 로그인 | 사용자명을 지정하는 터미널 접속은 설치형 앱만 허용한다. OS 자격 증명 인증과, 기존 서비스가 지정 사용자 토큰 경로인지 비교하는 검사도 존재한다(`src/server/connection.rs:2957`, `:4249`, `:4351`). |
| `terminal-persistent` | 연결 종료 후 터미널 유지 여부. 기본 연결 필드는 false이며 로그인 옵션과 세션 옵션으로 갱신한다(`src/server/connection.rs:658`, `:2965`, `:5122`). |
| 연결별 메시지 범위 | 터미널 연결에는 터미널 전용 메시지 범위를 적용한다(`authorized_message_scope_violation`, `src/server/connection.rs:5950`). |
| 클립보드 | Flutter 터미널은 클립보드 권한과 사용자 설정을 별도로 참조한다(`flutter/lib/models/terminal_model.dart:29`, `:161`). |

로그인 시 권한 검사가 있다는 사실과 **이미 연결된 세션에서 권한을 끌 때 즉시 차단되는지**는 별도 항목이다. 후자는 실기 확인표에 포함했으며, 이번 소스 조사만으로 완료 판정하지 않는다.

## 종료·유지 경로

일반 세션은 서비스 루프 종료 시 서비스를 제거한다. persistent 세션은 재접속을 위해 남겨 둔다(`run`, `src/server/terminal_service.rs:407`; 같은 정책의 `TerminalServiceProxy::on_disconnect:2080`). 따라서 persistent 옵션이 켜진 세션의 셸이 연결 종료 후 살아 있는 현상은 그 자체로 오류가 아니다.

터미널을 명시적으로 닫으면 세션을 제거하고 child kill/reaper 경로를 실행한다(`handle_close:1706`). 세션 drop은 `stop`을 호출해 채널·PTY·스레드·child를 정리한다. Windows helper 모드에서는 출력 읽기 스레드가 막히지 않도록 helper 종료를 먼저 시도한 뒤 스레드를 합친다(`TerminalSession::stop:787`, `Drop:884`). 서비스 정리는 비영구 서비스 idle 1시간, 비어 있는 영구 서비스 2시간 조건을 사용한다(`cleanup_inactive_services:238`).

이 경로의 존재만으로 모든 손자 프로세스·관리자 셸까지 종료됨을 입증할 수는 없다. 실행 중인 명령, helper, 자식 프로세스가 실제로 남지 않는지 Windows 작업 관리자/프로세스 조회로 확인해야 한다.

## 서버 없이 수행할 수 있는 검사

아래 기존 테스트는 호스트·컨트롤러 또는 외부 서버 없이 실행할 수 있다. 새 테스트 인프라는 추가하지 않았다.

| 검사 | 명령·범위 |
| --- | --- |
| UTF-8·출력 버퍼 | 저장소 루트에서 `cargo test --lib terminal_service::tests` — 기존 4개 테스트. 분할 다중 바이트, 불완전한 꼬리, 줄 없는 대용량 출력, 버퍼 크기 계산(`src/server/terminal_service.rs:2088`). |
| 인증 연결 종류별 메시지 분리 | `cargo test --lib session_scope_allows_only_messages_for_authenticated_session_type` — 기존 테스트(`src/server/connection.rs:7624`). |
| Flutter 터미널 | `flutter/`에서 `flutter test test/terminal_model_lifecycle_test.dart test/terminal_keyboard_utils_test.dart test/terminal_mouse_handler_test.dart test/terminal_alt_screen_scroll_test.dart`. |

이번 조사 환경에는 `flutter`/`dart` 명령이 없었다. Rust 루트 테스트는 전체 네이티브 앱 의존성을 빌드해야 하므로 이번 문서 작업에서는 실행하지 않았다. 위 명령은 **재실행 안내이며 통과 결과가 아니다**. P7-01의 `cargo check` 수용 기준과 Windows ConPTY 동작 확인은 남아 있다.

## Steven님 실기 확인표

자체 hbbs/hbbr 없이 같은 LAN 직접 IP 경로를 사용할 수 있다. [연결 안내](everywhere-connect.md#서버-없이-같은-lan에서-직접-ip-접속)에 따라 Windows 호스트에서 직접 접속을 켜고 TCP 21118을 허용한다.

| 확인 | 기대 결과 |
| --- | --- |
| 터미널 허용 off 상태에서 접속 | 터미널 생성·명령 실행 거부. 일반 화면 제어 권한과 혼동하지 않는다. |
| 허용 on, 일반 사용자 접속 | 대상 사용자의 셸·작업 폴더·권한이 일치한다. |
| Windows 사용자명을 지정한 로그인 | 설치형 서비스에서 대상 사용자로 실행되고 잘못된 자격 증명은 거부된다. |
| 한글 입력·출력·붙여넣기 | `안녕하세요`, 한글 경로, 여러 줄, 반복 출력이 깨지지 않는다. |
| 크기 변경·다중 탭 | 출력이 올바르게 다시 그려지고 탭 간 입력·출력이 섞이지 않는다. |
| 일반 모드에서 탭 닫기·네트워크 단절 | helper·셸·실행한 자식 명령이 남지 않는지 확인한다. |
| persistent on에서 단절·재접속 | 기존 셸과 출력이 복원되고 중복 명령을 실행하지 않는다. 명시적 닫기는 정리한다. |
| 연결 중 터미널 권한 off·클립보드 권한 off | 기존 세션 차단 동작과 복사·붙여넣기 제한을 각각 기록한다. |

## 다음 작업과 변경 범위

P7-02에는 셸 선택 UX, Windows 10/11 및 Android 입력·클립보드 사용성 검증이 남아 있다. 확인되지 않은 Windows 종료·권한 문제에 임의의 상태 관리나 재시도 로직을 추가하지 않았다.

이번 변경은 문서만 추가한다. 기존 파일과 런타임 동작을 변경하지 않았고, 코드 버그 수정 또는 ConPTY 실기 검증 완료를 주장하지 않는다.
