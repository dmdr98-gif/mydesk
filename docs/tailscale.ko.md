<!-- SPDX-License-Identifier: AGPL-3.0-only -->
# Tailscale로 집 PC에 접속하기

집 Windows PC와 제어 기기를 같은 Tailscale 네트워크에 등록하면 외부 Wi-Fi나
모바일 데이터에서 everywhere로 접속할 수 있습니다. everywhere의 ID·릴레이 서버나
공유기 포트포워딩은 필요 없습니다. Tailscale 설치와 최초 로그인은 공식 클라이언트에서
진행하며, Android는 시스템 VPN 승인도 필요합니다.

1. 집 PC에서 everywhere를 설치하고 홈 화면의 **Tailscale 원격 접속**을 엽니다.
   안내에 따라 공식 Tailscale을 설치하고 연결합니다.
2. **직접 IP 액세스 허용**과 everywhere 서비스가 켜져 있는지 확인합니다. 연결할
   PC의 Tailscale IPv4 주소와 포트가 표시됩니다. 기본 포트는 TCP 21118입니다.
   집을 비울 때는 PC를 켜 두고 절전을 해제합니다. 현장에서 승인할 수 없으면
   everywhere의 고정 접속 비밀번호를 설정합니다.
3. 갤럭시에서는 everywhere APK와 공식 Tailscale 앱을 설치하고 같은 Tailscale
   네트워크에 로그인합니다. everywhere의 **Tailscale 원격 접속**에서 집 PC의 QR을
   스캔하거나 주소를 붙여 넣어 등록합니다.
4. 등록 후 갤럭시에서 **연결**을 누르면 저장된 집 PC로 접속합니다. 앱이 지원하는
   Tailscale 자동 시작 기능은 최초 로그인과 VPN 승인이 끝난 뒤 사용할 수 있습니다.
   자동 시작이 지원되지 않거나 다른 VPN이 켜져 있으면 공식 앱에서 연결 상태를 확인하고
   돌아와 다시 시도합니다.
5. 외부 Windows PC도 같은 Tailscale 네트워크에 연결합니다. everywhere의 상대 ID
   칸에 집 PC에서 복사한 `100.x.y.z:21118` 형식의 주소를 입력합니다.

QR과 휴대폰에 저장된 정보에는 집 PC의 주소와 포트만 들어 있습니다. 접속 요청 승인
또는 everywhere 비밀번호 인증은 계속 적용됩니다. 방화벽이나 Tailscale 접근 정책을
설정했다면 제어 기기에서 해당 TCP 포트로 접근할 수 있어야 합니다.

첫 외부 접속은 갤럭시의 Wi-Fi를 끄고 LTE·5G에서 진행합니다. 화면과 터치 동작을 확인한
후 외부 Windows PC에서도 같은 주소로 시험합니다. Windows 재부팅 후 로그인 전 접속이
필요하면 [Tailscale 무인 실행](https://tailscale.com/docs/how-to/run-unattended)을 켜고
everywhere Windows 서비스가 자동으로 시작되는지 확인합니다.

[Tailscale Windows 설치](https://tailscale.com/docs/install/windows) ·
[Tailscale Android 설치](https://tailscale.com/docs/install/android) ·
[everywhere 연결 안내](everywhere-connect.md)
