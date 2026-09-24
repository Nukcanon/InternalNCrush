# Internal N Crush — 1.0.4 인계

2026-09-24. 공개 상태/커밋/CI/ZIP 해시는 PUBLICATION_STATUS.json이 기준이다. 이전 확정 자료는 game/docs/*V103*에 보존했다.

## 위치

- 게임 Git: D:/python_workplace/InternalNCrush/InternalNCrush → Nukcanon/InternalNCrush main
- 사이트 Git: D:/python_workplace/InternalNCrush/site-repository → Nukcanon/nukcanon main
- 공통 소스 game/ (games/relaystrike/에서 이동), Windows 진입점 windows/, Docker Linux/NAS nas/, 서비스 services/matchmaker/.
- Godot D:/python_workplace/InternalNCrush/.tools/godot/Godot_v4.4.1-stable_win64_console.exe; gh .tools/gh/bin/gh.exe; API 가상환경 .tools/server-venv/Scripts/python.exe. 인증 정보는 출력하지 않는다.

## 이번 구현

AuthoredHuman + bake_human.py: CC0 MakeHuman 기반 인체, 남녀 형태/15본 웨이트, 의복 표면·얼굴·피부/직물 셰이더. 기존 키/여성2/왼손12% 유지. OperatorSkin은 빌드 시 굽고 ImporterMesh로 거리 LOD를 만든다. 원본 데이터·커밋·해시·CC0는 game/assets/human/. 애니메이션은 기존 IK/관성/관절 스프링을 연결했다. 1인칭 WeaponHand는 원본 연속 관절 손가락/손목/팔이며 역방향 꺾임을 제한한다.

LanLobby/GraphicsOptions/HudLayout/HudPreview/AmmoPips/StartupNetworkAccess 분리. 큰 LAN 목록/IP 암호 모달, 고정 버튼 최대3/행, 이동 확인, 봇 배경 보존. 메인 플레이/연습 직접 버튼. 전체 화면의 선택 렌더 해상도, MSAA 최대8×/그림자/장식/FPS, HUD80%/농도38%와 미리보기, 탄환·예비 탄창 아이콘, 글꼴/팀색/정렬, B 병과/장비, 장비창 HUD 숨김. 시작 시 5초 임시 ENet 수신; Windows 정책/경로에 따른 허용 저장이며 강제 방화벽 규칙은 없다.

저격5종 피해/간격 너프, 25개 무게/안정성/휴대성별 빠른 점사 회복, 봇 정지/횡이동·난이도 반동 제어. PhysicsRagdoll은 피격 부위에 힘, 평지 약1–3m 감쇠, 중력/충돌/관절 유지. KillReplay는 마지막 탄환 추적·피해자 전방 정지·0.5초 비행·공격자 닉네임. 포탑 구동부/총열/탄약함/지지대와 설치 엄폐물 구분.

기존 32맵(31경쟁+4층연습), 규모별사각외곽2, 설치해체8인6개/12인6개, 무작위순환/무한/정원검증, 힐/폭발/혈흔/문/슬라이딩/서버권한·WSS 등은 유지했다. 상세 반영표 game/docs/REQUEST_STATUS.md, 수치 BALANCE_NOTES.md, 검증 TEST_REPORT.md, 출처 ART_SOURCES.md.

## 재현과 주의

prepare_assets.py → Godot editor import → tools/build_models.gd → import. GPU에서 tools/build_thumbnails.gd 후 import(52개). 모델 .scn은 Git 제외, CI 재생성. 인체 변경은 tools/bake_human.py와 assets/human/manifest.json 해시를 함께 갱신. .tools/tune_v104.py는 이전 HEAD:games/relaystrike를 기준으로 한 일회성 보조 도구로 이름 이동 커밋 후 재실행하지 않는다.

GODOT 지정 후 game/tests/run_functional.py, 네트워크 run_network_*.py 직렬. 로컬 사용자 1.0.3 EXE가 27888을 사용 중일 수 있으니 **사용자 프로세스를 종료하지 말고** 테스트 INC_TEST_PORT=29888 등으로 분리한다. 테스트 소유 프로세스만 확인 후 종료. Native tests: test_lobby_menu, windows_display, visual_human_v104, visual_hands_v104, visual_release_v104, benchmark_v104. Docker 실제 확인은 GitHub Actions Linux에서 수행한다.

과거 문서/음원 출처 URL, 구형 프로필 마이그레이션과 LAN wire token의 RelayStrike는 호환/출처 기록이다. 활성 소스 경로는 game/로 통일했다. 공개 사이트는 기존 URL과 플레이 가이드/멀티플레이 접속 두 섹션을 유지한다.

## Windows EXE 접속 검사에서 추가 수정

초기 후보 b489444는 Windows 그래픽 클라이언트에서 메뉴 종료 후 `Node not found ... SubViewport` RPC 오류가 나서 게시하지 않았다. menu_demo.gd 종료 시 공유 MultiplayerAPI를 배경 경로에 재등록하던 것을 `set_multiplayer(null, multiplayer_path)`로 바꿨다. 수정 소스는 2bcb5d9이며, 화면 없는 서버/일반 방장과 그래픽 클라이언트 조합 모두 로컬 소스 실행에서 통과했다. headless CI에도 실제 메뉴 생성/제거를 두 번 실행하는 4개 회귀 검사를 추가했다.

Windows 릴리스 headless 로그는 종료까지 버퍼에 남으므로 SERVER_READY 파일 문구만 기다리면 준비 검사에서 잘못 시간 초과가 날 수 있다. windows/verify_build.py는 테스트 프로세스 소유 UDP 소켓으로 준비를 확인하고, ZIP의 EXE 자체로 연습장·봇 전투·두 종류 방장 접속을 검사한다. 이 도구는 이전 후보 ZIP의 RPC 오류를 실패로 잡는 오류 재현 검사도 통과했다. 이전 후보 증거는 validation/release-v104-pre-rpc-fix-b489444/, 최종 ZIP/로그/검증 결과는 validation/release-v104/에 보존한다.

## 남은 품질/운영 과제

실제 사람 경쟁전/다중 PC·NAS ARM64·저사양·장시간 32인, 프레임 급증·간헐적 종료 GL texture 경고, 새 Windows의 최초 방화벽 팝업 실측. CC0 인체 교체는 구현했으나 모션캡처/수작업 AAA 완성을 주장하지 않는다. LAN ENet은 평문, 인터넷은 검증된 WSS. 클라이언트에 모든 상대 위치가 전달되어 벽핵/에임봇 방지를 완성한 상태가 아니다. 계정/MMR/영구 제재/시야 정보 제한/행동 탐지/분산 운영과 운영자 도메인/서버가 필요하다.

## 확정 게시 결과

1.0.4 소스 `2bcb5d98f3f127e92320e2c0bb7456b387d1d6c9`; Windows CI 35954374716, Docker CI 35954374710 성공. 기능 2,381/2,381, API 10/10, 실제 UI 50/50, 두 모니터 여섯 표시 방식 확인. 실제 배포 EXE의 연습장·봇전투·EXE 간 접속과 익명 다운로드 해시 확인.

ZIP 65,050,596바이트 / 13파일 / SHA-256 `841589a1e92345a6f6f97f3e6cd89d518607d7ba4b9b62beefa1f8de0332a14a`. 사이트 커밋 `af194c1c72251f4490fb026048dea406ecfe8a6b`, Pages 35955684842 성공. 자세한 결과와 성능 표본은 game/docs/TEST_REPORT.md 및 PUBLICATION_STATUS.json. 마지막 턱/옷깃 경계 수정, 썸네일 재생성, Python 네트워크 포트 사전 검사에도 INC_TEST_PORT 적용 완료. 검증 파일은 validation/release-v104/.
