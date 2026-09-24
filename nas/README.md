# Linux / NAS · 방 목록 서버

1.1.2 구성은 방 목록·빠른 매치 배정·입장 승인·WebRTC 접속 신호만 처리합니다. **실제 경기는 방장 PC 또는 브라우저가 계산**하며 NAS에 Godot나 게임 에셋을 설치하지 않습니다. 기존 1.0.x 전용 방 프로세스 구성은 `services/matchmaker/`에 참고용으로 남아 있습니다.

## 쉬운 설정

Windows에 Python 3.9 이상이 있으면 **01_설정.cmd**를 실행하세요. 설치 대상(NAS / Linux), 도메인, 최대 방 수를 선택하면 `.env`와 서버 업로드 ZIP을 만듭니다. 기존 TURN 설정은 유지하고 기존 `.env`는 백업합니다. ZIP에는 설정이 포함되므로 관리자가 보관하세요. 첨부 예시의 구성 방식을 참고해 새로 작성했으며 외부 설치 프로그램을 실행하지 않습니다.

- **NAS**: 기존 HTTPS 역방향 프록시에서 `https://도메인:443` → `http://127.0.0.1:18080`. WebSocket을 허용하고 `X-Real-IP`를 실제 요청자 주소로 덮어쓰세요. 기본 호스트 포트는 루프백으로 제한합니다. 프록시가 별도 컨테이너라면 해당 호스트에 접근 가능한 사설 인터페이스를 운영자가 지정해야 합니다.
- **Linux**: 도메인의 A/AAAA를 서버로 연결하고 TCP 80/443을 전달합니다. Caddy가 공인 인증서를 발급·갱신합니다. CGNAT나 잘못된 AAAA는 먼저 해결해야 합니다.

업로드 ZIP을 풀고 `nas` 폴더에서 실행합니다. Docker Engine와 Compose v2가 필요합니다.

```sh
sh 02_start.sh
sh 03_status.sh
curl https://실제도메인/health
```

`role: directory-only`, `version: 1.1.2`을 확인하고 게임 인터넷 로비에 동일한 HTTPS 주소를 입력하세요. `python setup.py --check`도 인증서 검증을 포함해 접속을 확인합니다. 설정 마법사 없이 `.env.example`을 복사해 직접 설정할 수도 있습니다.

## 운영과 연결

기본 최대 128개 방(설정 1~512), 디렉터리 컨테이너 1 CPU / 256 MB / 64 프로세스 제한입니다. 이는 처리량 보장이 아닙니다. Python과 Caddy 공식 멀티아키텍처 이미지를 사용하며 실제 ARM NAS 검증은 별도입니다. 비루트 UID 10001, 읽기 전용 루트, 권한 제거, 내부 API 포트 비공개입니다.

세션 6시간, 일회용 입장 승인 30초, 방장 상태 수신 8초, 미응답 방 45초 정리를 적용합니다. 방장은 퇴장 전까지 게임 서버 역할을 유지해야 합니다. 방장 자동 이전과 계정/MMR은 지원하지 않습니다. 서비스 재시작은 목록을 초기화하고 신호 연결을 종료하므로 점검 시간에 수행하세요.

```sh
docker compose logs --tail 100
docker compose up -d --build
sh 04_stop.sh
```

종료는 인증서 볼륨을 보존합니다. 게임 파일은 이 서버에 없으며 클라이언트는 GitHub Pages 또는 Windows 릴리스에서 받습니다. 봇은 빠른 매치의 빈자리를 자동으로 채우지 않으며 2명부터 시작합니다.

STUN으로 직접 연결을 시도합니다. 기업망·대칭 NAT에서 접속이 막히면 운영하는 TURN의 URL과 REST 비밀키를 `.env`에 설정하세요. 기본 구성은 유료 중계를 신청하지 않습니다. NAS는 기본 전투 트래픽을 중계하지 않지만 **TURN을 같은 NAS에서 별도로 운영하면 중계 대역폭은 발생**합니다.

웹 내부망 로비는 동일 외부 주소의 방을 표시합니다. Windows UDP 방과 별도이며 Windows에서도 ‘웹 호환 로비’를 사용하면 함께 참가할 수 있습니다. 공유 NAT에서는 다른 사용자도 같은 그룹일 수 있어 비밀번호 방이 권장됩니다. 목록 핑은 로비 왕복+방장 응답의 추정치, 경기 HUD 핑은 실제 게임 연결 값입니다.

## 보안과 검사

HTTPS/WSS 인증서·호스트 이름 검증, 짧은 입장 승인, 메시지 크기·빈도 제한, 호스트↔참가자 신호 라우팅을 적용합니다. 전투는 WebRTC DTLS/SCTP 암호화와 방장 권한 검증을 사용합니다. Windows 기본 LAN ENet은 평문입니다. 암호화가 클라이언트/방장의 변조, 메모리 분석이나 에임봇을 완전히 막지는 않습니다.

```sh
pip install -r services/directory/requirements.txt httpx==0.28.1
python -m unittest services.directory.test_directory nas.test_setup -v
python services/directory/check_live.py https://실제도메인 --version 1.1.2
python services/directory/test_docker.py
```

위 검사는 저장소 루트에서 실행합니다. Docker 검사는 자체 `inc-directory-ci` 프로젝트, 18080/18443 포트와 일회용 CA를 사용하고 자기 컨테이너/볼륨만 정리합니다. 시스템 신뢰 저장소를 변경하지 않습니다. 무료 호스팅 대안은 [Cloudflare 구성](../services/cloudflare-directory/README.md)입니다.
