<!-- SPDX-License-Identifier: AGPL-3.0-only -->
# MyDesk Windows CI

`windows-build.yml`이 MyDesk 자동 빌드 진입점이다. `main`, `master`,
`task/**` push, 모든 pull request, 수동 실행을 지원한다. Windows x64
(`windows-2022`, `x86_64-pc-windows-msvc`)만 제품으로 빌드한다.

## 빌드 구성

- Rust/Sciter Rust 1.75, LLVM 15.0.6, Flutter 3.24.5,
  flutter_rust_bridge 1.80.1, vcpkg 커밋
  `9e593bb18ea69cc5095e012465dcd675a822ed0d`를 고정했다.
- Ubuntu 선행 잡에서 업스트림 bridge.yml의 코드 생성 절차를 실행한다.
  ARM64용 브리지는 제외하고, Flutter는 제품과 같은 3.24.5를 사용하므로
  업스트림 3.22.3용 extended_text 다운그레이드는 필요하지 않다.
  로컬에서 코드 생성기를 실행하지 않는다.
- 기존 재사용 워크플로로 x64 WindowInjection.dll을 빌드한다.
- 업스트림 Windows 커스텀 엔진 zip 교체와 dropdown 패치를 유지했다.
  Flutter SDK/pub, Cargo, vcpkg 캐시를 사용한다. SDK 패치는 캐시 복원 후에도
  중복 적용하지 않는다.
- `python3 .\build.py --portable --flutter --hwcodec --vram`으로 빌드한다.
  업스트림 x64의 vram 옵션을 유지한다. WindowInjection.dll을 추가한 뒤
  포터블 EXE를 다시 패킹해 MSI와 같은 앱 파일을 포함한다.
- `res/msi`에서 preprocess, NuGet 복원, x64 MSBuild를 수행한다.
  `mydesk-windows-x64` 아티팩트에 EXE/MSI를 14일 보관한다.
  중간 브리지/DLL 아티팩트도 14일 보관한다.
- 릴리스 게시, nightly 태그, 서명 서버 호출, 템플릿 패키지는 제외했다.
  새 워크플로에는 비밀값이나 서명 단계가 없다. P9에서 자체 서명을 추가한다.
- usbmmidd/프린터 드라이버 다운로드는 선택 기능이며 이번 기본 CI에는
  포함하지 않는다. 드라이버 재배포/동봉은 P4/P9에서 별도 검토한다.

## 기존 워크플로 처리

| 파일 | 결정 |
| --- | --- |
| flutter-build.yml | 삭제하지 않고 workflow_dispatch 전용으로 보존. 입력과 기존 업스트림 빌드 본문 유지. 수동 실행 시 기존 게시/서명 동작이 있을 수 있으므로 참고용으로만 사용. |
| ci.yml | push/PR 제거, workflow_dispatch 전용. |
| flutter-ci.yml, flutter-nightly.yml, flutter-tag.yml | workflow_dispatch 전용. 더 이상 호출할 수 없는 flutter-build 재사용 호출을 windows-build 실행 안내로 대체. |
| fdroid.yml | 태그 push 제거, workflow_dispatch 전용. |
| update-webpki-roots.yml | schedule 제거, workflow_dispatch 전용. |
| playground.yml, clear-cache.yml | 이미 workflow_dispatch 전용이므로 그대로 유지. |
| bridge.yml | workflow_call 전용 유지. 자동 실행 없음. 새 CI는 ARM64 생성을 피하려고 기본 생성 절차만 자체 포함. |
| third-party-RustDeskTempTopMostWindow.yml | workflow_call 전용 유지. 새 CI에서 x64로 호출. 아티팩트 보존 기간만 14일로 지정. |

## 검증 및 남은 확인

- Linux: `actionlint .github/workflows/windows-build.yml` 통과.
- `git diff --check`로 변경 파일의 공백 오류 확인.
- 전체 `actionlint .github/workflows/*.yml`은 기존 ci.yml, flutter-build.yml,
  playground.yml 및 third-party 워크플로의 기존 진단 때문에 실패한다.
  해당 기존 코드의 수정은 이번 범위에서 제외했다.
- GitHub Actions에서 브리지 생성, 엔진 다운로드, 캐시 cold/warm 빌드,
  EXE 패킹 및 MSI 생성을 확인해야 한다. Linux에서 Windows 빌드는 실행하지 않았다.
- Windows 10/11 x64에서 EXE 실행, MSI 설치/제거, ID 표시 및 기본 원격 연결을
  확인해야 한다. 결과물은 현재 RustDesk 이름을 유지하며 서명되지 않는다.
- TODO: P1 브랜딩, P4/P9 드라이버 검토, P9 자체 서명/업데이트.

## 회귀 영향 범위

기존 앱/Rust/Dart 런타임 경로는 변경하지 않았다. 위 기존 워크플로의
자동 트리거와 Flutter 래퍼의 수동 실행 동작만 변경했다. 포크에서 불필요한
다중 플랫폼 빌드/게시가 자동 실행되지 않도록 하기 위한 필수 변경이다.
재사용 DLL 빌드는 기존 동작을 유지하며 아티팩트 보존 기간만 변경했다.
커밋, push, 저장소 생성, 릴리스 게시는 수행하지 않는다.
