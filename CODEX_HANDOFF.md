# Internal N Crush — 1.1.1 인계

2026-09-24. 실제 공개 버전·소스 커밋·빌드·ZIP 해시는 PUBLICATION_STATUS.json이 기준이다. 1.1.1 Windows·NAS ZIP과 웹 게시 및 공개 파일 검증을 완료했다. 최종 빌드 소스68936ba, 게임 런타임7095c48, 사이트83b7ef4.

## 위치와 빌드

- 게임 저장소 D:/python_workplace/InternalNCrush/InternalNCrush → Nukcanon/InternalNCrush main.
- 사이트 저장소 D:/python_workplace/InternalNCrush/site-repository → Nukcanon/nukcanon main.
- game/: 공통 게임·아트·검사. windows/: Windows 빌드/실행 검증. web/: 경량 웹 스테이징/패키징. nas/: Linux/NAS Docker 설정 CMD. services/directory/: 가벼운 방 목록·연결 신호 서버. services/cloudflare-directory/: 무료 Workers 대안. services/matchmaker/: 이전 전용 프로세스 구조의 참고 자료.
- Godot4.4.1 및 gh는 바깥 .tools 폴더. 서버 Python은 .tools/server-venv/Scripts/python.exe. 토큰/개인 환경 파일은 출력하거나 게시하지 않는다.
- prepare_assets.py → editor import → build_models.gd → build_arenas.gd → editor import → Windows export. 맵 전체 상태/경로 캐시 REVISION114. 충돌/지형 변경 시 32개를 다시 굽는다.
- 웹 스테이징은 editor/import/use_multiple_threads=false로 가져온다(첫 Linux CI의 글꼴 병렬 가져오기 heap abort 방지). 웹은 Pillow 설치 후 web/prepare_lightweight.py → web/staging/game import → tools/lightweight_models.gd → Web export → web/package_web.py. 원본 game/ 모델·텍스처를 경량화하지 않는다. 웹 캐릭터/지형 시각 메시만 줄이며 충돌/경로는 유지한다.

## 이번 변경

설치는 F/G로 반투명 미리보기, 빨간 무효 위치, 클릭 확정. 포탑은 .5/.65/.82/1. 크기의 4단계, 아군 소유 포탑 근처 F 강화, 자동60도/맵 크기 연동 사거리. TETHER 원격은 자동 각/범위 제한을 벗어나 조준하되 탄환은12–48m에서100→10%로 감쇠한다.4단계 미사일은2초 간격/18m/s/직격30/반경2.4m. 목표 획득·업그레이드 지연과 재사용 제한이 있다.

중간 기본에서 AA/추가 광원/그림자를 끄고, 높음에서 켠다. 모바일 첫 실행은 낮음. 모든 캐릭터에 1인칭 총을 생성하던 중복 작업 제거, 전체 지형/내비게이션 캐시, 웹 전용512텍스처/낮은 폴리곤/작은 폰트. Windows와 WebGL은 GPU 렌더링 확인. 브라우저/OS의 GPU 선택을 강제로 바꿀 수는 없다.

발 IK 이전에 애니메이션을 평가하고 네트워크 보행 위상을 부드럽게 추종한다. 살아 있는 물리 보조는 높은 Windows 품질의 가까운 2명만, 나머지는 관성·IK. 앉기/점프/착지와 팔 두께 1.85배, 정찰병 목 3cm/밀착 칼라 보완. 장비 미리보기는 화면 높이에 비례한 220–380 기준, 병과 6개/장비 탭 5개는 폭에 따라 배치. 예약 적용은 창을 닫고 무한 부활 모드에는 사망 −25점 즉시 적용을 추가했다.

기동 5초 + 3초 회복, 감지 4초/쿨타임 40초/최소 35m 또는 맵 대각선의 1/4, 표식 6초/피감지 알림, 방호 6초 및 이동 감속, 둔화 11m/65%, 메딕 4초 무적(30m 이내 아군 지정 또는 F 두 번으로 자신). 낙하 9m까지 피해 0, 12.6m에서 피해 40, 방어구 무시/물·무적 면제. 원뿔/타이어/책상 실제 충돌·가벼운 물체 밀기, 킬/힐/지원/설치 점수. 킬캠 공격자 초상 2초와 포탑 전방 시점, 근거리 피해자 관통 방지.

