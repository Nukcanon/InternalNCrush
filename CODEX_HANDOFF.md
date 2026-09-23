# Internal N Crush — 1.0.2 작업 인계

작업일: 2026-09-24. 실제 공개 상태·소스 커밋·빌드·해시는 `PUBLICATION_STATUS.json`을 기준으로 확인합니다. 1.0.1 문서/상태는 `games/relaystrike/docs/*V101*`에 보존했습니다.

## 저장소와 도구

- 게임: https://github.com/Nukcanon/InternalNCrush / 로컬 `D:/python_workplace/InternalNCrush/InternalNCrush`.
- 사이트: https://nukcanon.github.io/nukcanon/internal-n-crush.html / 로컬 `D:/python_workplace/InternalNCrush/site-repository`.
- Godot 4.4.1: `D:/python_workplace/InternalNCrush/.tools/godot/Godot_v4.4.1-stable_win64_console.exe`.
- gh: `D:/python_workplace/InternalNCrush/.tools/gh/bin/gh.exe`, Nukcanon 인증 상태. 자격 증명을 문서/로그에 출력하지 않습니다.
- 서버 검사용 가상환경: `D:/python_workplace/InternalNCrush/.tools/server-venv/Scripts/python.exe`.

## 이번 구현

- `combat_balance.gd`와 27종 장비 데이터: 무기군별 피해·거리 감쇠·재발사·조준·이동·탄창·재장전·부위 배율. 샷건은 층화 산탄, 저격은 느린 조준/이동과 큰 비조준 퍼짐. 그래프/곡선 UI와 52개 실제 모델 카드. `docs/BALANCE_NOTES.md`에 수치와 공식 참고 자료를 기록했습니다.
- 사격은 시선으로 목표를 찾되 서버 총구 경로를 검사합니다. 눈은 엄폐 위를 보지만 총열은 가려진 상황에서 발사 관통이 되지 않게 했습니다. 피격 부위는 키/앉기별 캡슐 높이 구간이며 본별 히트박스는 아닙니다.
- `surface_cleanup.gd`: 건축 메시 병합 전에 겹친 축 정렬 BoxMesh의 동일 평면 면을 잘라내고 공유 면을 제거합니다. 충돌과 내비게이션은 유지합니다. 카메라 near 및 표면 패턴 안티앨리어싱도 개선했습니다. 회전/곡면 전체를 처리하는 범용 CSG는 아닙니다.
- `combat_layout.gd`: 양쪽 우회가 가능한 시야 차단 구조, 고가 통로 장벽. 16인 다층 맵 크기 축소. 실내 `[2,3,8,11,14,15]`, 야간 `[1,6,9,16,17]`. 나머지 15개 다층/규모별 평면 한 개 유지. 기본 방은 8인 map13, 서버에서도 맵 정원 초과를 제한합니다.
- `arena_lighting.gd`, `surface_finish.gd`: 카툰 장비 조명, 재질별 금속/거칠기·천/표면 질감, 주야간/실내 광원과 조명기구, 추가 현장 소품.
- `grenade_logic.gd`: 돌격 보호판 대안 파편 수류탄. G 또는 가젯 발사 누름→조리, 놓음→투척. 안전핀부터 3초, 벽 차폐·자폭·장치/물체 반응. 포탑/엄폐 파괴·폭발·연기·회복 파동·상태 효과 시각화. 메딕은 총구→몸으로 회복 광선을 연결합니다.
- `character_visual.gd`: 가감속/회전 스프링 관성·상하체 지연·달리기 팔 스윙. 더블 Shift 지상 슬라이딩. `physics_ragdoll.gd`: 11개 몸체와 관절, 피격 방향 힘, 지면 낙하, 최대 6개/6초 유지. 정지한 경우만 물리를 잠급니다.
- HUD는 병과 아이콘·원형 쿨타임·키캡, 회복탄/크레딧/장비 예약/관전 안내를 표시합니다. 사이트는 플레이/접속 안내 중심으로 유지합니다.
- 기존 1.0.1의 인체 비율·SERA/MINA·왼손 12%·슬로 모션 킬캠·모니터/해상도 제한은 유지합니다.

