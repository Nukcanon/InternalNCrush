# 무료 방 목록 서버 · Cloudflare Workers

## 배포된 공용 로비

https://internal-n-crush-lobby.internal-n-crush-directory.workers.dev

웹 온라인 로비와 Windows 인터넷 로비의 기본 주소입니다. 빈 주소를 쓰던 프로필은 기본 주소를 받으며, 사용자가 지정해 둔 주소는 유지합니다. 메뉴를 열면 자동 연결합니다. 1.3.5부터 게임은 하나의 `internet` 방 목록만 사용합니다(‘같은 네트워크의 방’ 제거).

## 버전 정책

- 세션은 클라이언트의 게임 버전을 기록하고, 방 목록·빠른 참가·입장은 **같은 버전끼리만** 이루어집니다.
- `wrangler.jsonc`의 `MIN_GAME_VERSION`보다 낮은 버전은 “새 버전으로 업데이트하세요” 안내와 함께 거부됩니다. 현재 값은 1.3.5입니다.
- 새 게임 버전을 출시해도 워커를 다시 배포할 필요가 없습니다. 이전 버전의 온라인 접속을 막고 싶을 때만 `MIN_GAME_VERSION`을 올려 main에 푸시하세요.
- main에 이 폴더가 바뀌어 푸시되면 `.github/workflows/deploy-lobby.yml`이 저장소 시크릿 `CLOUDFLARE_API_TOKEN`·`CLOUDFLARE_ACCOUNT_ID`로 자동 배포하고 `/health`의 `min_version`을 확인합니다.

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
python services/directory/check_live.py https://배포된주소 --version 1.3.5
```

Python 검사 명령은 저장소 루트 기준이며 `services/directory/requirements.txt`가 필요합니다. `--version`에는 `MIN_GAME_VERSION` 이상인 현재 게임 버전을 넣습니다. URL이 확정되면 `game/assets/lobby_defaults.json`의 `url`을 업데이트하고 게임을 다시 빌드할 수 있습니다.

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
- Windows 내부망 로비(UDP 브로드캐스트)는 이 서버와 별개이며 게임끼리 버전을 직접 비교합니다.
- STUN은 직접 연결을 시도합니다. 대칭 NAT·기업 방화벽에서는 TURN 중계가 필요할 수 있습니다. 이미 운영하는 TURN이 있을 때만 `TURN_URLS`와 `wrangler secret put TURN_SECRET`을 설정하세요. TURN은 별도 대역폭과 비용이 발생할 수 있으며 기본 구성에는 없습니다.
- WebRTC는 DTLS/SCTP로 전송을 암호화합니다. 호스트 권한 검증은 이동·사격·장비 요청 변조를 제한하지만, 방장이 자신의 프로그램을 변조하는 것을 차단하는 상용 안티치트는 아닙니다.

공식 문서: [무료 한도](https://developers.cloudflare.com/durable-objects/platform/pricing/), [WebSocket hibernation](https://developers.cloudflare.com/durable-objects/best-practices/websockets/), [STUN/TURN](https://developers.cloudflare.com/realtime/turn/).

