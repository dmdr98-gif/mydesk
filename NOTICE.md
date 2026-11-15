<!-- SPDX-License-Identifier: AGPL-3.0-only -->
# MyDesk 오픈소스 고지

MyDesk는 RustDesk를 기반으로 한 독립 포크이다. 원저작자와 기여자의 저작권,
라이선스 및 제3자 고지를 유지한다. 원본 기준 해시는 [UPSTREAM.md](UPSTREAM.md)에 기록한다.
RustDesk의 기존 저작권 표기에는 Purslane Tech Pte. Ltd.가 포함되어 있으며,
이 문서는 기존 파일의 고지를 대체하거나 저작권을 이전하지 않는다.

## AGPL-3.0 고지

이 포크의 신규 파일은 `AGPL-3.0-only`로 제공한다. RustDesk 기반 코드의
GNU Affero General Public License version 3 전문은 [LICENCE](LICENCE)에 있다.
프로그램은 해당 라이선스에 따라 사용·수정·재배포할 수 있으며, 법이 허용하는
범위에서 상품성이나 특정 목적 적합성을 포함한 보증 없이 제공된다.

배포 시 라이선스와 저작권 고지를 유지하고 해당 배포물의 Corresponding Source를
라이선스가 정한 방식으로 제공해야 한다. 수정 프로그램과 네트워크로 상호작용하는
사용자에게는 AGPL 제13조에 따라 해당 버전의 Corresponding Source를 무료로
받을 수 있는 기회를 명확히 제공해야 한다. 소스에는 필요한 빌드·설치 자료도 포함한다.
정확한 조건은 LICENCE 제4–6조 및 제13조를 따른다.

## 현재 주요 오픈소스 구성요소

아래는 저장소 수준의 주요 구성요소 목록이다. 전체 전이 의존성 고지나 배포물별
라이선스 원문 묶음을 대신하지 않는다. 각 파일의 원래 고지가 우선한다.

| 구성요소 | 역할 / 출처 | 라이선스 및 확인 근거 |
| --- | --- | --- |
| RustDesk | 클라이언트/호스트, https://github.com/rustdesk/rustdesk | AGPL-3.0, 루트 `LICENCE` |
| hbb_common | 공통 프로토콜/설정, https://github.com/rustdesk/hbb_common | RustDesk 공통 구성요소로 AGPL-3.0 고지에 포함. 현재 고정 트리에는 별도 LICENSE/LICENCE 및 Cargo license 필드가 없어 배포 전 원본 권리자 고지 재확인 필요 |
| Enigo (포크) | 입력 제어, `libs/enigo` | MIT, `libs/enigo/LICENSE` 및 `Cargo.toml`; Copyright (c) 2017 pythoneer |
| scrap (포크) | 화면 캡처, `libs/scrap` | MIT, `libs/scrap/Cargo.toml`; authors: Ram <quadrupleslap@gmail.com>. 배포 전 원문 고지 확보 |

Rust 의존성은 `Cargo.toml`, 각 workspace manifest 및 `Cargo.lock`, Flutter 의존성은
`flutter/pubspec.yaml`과 `flutter/pubspec.lock`, 네이티브 코덱과 라이브러리는
`vcpkg.json` 및 `res/vcpkg/`에서 추적한다. 이 목록에 있다고 모든 대상 빌드에
포함되는 것은 아니다. Flutter 엔진/SDK, Rust crate, 코덱, HW SDK, 드라이버는
실제 Windows 빌드에 포함된 버전과 빌드 옵션을 기준으로 원문 라이선스와 저작권
고지를 수집해야 한다. 특히 FFmpeg는 구성에 따라 라이선스 조건이 달라지며,
로컬 port manifest의 license 필드는 null이므로 배포 전에 별도 검증해야 한다.

자체 hbbs/hbbr, API 서버, ViGEm, USB/IP 등 향후 도입 항목은 이 작업에서 추가하지
않았다. 도입·배포 시 각각의 실제 버전과 라이선스, 드라이버 재배포 조건을 확인하고
이 목록과 배포용 고지 묶음을 갱신한다. 이 문서만으로 배포 준비 완료를 뜻하지 않는다.

## 상표와 독립성

**RustDesk 상표 미사용**: MyDesk 제품의 이름·로고·홍보에 RustDesk 상표를 사용하지
않으며 RustDesk 측의 공식 제품, 제휴 또는 보증을 의미하지 않는다. 출처와 저작권을
설명하기 위한 문서상 명칭은 유지한다. 현재 P0 기준 소스에는 기존 UI·리소스의
RustDesk 브랜딩이 남아 있으므로 제품 배포 전 P1 브랜딩 작업으로 교체해야 한다.

StarDesk(GearUP)의 코드·바이너리·드라이버·리소스·문자열은 복사하지 않는다.
이 포크는 오픈소스와 공개 문서만을 사용한다.

## 배포 전 TODO

- 실제 배포 버전의 소스 제공 URL과 프로그램 내 네트워크 사용자용 소스 안내를 연결한다.
- Windows 산출물의 전체 직접/전이 의존성과 동봉 드라이버·리소스 목록을 확정하고
  각 라이선스 전문, 저작권 고지 및 필요한 소스를 배포 패키지에 포함한다.
- hbb_common의 별도 라이선스 근거와 scrap의 원문 고지를 확보하고,
  FFmpeg/HW SDK/드라이버의 실제 빌드·재배포 조건을 확인한다.
- P1에서 제품명·로고·설치 파일의 기존 브랜딩을 교체한다.
