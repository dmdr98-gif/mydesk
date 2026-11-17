<!-- SPDX-License-Identifier: AGPL-3.0-only -->
# 서버 없이 실행하는 개발 검사

저장소 루트에서 다음 명령으로 한국어 키와 보간 문자열을 검사한다. Python 3
표준 라이브러리만 사용하며 네트워크, Flutter, Rust 빌드가 필요하지 않다.

```sh
python3 scripts/check-localization.py
```

`template.rs`의 키와 `ko.rs`를 비교해 누락·빈 번역·알 수 없는 키·중복 키를
검사한다. `{}` 및 `%min%` 같은 보간 문자열은 `en.rs`의 비어 있지 않은 번역을
원문으로 사용하고, 해당 번역이 없으면 키 자체를 원문으로 사용해 비교한다.
누락이나 불일치가 있으면 종료 코드 1을 반환한다. 문장 품질과 실제 화면의 줄바꿈은
이 검사만으로 확인할 수 없다. 기존 번역을 자동으로 수정하지 않는다.

2026-11-17 검사 결과는 한국어 826/826개 키, 누락·빈 번역·추가 키 0개이며
보간 문자열도 일치했다. Windows 및 Android 제품 CI가 빌드 전에 같은 검사를
실행한다.

전체 Linux 개발 검사는 다음 명령으로 실행한다.

```sh
bash scripts/check-linux.sh
```

각 단계는 `PASS`, `FAIL`, `SKIP`으로 표시된다. 누락된 Linux 개발 패키지나
Flutter SDK 때문에 건너뛴 단계는 통과한 것이 아니다. 이 스크립트가 종료 코드
0을 반환해도 Windows·Android 설치나 원격 접속 실기 검증을 대신하지 않는다.

박스의 영구 Rust 툴체인은 `/home/box/apps/rust/rustup`에 있으며, 검사 스크립트가
`RUSTUP_HOME`이 비어 있으면 이 경로를 선택한다. 이미 지정한 환경변수는 유지한다.
Cargo는 쓰기 가능한 캐시와 해당 잠금 파일의 모든 의존성이 필요하다. 읽기 전용
캐시를 사용하는 환경에서는 `CARGO_HOME`을 준비된 쓰기 가능 경로로 지정한다.
`XDG_CONFIG_HOME`도 임시 폴더로 지정하면 테스트가 개인 설정에 쓰지 않는다.

현재 박스에 보관된 Cargo 캐시는 crates.io 인덱스와 일부 잠금 버전이 빠져 있어
`cargo check --offline -p hbb_common`이 의존성 해석 단계에서 실패한다. 영구 캐시나
잠금 파일을 바꿔 이 검사를 통과시키지 않았다. 전체 Rust 빌드는 GitHub Actions에서
확인하고, 로컬 오프라인 재실행에는 완전한 캐시를 별도로 준비해야 한다.
