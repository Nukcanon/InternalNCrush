# Linux / NAS 공개 로비

Docker Compose v2로 HTTPS 로비 API, WSS 게임 게이트웨이, 서버 권한형 Godot 방 프로세스를 함께 실행한다. 인터넷 로비는 LAN 방 검색과 별도이며 게임 메인 메뉴의 **인터넷 로비**에서 운영자 URL을 입력한다. 이 저장소나 GitHub Pages가 실시간 서버를 호스팅하지는 않는다.

## 설치

64비트 Linux x86-64 또는 ARM64, Docker Engine/Compose v2, 공개 DNS 이름이 필요하다. 이미지에는 두 CPU용 Godot 다운로드 경로가 있다. 실제 검증한 CPU와 결과는 [검증 보고서](../../games/relaystrike/docs/TEST_REPORT.md)를 확인한다. 32비트 ARM NAS는 지원하지 않는다.

```sh
git clone https://github.com/Nukcanon/InternalNCrush.git
cd InternalNCrush/services/matchmaker
cp .env.example .env
# .env의 DOMAIN과 ACME_EMAIL을 실제 도메인/이메일로 변경
docker compose up -d --build
docker compose ps
curl https://실제도메인/health
```

DNS A/AAAA를 서버의 공인 IP로 연결하고 공유기/NAS에서 TCP 80·443만 이 구성으로 전달한다. Caddy가 공인 인증서를 발급·갱신한다. 잘못된 AAAA, CGNAT, ISP의 포트 차단이 있으면 먼저 네트워크 환경을 해결해야 한다. NAS 관리 화면이 이미 80/443을 사용한다면 별도 IP 또는 기존 TLS 리버스 프록시 연동이 필요하다. 관리 화면을 게임 포트로 공개하지 않는다.

게임 클라이언트에서 `https://실제도메인`으로 연결한다. **공개 방 만들기**는 방장이 시작하고, **빠른 참가**는 원하는 모드 또는 모든 모드로 참가 가능한 방을 찾는다. 새 자동 매칭 방은 2명 이상 들어오면 시작한다. 기본은 8인 CARGO ROW, 참가 인원은 맵 정원을 초과할 수 없다. 게임과 서버 버전은 같아야 한다.

## 운영

- 기본 최대 4개 방, API 세션 최대 2,000개, 게스트당 방 생성 1개. `.env`의 `MAX_ROOMS=1..4`로 줄일 수 있다. 기본 컨테이너 제한은 CPU 4개/메모리 4GB/프로세스 256개이며 이는 처리 성능 보장이 아니다. NAS 사양에 맞춰 시작은 1개 방을 권장한다.
- 방당 전용 Godot 프로세스 하나. 봇은 공개 매칭의 빈자리를 자동으로 채우지 않는다. 빈 방 180초, 시작 실패 90초, 하트비트 중단 20초 후 정리한다.
- 세션은 6시간, 입장권은 30초 유효하며 한 번만 사용한다. 재접속은 로비에서 새 입장권을 받는다. 토큰은 클라이언트 메모리에만 둔다.
- `docker compose logs --tail 100`으로 API/게이트웨이 시작 문제를 확인한다. 개별 게임 프로세스 stdout은 무제한 로그와 정보 노출을 피하려고 버린다. `/health`는 API 가용성만 검사한다. 방 준비 실패는 방 목록에서 사라지므로 외부 모니터링은 실제 입장 검사도 포함해야 한다.
- 업데이트: `git pull --ff-only` 후 `docker compose up -d --build`. 컨테이너 교체 시 진행 중 경기는 종료되므로 이용자에게 점검 시간을 알리고 적용한다.
- 종료: `docker compose down`. 인증서 볼륨은 유지한다. `down -v`는 인증서도 지우므로 평상시 업데이트에 사용하지 않는다.
- 현재 방/게스트 세션은 메모리 저장이다. 재시작 후 복구되지 않는다. 고정 계정, 영구 제재, 순위/MMR, 지역 선택, 관전자 서비스와 여러 NAS 간 분산 배치는 후속 과제다.

## 보안 경계

인터넷 클라이언트↔Caddy는 인증서와 호스트 이름을 검증하는 HTTPS/WSS다. 입장권은 방별 비밀 키로 HMAC-SHA256 서명하고 방/만료/1회용 nonce를 검증한다. 내부 하트비트 API는 게이트웨이에서 차단한다. Godot/API 포트는 호스트로 공개하지 않으며 컨테이너 내부 네트워크에서만 통신한다. Docker 소켓을 마운트하지 않고 게임/API는 비루트 사용자로 실행한다.

이동·발사 간격·탄약·피해·장비·팀·목표·수류탄은 서버가 결정한다. 클라이언트는 입력만 보내며 NaN/무한대/타입 오류, 잘못된 명령, 과도한 입력 빈도와 너무 큰 API 요청을 거부한다. 서버간 API 키와 세션 토큰은 공개 방 목록에 포함하지 않는다.

암호화는 네트워크 구간의 평문 도청/변조를 막기 위한 것이다. 클라이언트 메모리의 상대 위치, 에임봇, 화면 인식, 감염된 PC, 서버 관리자에 대한 보호까지 보장하지 않는다. 현재 스냅샷은 모든 참가자의 위치를 포함하므로 벽 너머 정보의 클라이언트 분석을 완전히 차단하지 못한다. 게스트가 새 세션으로 제재를 우회할 수도 있다. 계정 인증·영구 제재·시야 기반 정보 제한·행동 탐지·운영자 신고/재생 도구·DDoS 보호가 공개 대규모 운영 전에 추가로 필요하다.

LAN 모드는 기존 UDP ENet이며 암호화되지 않는다. 신뢰할 수 있는 내부망에서 사용한다. 인터넷 WSS는 TCP 기반이므로 패킷 손실 시 뒤 데이터가 함께 지연될 수 있다. 로컬 연결 성공을 WAN 대규모 성능 검증으로 해석하지 않는다. 장기 고빈도 경쟁전 서버는 인증된 UDP/DTLS 또는 QUIC 전송을 따로 평가해야 한다.

## 개발 검증

```sh
pip install -r services/matchmaker/requirements.txt httpx==0.28.1
python -m unittest services.matchmaker.test_service -v
GODOT=/절대경로/godot python -m services.matchmaker.run_integration
python services/matchmaker/test_docker.py
```

저장소 루트에서 실행한다. 마지막 검사는 임시 Compose 프로젝트 `inc-ci`를 생성하며 로컬 80/443을 사용한다. 전용 개발/CI 머신에서 실행한다. 테스트가 만든 컨테이너와 볼륨만 종료 시 정리한다. 인증서 검증을 끄지 않고 임시 Caddy CA를 테스트 클라이언트에만 지정해 HTTPS/WSS를 검사하며, 신뢰되지 않는 CA와 다른 호스트 이름의 인증서는 거부하는지도 검사한다. 일반 게임에는 테스트 CA 설정이 적용되지 않는다.

설계 근거: [FastAPI 컨테이너 배포](https://fastapi.tiangolo.com/deployment/docker/), [Caddy 자동 HTTPS](https://caddyserver.com/docs/automatic-https), [Godot WebSocketMultiplayerPeer](https://docs.godotengine.org/en/4.4/classes/class_websocketmultiplayerpeer.html). 공인 도메인/NAS 접속 정보가 제공되지 않은 상태에서는 외부 운영 서버가 배포됐다고 간주하지 않는다.