## Docker Linux/NAS

사용자가 선택한 공통 배포 방식입니다. `services/matchmaker/README.md`에 운영 명령/네트워크 조건/보안 경계를 기록했습니다. FastAPI 단일 워커가 방별 Godot를 실행하고 Caddy가 HTTPS/WSS를 처리합니다. 공개 목록/방 생성/선택 또는 무지정 모드 매칭, 기본 4개 방, 빈 방 정리, 6시간 익명 세션, 30초 HMAC 입장권·일회용 nonce, 내부 하트비트 차단, 입력 타입/빈도/크기 검증을 포함합니다.

전용 도메인과 서버 접속 정보는 아직 없습니다. GitHub Pages는 서버로 사용할 수 없습니다. 이 코드는 Linux/NAS 배포 구성이며 실제 외부 운영 서버를 가동했다는 뜻이 아닙니다. LAN ENet은 평문입니다. WSS는 TCP 손실 지연 특성이 있습니다. 모든 상대 위치가 현재 스냅샷에 포함되고 익명 게스트는 새 세션을 만들 수 있으므로 벽핵/에임봇/영구 제재까지 해결한 것으로 표현하지 마세요. 계정/MMR/영구 제재/시야 기반 정보 제한/행동 탐지/대규모 DDoS 운영은 후속 과제입니다.

## 재현과 검증

```powershell
$env:GODOT='D:/python_workplace/InternalNCrush/.tools/godot/Godot_v4.4.1-stable_win64_console.exe'
python games/relaystrike/tests/run_functional.py
python games/relaystrike/tests/run_network_capacity.py
python games/relaystrike/tests/run_network_lifecycle.py
python games/relaystrike/tests/run_network_props.py
& '../.tools/server-venv/Scripts/python.exe' -m unittest services.matchmaker.test_service -v
& '../.tools/server-venv/Scripts/python.exe' -m services.matchmaker.run_integration
& $env:GODOT --path games/relaystrike --script res://tests/visual_v102.gd -- --no-save-profile --no-update-check
```

네트워크 검사는 순서대로 실행합니다. Windows console Godot는 자식 EXE를 만들므로 실패 정리 시 해당 테스트 프로세스 트리만 종료합니다. 기능 검사기는 종료 코드뿐 아니라 엔진 로그 오류도 검사합니다. 썸네일은 GPU 모드에서 `tools/build_thumbnails.gd`로 생성하고 재임포트합니다.

기능 1,089개, API 단위 검사 9개, 실제 로비→전용 서버→독립 클라이언트 2개는 로컬 통과했습니다. 19개 맵과 그래프/회복/폭발/모션은 RTX 4080 SUPER Windows에서 렌더링했습니다. 공개 CI·ZIP/EXE·홈페이지 검증의 최종 결과는 아래와 JSON을 확인하세요.

## 남은 한계

실제 다중 PC/LAN/WAN, 장시간 32인 전투, ARM64 NAS, 저사양 GPU와 다양한 DPI는 별도 검증 대상입니다. 자동 경로/시야/피해 검사만으로 경쟁 밸런스를 확정하지 않습니다. 절차적 모델·IK와 관절 물리는 수작업 고급 에셋/모션캡처가 아닙니다. 일부 Godot 4.4.1 Compatibility 종료에서 `Texture with GL ID ... leaked 349524 bytes` 경고가 남으며 해결했다고 표현하지 않습니다.


## Linux TLS와 로컬 네트워크 최종 확인

