# Internal N Crush — 1.1.1 작업 인계

1.1.1은 로컬 구현·검증 중이며 공개 버전은 아직 1.1.0이다. 최신 변경과 확인한 범위는 game/docs/WORK_1_1_1.md, 실제 배포 상태는 PUBLICATION_STATUS.json을 확인한다.

새 웹 빌드는 web/prepare_lightweight.py → staging import → tools/lightweight_models.gd → Web export 순서로 만든다. Windows 원본을 경량화하지 않는다. 전체 지형/경로 캐시는 ArenaCache REVISION114이며 충돌 변경 시 다시 굽는다. 기능검사에 test_v111, test_abilities_v111, test_spawn_exits가 추가되었다.

아래는 이전 공개 버전의 검증 이력이다.

# Internal N Crush — 1.1.0 인계

2026-09-24. **실제 게시 버전·소스 커밋·CI·ZIP 해시는 PUBLICATION_STATUS.json을 기준으로 판단한다.** 이 문서의 구현 설명만으로 배포 완료를 추정하지 않는다. 이전 검증/반영표는 game/docs/*_V104.md에 보존했다.

1.1.0 Windows/Web/NAS 파일 게시 및 공개 파일 해시 검증 완료. 기능 3,051/3,051, 터치 20/20. 공용 로비는 계정 인증 대기이며, 실제 휴대폰과 간헐 접속 끊김의 장시간 추적은 남아 있다.

## 작업 위치

- 게임 저장소: D:/python_workplace/InternalNCrush/InternalNCrush → Nukcanon/InternalNCrush main
- 사이트 저장소: D:/python_workplace/InternalNCrush/site-repository → Nukcanon/nukcanon main
- game/: 공통 코드·아트·물리·테스트. windows/: Windows 빌드/검사. web/: GitHub Pages용 내보내기. nas/: Linux/NAS 설정 CMD·Compose.
- services/directory/: 방 목록/입장/신호용 Python 서비스. services/cloudflare-directory/: 같은 계약의 무료 Workers 구성. services/matchmaker/: 기존 전용 프로세스 방식 참고 자료, 새 배포에서 사용하지 않음.
- Godot: D:/python_workplace/InternalNCrush/.tools/godot/Godot_v4.4.1-stable_win64_console.exe. gh: .tools/gh/bin/gh.exe. 서버 Python: .tools/server-venv/Scripts/python.exe. 계정·토큰은 출력하지 않는다.

## 이번 구현과 제한

UI는 원본 픽셀 해상도이며 3D만 선택 해상도로 낮춘다. MSDF 글꼴, 작은 반투명 메뉴, 공통 고정 버튼, 연습장 이동 확인을 적용했다. 유혈 효과는 기본 꺼짐이며 켜고 끌 수 있다. 기본 걷기/달리기 3.2/6.2m/s에 무기 배율을 적용한다.

MakeHuman CC0 UV 피부 4종과 자체 생성 미세 표면(피부/직물/가죽/머리카락), 붉은 피부색 완화, 기울어진 어깨/여성 어깨 너비/모자 피팅, 연속 손·팔과 손목 축, 탄창별 재장전, 총기 끝면 폐쇄를 적용했다. 출처·저작자·해시·CC0와 생성 프롬프트는 assets/human 및 assets/textures의 manifest/provenance에 있다. 외부 MakeHuman 프로그램 코드는 포함하지 않는다.

AnatomicalHit는 관절을 따라가는 구체/캡슐로 머리/몸통/팔다리를 판정하고 장식품·빈 공간을 제외한다. 권한 서버의 가벼운 관절/총 소켓은 표시 모델의 양손/재장전 소켓과 검사한다. 수신 전용 headless 피어는 이 계산을 중복하지 않는다. 시체는 월드 충돌만 허용해 자기·총·장구류에 의한 떨림을 줄이고 안정 후 정지한다.

SurfaceCleanup+PlanarCleanup은 축 정렬 및 회전 공면을 정리한다. **build_arenas.gd로 32개 지형을 미리 구워야 한다.** 저장 전후 충돌 형태/위치/축/레이어를 비교하며, 런타임은 결정적으로 생성한 이동/목표/동적 물체 정보와 구운 정적 지형을 결합한다. 누락된 캐시는 런타임 정리로 돌아가지만 큰 맵 로딩이 길어질 수 있다. 지형/재질 소스 변경 시 모든 캐시를 다시 굽는다. Compatibility 고정 광원 11 + 일시 광원 5가 오브젝트당 16 제한에 들어가도록 했으며 그림자 단계 전환도 보완했다. 모든 GPU의 깜빡임을 완전히 보증하는 것은 아니다.

웹은 WebGL2·단일 스레드, 약 140MB 최초 파일. 스마트기기만 가상 스틱·드래그 조준·발사·재장전·스킬·가젯·장비 타일을 사용하고 기본 품질을 낮춘다. PC에는 이 버튼을 표시하지 않는다. 앱/창 포커스를 잃거나 일시 중단되면 가상 입력을 초기화해 이동/발사가 붙는 현상을 막는다. 브라우저 포인터 고정은 클릭 콜백에서 요청하며, 고정을 제한하는 내장 브라우저에는 키보드/클릭 발사/드래그 조준 대체 동작이 있다.

## 접속 구조

Windows 기본 LAN은 UDP 27888/27889이며 평문이다. 웹은 UDP 검색을 할 수 없으므로 **웹 호환 로비**로 Windows와 같은 WebRTC 방에 참가한다. 웹 LAN 목록은 같은 외부 주소 그룹이며 공유 NAT에서는 다른 사용자도 같은 그룹일 수 있다.

NAS/Linux/Worker는 방 목록·매칭·입장 승인·WebRTC 연결 신호만 처리한다. 전투 계산은 방장 Windows/브라우저가 담당한다. 방장 퇴장 시 방은 종료되며 자동 이전은 없다. 방 이름/모드/인원/최대 핑 검색과 이름/핑/인원 정렬을 지원한다. 목록 핑은 추정, HUD는 실제 연결 왕복이다.

HTTPS/WSS 검증·단기 일회용 입장·크기/빈도 제한·호스트↔참가자 라우팅과 WebRTC 암호화를 적용했다. 입력 권한 검증이 변조된 방장/에임봇/메모리 분석을 모두 차단하지는 않는다. 일부 NAT에는 별도 TURN이 필요하며 이를 자동 구매/설정하지 않았다.

Cloudflare 계정 로그인이 없어 공용 서버는 미배포이고 game/assets/lobby_defaults.json의 url은 비어 있다. 인증 후 services/cloudflare-directory/README.md대로 배포하고 실제 /health·HTTP/WS 검사에 통과한 주소만 기본값으로 넣는다. GitHub Pages는 실시간 방 목록 서버를 실행할 수 없다.

NAS 공개 ZIP은 .env 없이 .env.example만 포함한다. 사용자가 01_설정.cmd로 만든 업로드 ZIP은 운영자 설정을 포함할 수 있으므로 관리자용이다. 예시 SchoolAssignmentServer ZIP은 읽기만 했고 실행하거나 그 프로그램을 복제하지 않았다.

## 재현 및 검증

준비: Python game/tools/prepare_assets.py → Godot headless editor import → tools/build_models.gd → tools/build_arenas.gd → editor import → Windows/Web export. windows/build.ps1와 GitHub Actions가 이 순서를 수행한다. Web 산출물은 web/package_web.py로 파일 크기/단일 스레드/라이선스/해시를 검증한다.

GODOT 환경 변수 지정 후 game/tests/run_functional.py, run_network_capacity.py, run_network_probe.py, run_network_lifecycle.py, run_network_props.py, run_network_rotation.py, run_network_rtc.py. test_touch.gd에는 --touch-test --no-save-profile --no-update-check를 준다. 실제 EXE는 windows/verify_build.py로 ZIP에서 꺼내 검사한다. windows/verify_webrtc.py는 해당 EXE/PCK를 명시해 WebRTC 접속을 검사하며 최종 CI 배포본 양쪽 연결을 확인했다. Docker/Worker는 .github/workflows/matchmaker.yml이 실제 Linux 컨테이너·공식 Worker 런타임을 검사한다.

사용자가 실행 중인 기존 게임이나 해당 포트는 종료하지 않는다. 검사는 INC_TEST_PORT=32888 등 별도 포트와 자신이 시작한 프로세스만 사용한다. Python 출력은 PYTHONUTF8=1. 새 빌드 검증 후 릴리스 게시→사이트 Pages→공개 파일 해시/브라우저 실행 순서로 확인하고 이 문서와 PUBLICATION_STATUS를 저장소 및 바깥 작업 폴더에 함께 갱신한다.

## 남은 검증

실제 휴대폰·태블릿(iOS/Safari 포함), 서로 다른 PC/외부 WAN, NAS ARM64, 저사양·장시간 32인 경기와 사람 경쟁전 승률은 미확인이다. Compatibility 종료 때의 소수 GL texture 경고와 간헐 프레임 급증이 남아 있다. 짧은 RTX 4080 SUPER 표본은 모바일 성능 보증이 아니다. AAA 수준 아트 평가, 모션캡처, 상용 안티치트·MMR·계정·지속 제재·DDoS 운영 완료로 보고하지 않는다.
