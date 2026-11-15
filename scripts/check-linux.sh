#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-only

set -uo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)" || exit 1
cd -- "$repo_root" || exit 1

# The box's rustup toolchain is not always on PATH.
if [[ -d /home/box/apps/rust/cargo/bin ]]; then
    export PATH="/home/box/apps/rust/cargo/bin:$PATH"
fi

results=()
failed=0
record() {
    results+=("$1  $2")
    printf '\n[%s] %s\n' "$1" "$2"
    if [[ $1 == FAIL ]]; then
        failed=1
    fi
}

run_step() {
    local label=$1
    shift
    printf '\n>>> %s\n' "$label"
    if "$@"; then
        record PASS "$label"
    else
        local status=$?
        record FAIL "$label (exit $status)"
    fi
}

run_step 'cargo check -p hbb_common' cargo check -p hbb_common
# socket_client::tests::test_test_if_valid_server expects DNS lookup of "a" to fail.
# Sandboxed/proxied networks (like the box) resolve every name, so it is skipped by default.
# Set HBB_TEST_SKIP= (empty) to run every test.
HBB_TEST_SKIP=${HBB_TEST_SKIP-socket_client::tests::test_test_if_valid_server}
hbb_test_args=()
if [[ -n $HBB_TEST_SKIP ]]; then
    hbb_test_args=(-- --skip "$HBB_TEST_SKIP")
fi
run_step 'cargo test -p hbb_common' cargo test -p hbb_common "${hbb_test_args[@]}"

missing_packages=()
if [[ $(uname -s) != Linux ]]; then
    record SKIP 'cargo check --features flutter (Linux only)'
else
    if ! command -v pkg-config >/dev/null 2>&1; then
        missing_packages+=(pkg-config)
    fi
    # pkg-config probes development files rather than installed runtime libraries.
    for dependency in \
        'gtk+-3.0:libgtk-3-dev' \
        'ayatana-appindicator3-0.1:libayatana-appindicator3-dev' \
        'alsa:libasound2-dev' \
        'libpulse:libpulse-dev' \
        'gstreamer-1.0:libgstreamer1.0-dev' \
        'gstreamer-app-1.0:libgstreamer-plugins-base1.0-dev' \
        'xcb-randr:libxcb-randr0-dev' \
        'xcb-shape:libxcb-shape0-dev' \
        'xcb-xfixes:libxcb-xfixes0-dev' \
        'xdo:libxdo-dev' \
        'xfixes:libxfixes-dev' \
        'libva:libva-dev' \
        'openssl:libssl-dev'; do
        if ! pkg-config --exists "${dependency%%:*}" 2>/dev/null; then
            missing_packages+=("${dependency#*:}")
        fi
    done
    if ((${#missing_packages[@]})); then
        printf '\nMissing Linux development packages (not installed by this script):\n'
        printf '  %s\n' "${missing_packages[@]}"
        printf 'Other upstream build prerequisites: clang libclang-dev llvm-dev cmake ninja-build nasm libunwind-dev\n'
        printf 'Native codec dependencies also require the upstream vcpkg setup (see vcpkg.json).\n'
        record SKIP 'cargo check --features flutter (missing Linux dependencies)'
    else
        run_step 'cargo check --features flutter' cargo check --features flutter
    fi
fi

if command -v flutter >/dev/null 2>&1; then
    run_step 'flutter analyze' bash -c 'cd flutter && flutter analyze'
else
    record SKIP 'flutter analyze (flutter not found on PATH)'
fi

printf '\n>>> Branding report (case-insensitive matching lines; informational)\n'
if command -v rg >/dev/null 2>&1; then
    # Respect ignore files and omit build output even if ignore rules change.
    report=$(mktemp) || exit 1
    rg -n -i 'rustdesk' --glob '!**/LICENCE' --glob '!**/LICENSE*' \
        --glob '!**/COPYING*' --glob '!**/target/**' --glob '!**/build/**' \
        --glob '!scripts/check-linux.sh' . > "$report"
    rg_status=$?
    if ((rg_status <= 1)); then
        printf 'Remaining matching lines: %s\n' "$(wc -l < "$report")"
        printf 'Scope: non-hidden, non-ignored text files; licence notices/build output/check script excluded.\n'
        printf 'Includes technical names and upstream references; matches do not fail this check.\n'
        record PASS 'branding report'
    else
        record FAIL "branding report (rg exit $rg_status)"
    fi
    rm -f -- "$report"
else
    record FAIL 'branding report (rg missing; apt package: ripgrep)'
fi

printf '\n===== Linux check summary =====\n'
printf '%s\n' "${results[@]}"
exit "$failed"