- Docker CI [35893634492](https://github.com/Nukcanon/InternalNCrush/actions/runs/35893634492) 성공. Linux amd64 이미지 빌드→실제 Compose 기동→HTTPS API→Godot WSS 클라이언트 2개 입장/경기/사격/동기화 통과. 알 수 없는 CA·잘못된 호스트 이름 거부, 내부 API 경로 404 차단 확인. API 검사 9/9. 서버 검증 커밋 `4ea5a9a335b2d7e13df1f59daaf992bb6dd013e0`.
- 테스트 CA는 일회용 클라이언트 컨테이너에만 마운트했습니다. 초기화 시점/공개 인증서 읽기 권한 문제를 수정했고 TLS 검증을 비활성화하지 않았습니다. 게임/API 이미지는 비루트 사용자입니다. 초기 프록시 내부 경로 처리 순서도 실제 실패 검사에서 찾아 수정했습니다.
- 로컬 ENet: 독립 2프로세스 사망/부활/재장비/사격·손잡이·블룸, 32클라이언트 최신 상태 완료 장벽, 8인 재접속/서버 재시작, 움직이는 물체의 기존/늦은 참가 동기화 모두 통과했습니다. 샷건 탄창 감소 검사는 고정 6이 아니라 실제 무기 탄창 수에서 감소한 것을 확인합니다.
- Windows 짧은 성능 표본: RTX 4080 SUPER, 1280×720, VSync OFF, 준비 5초 후 각 12초. 8인(봇 7) map13 평균 1.553ms / P95 3.494ms / 최대 43.294ms; 32인(봇 31) map0 평균 7.182ms / P95 11.533ms / 최대 193.248ms. `process_frame` 간 벽시계 간격이며 GPU 전용 시간이나 장시간 성능 보장은 아닙니다. 최대 지연이 남아 있으므로 ‘모든 끊김 제거’라고 표현하지 않습니다. 추가 프레임 급증 프로파일링이 필요합니다.


## 1.0.2 공개 배포 검증 완료

- [정식 릴리스](https://github.com/Nukcanon/InternalNCrush/releases/tag/internal-n-crush-v1.0.2), Windows 소스 `273fafa86ef583fbae02da910ad139cd68366455`, [빌드 CI](https://github.com/Nukcanon/InternalNCrush/actions/runs/35893321606) 전체 성공. 기능 1,089/1,089 및 32클라이언트/2프로세스/8인 재접속·재시작·지연 시작/물체 동기화 검사 통과.
- 공개 ZIP 재다운로드: 49,334,275 bytes, 9 files, SHA-256 `8f664683b980f091788207a8c2543214b19eb73b4fc7a18bf61da7a37b924198`. 압축 무결성과 EXE/PCK 헤더 확인 후 이 ZIP의 EXE로 실제 Windows 메뉴/8인 봇 연습 실행, 정상 종료 및 GDScript 오류 없음. 일부 연습 종료의 텍스처 정리 경고는 여전히 남습니다.
- [Docker TLS CI](https://github.com/Nukcanon/InternalNCrush/actions/runs/35893634492) 성공, 커밋 `4ea5a9a335b2d7e13df1f59daaf992bb6dd013e0`. Windows 실행 코드와 게임 코드는 동일하며 후속 커밋은 테스트 CA 읽기 권한을 수정한 것입니다. Linux amd64만 실제 컨테이너 실행 검증했습니다.
- 홈페이지 커밋 `2f4c6c9154b5b90af2e322410ac309465b1bb39b`, [Pages](https://github.com/Nukcanon/nukcanon/actions/runs/35895174852) 성공. HTML/버전 JSON/현재 게임 이미지 3개가 게시 커밋의 Git 파일과 바이트 단위로 일치합니다. 개발 설명 대신 플레이 가이드/멀티플레이 접속 두 영역을 유지했습니다.
- 실제 외부 운영 도메인/NAS에 서비스를 올린 것은 아닙니다. 운영 절차와 보안/성능의 남은 한계는 위 문서에 기록되어 있습니다.
