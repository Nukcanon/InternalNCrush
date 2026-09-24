# Internal N Crush — 1.0.3 인계

2026-09-24. 공개 상태/커밋/CI/다운로드 해시는 PUBLICATION_STATUS.json이 기준이다. 1.0.2 자료는 games/relaystrike/docs/*V102*에 보존했다.

## 위치와 도구

- 게임 Git: D:/python_workplace/InternalNCrush/InternalNCrush → https://github.com/Nukcanon/InternalNCrush
- 사이트 Git: D:/python_workplace/InternalNCrush/site-repository → https://nukcanon.github.io/nukcanon/internal-n-crush.html
- Godot: D:/python_workplace/InternalNCrush/.tools/godot/Godot_v4.4.1-stable_win64_console.exe
- gh: D:/python_workplace/InternalNCrush/.tools/gh/bin/gh.exe, Nukcanon 인증. 자격 증명은 출력하지 않는다.
- 서버 가상환경: D:/python_workplace/InternalNCrush/.tools/server-venv/Scripts/python.exe

## 구현

요청별 사실/한계는 [REQUEST_STATUS](games/relaystrike/docs/REQUEST_STATUS.md), 수치는 [BALANCE_NOTES](games/relaystrike/docs/BALANCE_NOTES.md), 검사는 [TEST_REPORT](games/relaystrike/docs/TEST_REPORT.md), 아트 생성 출처/프롬프트는 [ART_SOURCES](games/relaystrike/docs/ART_SOURCES.md).

32개 지도(기존 19, 설치·해체 12, 연습 1). 6/8/12/16/32인 규모마다 사각 외곽 두 개 정확히 유지. MapIdentity.RECTANGLES=[0,1,2,4,8,10,13,14,25,26], 연습 31은 집계 제외. 기존 0/4/10/13 평면 중심 유지. 새 전용 맵은 node/link 기반 별도 설계, 연속 폴리곤 벽/지붕, 두 공격 경로와 회전. WorldDressing은 그 진입로 중앙 2m를 비운다.

연습 31은 네 높이(0/4.2/8.4/12.6), 9개 비공격 표적, 리스폰/회복 대상/보급/B 즉시 변경. PracticeSession과 MatchFlow를 별도 코드로 분리. 방 기본은 8명/8인 무작위/무한, 짝수 인원 독립, 선택 인원 이상 지도, 같은 규모 순환. 설치·해체 최대 12명, 30/45/60초 준비, 공격 대기구역 제한과 피해 차단, 공수 한 번씩 후 순환. 점령은 기존 중립 거점의 시작 진영 교대다.

연속 SDF 의복/인체 표면, 15본 GPU 변형, 얼굴/체형/곡면 총몸, 발 접지/관성/살아 있는 관절 보조(가까운 최대 8명). 사망 11몸체 래그돌/피격 지점 충격/중력. 혈흔, 생성 연기 스프라이트의 폭발·물리 파편, 총구→몸 리본과 회복 파동, E 문 서버 상태/끼임 방지. 살아 있는 물리는 시각 보조이고 서버 이동을 밀어내지 않는다.

25개 총기의 개별 스프레이 폭/패턴 시간/회복, 속도 비례 퍼짐, DPS/재장전 포함 지속 DPS 그래프, 능력 지속·사거리·쿨타임 조정. 기존 거리 감쇠/머리·몸통·다리 높이 판정/총구 차폐/왼손 12%/여성2명/킬캠/모니터 설정 유지. UI 정렬과 투명 선택 카드. 축 정렬 동일 평면 제거와 그림자 자기 겹침 보정·밉맵 적용.

## 재현

GODOT 환경 변수 설정 후 tests/run_functional.py, run_network_probe.py, run_network_capacity.py, run_network_lifecycle.py, run_network_props.py, run_network_rotation.py를 직렬 실행한다. 테스트 Godot는 Windows 자식 프로세스도 만들므로 실패 정리 시 검증된 해당 프로세스 트리만 종료한다. API: python -m unittest services.matchmaker.test_service -v. Docker: python services/matchmaker/test_docker.py (실제 Docker 환경 필요).

models는 prepare_assets.py → Godot editor import → tools/build_models.gd → import로 빌드. thumbnails는 GPU에서 tools/build_thumbnails.gd 후 import. 새 전용 맵 편집 시 Godot tools/export_layout_specs.gd → Python tools/bake_defusal_geometry.py (개발 전용 shapely==2.1.2)로 JSON을 갱신. 런타임에는 Shapely/Blender 불필요. PNG 생성 원본은 assets/textures/에 그대로 저장. .tools/upgrade_v103_data.py는 곱셈식 일회용이므로 다시 실행하면 안 된다.

플랫폼 진입점 windows/README.md와 windows/build.ps1, nas/README.md와 compose.yaml/Caddyfile/.env.example. 공통 구현은 games/relaystrike와 services/matchmaker. NAS 운영자 도메인/서버는 제공되지 않았다. 공개 GitHub/Pages를 게임 서버로 오해하지 않는다.

## 남은 품질/운영 과제

사람 경쟁전 테스트, 외부 다중 PC/NAS ARM64·저사양/장시간 32인, 일부 프레임 급증, 간헐적 종료 GL texture 349524 bytes 경고. 수작업 AAA 모델/모션캡처/완전 안티치트라고 말하지 않는다. WSS는 암호화되고 LAN ENet은 평문이며 모든 상대 위치가 스냅샷에 있으므로 벽핵·에임봇까지 해결한 것이 아니다. 계정/MMR/영구 제재/정보 제한/행동 탐지/분산 운영은 별도 과제다.