설치해체는 별도 스폰 슬롯, 팀별 보호 경계. 수비는 준비 중 이동, 공격은 준비 종료 후 이동. 상대 스폰은 항상 출입/사격 차단, 아군 이동은 허용. 봇 이동 검사는 사격 차폐를 재사용하지 않는다. 12개 맵 × 공수 교대 × 두 팀의 실제 출구 48개 검사 통과. 무의미한 고립 문은 제거했고 남은 문은 상부를 채웠다.

폭탄은 공격팀 한 명 무작위 운반, 사망/이탈 드롭, 공격팀만 E 회수, 한 사이트만 설치. 120/150초, 기본 해체 30초/400크레딧 키트 10초(가젯 대체). 폭발 반경 min(30m, 맵 짧은 변/5), 굉음/범위피해. 경고음 28m/4단계 가속, 밝은 적색 점멸, 해체 작업음, 모든 참가자에게 영어 설치·투하·해체 완료 음성과 한국어 안내. 타이머 0 하한. 거점 이름·화살표·테두리는 점령 팀 색, 폭탄 사이트는 설치 상태 비노출. 장식방향문구 제거.

## 검증

소스 7095c4871b9f78d8c9a0f69856c374cd9f128dbd. 로컬 기능 3,229/3,229, 터치 20/20, 32명 독립 참가, ENet 재접속·부활·물체·문·공수 순환, 실제 WebRTC 통과. 로컬 ZIP 및 최종 공개 CI ZIP의 Windows 실행 4모드와 해당 EXE/PCK의 WebRTC 통과. 검사는 기존 사용자 프로세스를 종료하지 않고32888 등 별도포트, --no-save-profile을 사용한다. Python은 PYTHONUTF8=1.

IAB 1280×720, 7봇+방장 60FPS 표본, ANGLE NVIDIA RTX 4080 SUPER D3D11. 웹 파일 약 85MB(기존 140.67MB). Windows 중간 8인 평균 3.35ms/P95 5.33ms, 32인 평균 7.32ms/P95 12.28ms. 최대89.9/142ms 지연 및 종료 시 OpenGL 텍스처 경고는 남아 있다. 정확한 수치·범위는 game/docs/TEST_REPORT.md. 이전 검증은 TEST_REPORT_V110.md.

## 접속 구조와 남은 범위

Windows UDP LAN 27888/27889는 평문이다. 웹은 UDP 검색을 못 하므로 WebRTC 호환 로비를 사용한다. 같은 외부 IP 그룹의 LAN 목록은 공유 NAT에서 다른 사용자도 포함할 수 있다. NAS/Linux/Worker는 목록·입장·연결 신호를, 방장 Windows/브라우저는 전투 계산을 처리한다. 방장 퇴장 시 경기는 종료되며 자동 이전은 없다.

HTTPS/WSS·일회용 입장·빈도/크기 제한·WebRTC 암호화가 적용되지만 변조된 방장이나 에임봇을 모두 막지는 못한다. 일부 NAT는 TURN이 필요하다. 공용 Workers는 계정 인증이 없어 아직 미배포이며 lobby_defaults.json의 URL은 비어 있다. GitHub Pages는 정적 게임 파일만 제공한다. 실제 배포 후 /health 및 HTTP/WS를 검증한 주소만 기본값으로 넣는다. NAS 공개 ZIP에는 .env를 포함하지 않는다.

실제 내장 GPU, 휴대폰/iOS Safari, 다른 PC 간 외부 WAN, ARM64 NAS, 장시간 32인 경기와 사람 간 경쟁 승률은 미검증이다. 과거 Linux CI에서 한 번 발생한 간헐 접속 끊김은 이후 반복 검사에서는 재현되지 않았지만 장시간 추적 대상이다. AAA 아트·모션캡처·상용 안티치트·MMR·운영 완료라고 보고하지 않는다. 공개 확인 후 인계 문서와 상태 JSON을 저장소 및 바깥 작업 폴더에 함께 갱신했다.

## 최종 게시 확인

GitHub 빌드35994021257, Docker/Worker35992058167, Pages35996339880 성공. 공개 웹19파일85,274,849bytes 전체 해시 일치. 공개 Windows ZIP119,687,436bytes의 4모드 및 WebRTC 실행 확인. NAS ZIP15,364bytes 익명 다운로드 해시 일치. 공개 브라우저에서1.1.1 메뉴·연습장 진입, 오류/경고 로그 없음. 해시는 PUBLICATION_STATUS.json 참고.
