<!-- SPDX-License-Identifier: AGPL-3.0-only -->
# 업스트림 기준과 갱신 절차

## P0-01 시작 기준

아래 해시는 포크 작업 시작 시점의 기준이며, 이후 MyDesk 커밋의 HEAD를 뜻하지 않는다.

| 구성요소 | 원본 업스트림 | 기준 커밋 | 태그 관계 |
| --- | --- | --- | --- |
| RustDesk | https://github.com/rustdesk/rustdesk | `fcb485bb9033a1e31869ae8e84574a1bf58b8c03` | `1.5.3-26-gfcb485bb9` (기준 커밋 자체에는 태그 없음) |
| hbb_common | https://github.com/rustdesk/hbb_common | `fae47e024dd83cef6aaecde0aa7d11731df11649` | `driver-453-gfae47e0` (기준 커밋 자체에는 태그 없음) |

- RustDesk `1.5.3` 태그의 커밋: `95cca3f661f635b3cc85c04935fe8d96d8f432ef`.
- hbb_common의 위 describe 기준 `driver` 태그 커밋: `4bd7fff39f859a868dc48fce97d4d06c9d3d7ff5`.
  이는 드라이버 관련 태그 이름이며 RustDesk 릴리스 버전을 뜻하지 않는다.
- 클라이언트 포크(origin): https://github.com/dmdr98-gif/mydesk.git
- hbb_common 포크: https://github.com/dmdr98-gif/hbb_common
- P0-01은 `.gitmodules` URL만 바꾸며 gitlink 커밋은 유지한다.

## 초기화와 확인

```sh
git submodule sync --recursive
git submodule update --init --recursive
git submodule status --recursive
cargo metadata --no-deps >/dev/null
```

`sync`는 이미 초기화된 체크아웃의 로컬 URL도 `.gitmodules`와 맞춘다.
서브모듈 상태 앞의 공백은 일치, `-`는 미초기화, `+`는 gitlink와 불일치,
`U`는 충돌이다. 정상 상태에서는 공백이어야 한다.

## 향후 rebase 절차

1. 작업 트리와 서브모듈이 깨끗한지 확인하고 로컬 백업 브랜치를 만든다.
   `git branch backup/before-upstream-rebase` (이미 있으면 새 이름 사용).
2. `git remote -v`로 `upstream`이 원본 RustDesk인지 확인한다.
   없을 때만 `git remote add upstream https://github.com/rustdesk/rustdesk.git`.
   `git fetch upstream --tags` 후 검토할 태그 또는 전체 커밋 해시를 선택한다.
3. 작업 브랜치에서 `git rebase <선택한-업스트림-태그-또는-커밋>`을 실행한다.
   충돌은 포크 변경과 업스트림 의도를 비교해 해결하고 `git rebase --continue`한다.
   중단하려면 `git rebase --abort`한다. `.gitmodules`의 포크 URL을 유지한다.
4. `git submodule sync --recursive`와 `git submodule update --init --recursive`로
   새 부모 커밋이 지정하는 gitlink를 체크아웃한다. `--remote`로 임의 최신화하지 않는다.
   포크에 해당 객체가 없어 실패하면 원본에서 해시를 확인하고 별도 포크 동기화 작업으로
   처리한다. 이 절차는 push나 저장소 생성을 수행하지 않는다.
5. hbb_common 변경이 필요할 때만 서브모듈 내부 작업 브랜치에서 원본 변경을 검토하고
   rebase한다. 이전 gitlink부터 새 gitlink까지 `git log`와 `git diff`를 확인하여
   무관한 커밋을 포함하지 않는다. 클라이언트 전용 코드는 `libs/base`에 둔다.
6. 위 초기화 검증, 변경 관련 Linux 검사, Windows `windows-build` 및 실기 검증을
   수행한다. 이 문서에 새 원본 기준 해시와 태그 관계를 기록하고, gitlink 변경은
   의도한 경우에만 스테이징한다. 실패 원인과 미검증 항목도 기록한다.

P0-01에서는 `task/p0-01`의 로컬 변경/커밋까지만 허용하며 push, 릴리스 게시는 하지 않는다.
