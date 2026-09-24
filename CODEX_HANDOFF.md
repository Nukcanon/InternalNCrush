# 1.1.3 진행 상태

로컬 기능25묶음 3,525/3,525 통과. GPU 실루엣 차폐/비차폐/비권한 사용자 검사 통과. 웹 모델/재질/소품 묶음 경량화 및 자동 해상도 변경 제거. 현재 공개본은 아직1.1.2이며 아래 기록은 이전 공개본이다. 최종 빌드/게시 검증 후 갱신한다. 최신 변경은 RELEASE_NOTES.md와 web/README.md 참조.

# Internal N Crush — 1.1.2 인계

최종 공개 버전·소스 커밋·빌드·ZIP 해시는 PUBLICATION_STATUS.json이 기준이다. 2026-09-25(KST), 1.1.2 Windows/NAS ZIP과 웹 게시 및 공개 파일 검증을 완료했다. 이전 1.1.1 검증은 game/docs/TEST_REPORT_V111.md에 보존했다.

## 위치와 빌드

- 게임 저장소 D:/python_workplace/InternalNCrush/InternalNCrush → Nukcanon/InternalNCrush main.
- 사이트 저장소 D:/python_workplace/InternalNCrush/site-repository → Nukcanon/nukcanon main.
- game/: 공통 게임·아트·검사. windows/: Windows 빌드/실행 검증. web/: 경량 웹 스테이징/패키징. nas/: Linux/NAS Docker 설정 CMD. services/directory/: 가벼운 방 목록·연결 신호 서버. services/cloudflare-directory/: 무료 Workers 대안. services/matchmaker/: 이전 전용 프로세스 구조의 참고 자료.
- Godot4.4.1 및 gh는 바깥 .tools 폴더. 서버 Python은 .tools/server-venv/Scripts/python.exe. 토큰/개인 환경 파일은 출력하거나 게시하지 않는다.
- prepare_assets.py → editor import → build_models.gd → build_arenas.gd → editor import → Windows export. 맵 전체 상태/경로 캐시 REVISION115. 충돌/지형 변경 시 32개를 다시 굽는다.
- 웹 스테이징은 editor/import/use_multiple_threads=false로 가져온다(첫 Linux CI의 글꼴 병렬 가져오기 heap abort 방지). 웹은 Pillow 설치 후 web/prepare_lightweight.py → web/staging/game import → tools/lightweight_models.gd → Web export → web/package_web.py. 원본 game/ 모델·텍스처를 경량화하지 않는다. 웹 캐릭터/지형 시각 메시만 줄이며 충돌/경로는 유지한다.

## 1.1.2 변경

웹은 256px 텍스처와 별도 경량 메시·단순 재질을 사용하고 추가 광원·그림자·AA를 끈다. 3D는 별도 공유 월드 SubViewport로 PC 최대 높이540/터치432에서 성능에 따라288까지 조절하며 UI는 원본 해상도를 유지한다. 메뉴 봇 배경은 작은 렌더 타깃/15FPS이다. 원본 Windows 에셋은 웹 경량화에 영향을 받지 않는다. 터치 시점은 손가락별 좌표 차이로 계산하고 좌표계 변경·비정상 델타를 거른다.

여성 어깨 관절7cm 상승 및 쇄골/삼각근/상완 연결 수정, 리그·피격 관절 동기화, 관련 썸네일 갱신. 조명 기둥 전체 부피가 계단·상층 바닥과 겹치는 배치를 제외하고 캐시115로32개 맵을 다시 생성했다. 모든 가능한 맵 시점에서 겹침이 없다는 보장은 아니다.

봇 전투 기본7명, 시작 전 병과·무기 선택, 좁은 일시정지 창, 비조준 휠 무기 전환. 폭탄 설치/해체는 실제 E 길게 누르기와 위치 안내를 맞췄다. 즉시 사망 후 장비 변경은 StringName 명령 키가 서버에서 거절되던 오류를 고쳤고 실제 버튼부터 확인했다. 재장전 시간은 유지하면서 후반30%에 노리쇠/슬라이드 조작을 추가하고 손잡이 방향을 반영했다.

