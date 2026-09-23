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

기능 1,089개, API 단위 검사 9개, 실제 로비→전용 서버→독립 클라이언트 2개는 로컬 통과했습니다. 19개 맵과 그래프/회복/폭발/모션은 RTX 4080 SUPER Windows에서 렌더링했습니다. 공개 CI·ZIP/EXE·홈페이지 검증의 최종 결과는 아래와 JSON에 추가합니다.

## 남은 한계

실제 다중 PC/LAN/WAN, 장시간 32인 전투, ARM64 NAS, 저사양 GPU와 다양한 DPI는 별도 검증 대상입니다. 자동 경로/시야/피해 검사만으로 경쟁 밸런스를 확정하지 않습니다. 절차적 모델·IK와 관절 물리는 수작업 고급 에셋/모션캡처가 아닙니다. 일부 Godot 4.4.1 Compatibility 종료에서 `Texture with GL ID ... leaked 349524 bytes` 경고가 남으며 해결했다고 표현하지 않습니다.
