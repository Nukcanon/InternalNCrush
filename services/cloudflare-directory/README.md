# 무료 방 목록 서버 · Cloudflare Workers

경기 계산은 방을 만든 Windows PC 또는 웹 브라우저에서 실행합니다. 이 서버는 방 목록, 빠른 매치 배정, 일회용 입장 승인과 WebRTC 연결 신호만 처리합니다. 전투 패킷과 음성·영상은 이 서버를 통과하지 않습니다.

Workers **Free**의 SQLite Durable Object와 WebSocket hibernation을 사용합니다. 기본 32개 방이며 자동 유료 전환이나 유료 TURN 신청은 구성하지 않았습니다. 무료 일일 한도에 도달하면 새 로비 요청이 실패할 수 있습니다. GitHub Pages는 정적 게임 파일만 호스팅하며 이 서버를 실행할 수 없습니다.

## 배포

Cloudflare 계정이 필요합니다. Node.js 22 이상과 pnpm을 설치하고 이 폴더에서 실행합니다.

```sh
pnpm install --frozen-lockfile
pnpm exec wrangler login
pnpm test
pnpm exec wrangler deploy
```

마지막 명령이 출력하는 실제 `https://internal-n-crush-lobby.<계정>.workers.dev` 주소를 사용하세요. 표시된 주소의 `/health`가 `directory-only`와 현재 버전을 반환하는지 확인한 다음 게임 인터넷 로비에 입력합니다. 아직 배포하지 않은 주소를 게임 기본값으로 넣지 않습니다.

```sh
# Docker/NAS 서버와 같은 HTTP/WebSocket 계약 검사
python services/directory/check_live.py https://배포된주소 --version 1.1.2
```

Python 검사 명령은 저장소 루트 기준이며 `services/directory/requirements.txt`가 필요합니다. `GAME_VERSION`은 클라이언트와 일치시켜야 합니다. URL이 확정되면 `game/assets/lobby_defaults.json`의 `url`을 업데이트하고 게임을 다시 빌드할 수 있습니다.

## 로컬 검증

```sh
pnpm test
pnpm dev
```

`http://127.0.0.1:30881`에서 실행합니다. 게임은 로컬 테스트에 한해 localhost HTTP/WS를 허용합니다. 일반 인터넷 서버는 HTTPS/WSS를 요구합니다. `src/policy.mjs`는 방 정원·모드·신호 라우팅을 검증하며, `check_live.py`는 실제 WebSocket과 재사용 방지·방장 퇴장을 검사합니다.

## 연결과 운영 제한

- 서버가 생성한 세션, 30초 일회용 입장 승인, 방별 호스트↔참가자 라우팅, 크기·빈도 제한을 적용합니다. 키는 Durable Object 내부 저장소에서 생성되며 소스에 포함되지 않습니다.
- 입장 승인·방 설정은 SQLite 저장소에, 상태·핑은 hibernation attachment에 보관하여 8초 주기마다 데이터베이스에 쓰지 않습니다. 방장 연결이 끊기면 방을 종료합니다. 방장 자동 이전은 지원하지 않습니다.
- 목록의 핑은 클라이언트→로비와 로비→방장 왕복 시간을 합한 **예상치**입니다. 실제 경기 핑은 연결 후 게임 HUD에 표시됩니다.
- 웹 내부망 로비는 동일한 외부 주소에서 연결한 참가자만 보여 줍니다. UDP 브로드캐스트로 찾은 기존 Windows LAN 방과는 별도입니다. 공유 NAT 환경에서는 같은 목록에 다른 사용자가 나타날 수 있으므로 비밀번호 방을 사용하세요.
- STUN은 직접 연결을 시도합니다. 대칭 NAT·기업 방화벽에서는 TURN 중계가 필요할 수 있습니다. 이미 운영하는 TURN이 있을 때만 `TURN_URLS`와 `wrangler secret put TURN_SECRET`을 설정하세요. TURN은 별도 대역폭과 비용이 발생할 수 있으며 기본 구성에는 없습니다.
- WebRTC는 DTLS/SCTP로 전송을 암호화합니다. 호스트 권한 검증은 이동·사격·장비 요청 변조를 제한하지만, 방장이 자신의 프로그램을 변조하는 것을 차단하는 상용 안티치트는 아닙니다.

공식 문서: [무료 한도](https://developers.cloudflare.com/durable-objects/platform/pricing/), [WebSocket hibernation](https://developers.cloudflare.com/durable-objects/best-practices/websockets/), [STUN/TURN](https://developers.cloudflare.com/realtime/turn/).