포탑은 소유자 사망 시 파괴되고 부활하면 스킬/가젯 쿨타임이 초기화된다. 자동 탐지각100도, 높이가 다른 대상도 노출된 가슴/머리/골반을 확인한다. 실제 벽/연막 차폐는 유지한다. 봇도 적 포탑을 사격한다. 본인 설치물은 팀 색 단색 투시 실루엣으로 표시하며 강화/설치 쿨타임을 분리했다. 미사일18→30m/s, 피해30·2초 간격 유지. 포탑 사격 중 다른 포탑 소유자가 죽어 장치가 제거되는 경우도 처리한다.

저격 SCOUT4/8배(기본4), MONOLITH4/8/16배(기본8). 조준 중 휠·모바일±, 총별 마지막 배율 저장, 저격 마우스/터치 독립 감도. 지정사수 배율은 기존 값을 유지한다. 저격/지정사수 스코프 지름은 화면 높이72%→98%. 발사 원점은 조준 진행에 따라 가슴 아래→눈 가까이로 이동하며 눈-총구/총구-표적 차폐 검사도 유지한다.

감지파동4초/표식6초 팀 공유 실루엣, 사망·정화·만료 시 해제, FFA는 본인에게만 공유. 표식기는 장착 상태에서 스코프 중앙에 가장 가까운 가시 적1명을1초 연속 추적하여 자동 발동한다. G로 설치/소모하지 않는다. 줌을 풀거나 대상이 바뀌면 누적이 초기화되고 해체 키트로 가젯을 바꾸면 표식이 비활성화된다. 서버가 배율 입력과 대상 시야/연막을 검증한다.

## 검사 및 게시 절차

최종 소스4cadd346ddc5c5a65aff18bd328f4d732f3bce98, 런타임abd23c4217399801b080fb6d934e6dd8b1a300c9. Windows/Web 빌드36021490283, Docker/Worker36021490335. 이전 빌드36019700822의 실패는 수동 표식기 소비를 기대하던 오래된 AI검사1개였으며 자동 추적 방식으로 수정했다.

최신 전용260/260, AI38/38, 터치23/23, 입력보안40/40, 웹 충돌 일치32/32와 로컬 실제 WebRTC 통과. 최종 CI 기능3489/3489, 배포 ZIP Windows4모드와 해당 EXE/PCK WebRTC 통과. 공개19파일74,221,457bytes 해시 일치. Windows ZIP119,709,287bytes와 NAS ZIP15,343bytes를 익명 다운로드해 해시를 확인했다. Pages36024974346, 사이트7c804ffb94573e27cdb964a4cf0ffe0184eb16cc. 공개 브라우저1.1.2 메뉴·연습장 실행 및 오류/경고 없음 확인. 세부 결과는 TEST_REPORT.md와 상태 JSON을 참조한다. push 빌드는 릴리스 게시 단계를 건너뛰므로 성공 아티팩트를 검증한 뒤 gh release로 올린다. 게시 후 소스/사이트 문서 커밋은 [skip ci]로 남긴다.

## 접속 구조와 검증 한계

Windows UDP LAN27888/27889는 평문이다. 웹은 UDP 검색을 못 하므로 WebRTC 호환 로비를 사용한다. NAS/Linux/Worker는 목록·입장·연결 신호만 처리하고 방장 Windows/브라우저가 전투를 계산한다. 방장 이탈 시 경기는 종료되며 자동 이전은 없다. 같은 외부 IP 기반 LAN 그룹에는 공유 NAT 사용자가 포함될 수 있다.

HTTPS/WSS·일회용 입장·입력/빈도/크기 제한·WebRTC 암호화가 있지만 변조 방장과 에임봇을 완전히 막지 못한다. 일부 NAT는 TURN이 필요하다. 공용 Workers는 계정 인증이 없어 미배포이며 기본 로비URL은 비어 있다. GitHub Pages는 정적 게임만 제공한다. 실제 운영 주소의 /health 및 HTTP/WS 검증 후에만 기본값을 넣는다. NAS ZIP에는 운영자 .env를 포함하지 않는다.

웹 RTX4080SUPER 7봇+방장57FPS 표본만 확인했다. GTX960·내장GPU·실제 휴대폰/iOS·외부PC WAN·ARM NAS·장시간32인·사람 경쟁 승률은 미검증이다. 첫 로딩 지연과 종료 시 Compatibility GL 텍스처 경고는 남아 있다. 과거 Linux CI의 간헐 접속 끊김은 후속 반복 검사에서 재현되지 않았으나 장기 추적 대상이다. AAA 아트·모션캡처·상용 안티치트·공용 서버 운영을 완료했다고 보고하지 않는다.
