# Internal N Crush — 1.0.1 작업 인계

작업일: 2026-09-23. 공개 상태와 실제 커밋·빌드·해시는 `PUBLICATION_STATUS.json`에서 확인합니다. 이전 인계는 `games/relaystrike/docs/HANDOFF_V100.md`에 보존했습니다.

## 소스와 배포

- 게임: https://github.com/Nukcanon/InternalNCrush / 로컬 `D:/python_workplace/InternalNCrush/InternalNCrush`.
- 사이트: https://nukcanon.github.io/nukcanon/internal-n-crush.html / 로컬 `D:/python_workplace/InternalNCrush/site-repository`.
- Godot 4.4.1 Standard. 도구 경로: `D:/python_workplace/InternalNCrush/.tools/godot/Godot_v4.4.1-stable_win64_console.exe`.
- 인증된 gh: `D:/python_workplace/InternalNCrush/.tools/gh/bin/gh.exe`. 토큰을 출력하거나 저장소에 넣지 않습니다.

## 이번 변경

- 어깨와 골반 관절 간격을 줄이고 얼굴의 턱·코·눈꺼풀·홍채·입술·머리카락을 다듬었습니다. 정찰 SERA와 메딕 MINA는 여성 오퍼레이터입니다. 병과별 키는 유지합니다.
- 시작/부활마다 서버가 왼손 12%, 오른손 88%로 손잡이를 정합니다. 총·손·3인칭 모델·총구와 리플레이에 반영하고 참가자에게 동기화합니다. 성능이나 피격 크기는 손잡이로 달라지지 않습니다.
- 무기별 피해·안정성·조준 시간(ms)·무게(kg)·휴대성·탄창·사거리·퍼짐을 장비 화면에 표시합니다. 실제 모델을 렌더링한 카드로 병과·총기·가젯·방어구·스킬을 선택하고 옆에서 설명과 3D 미리보기를 봅니다.
- 사격 조준점이 이동뿐 아니라 탄 퍼짐과 누적 반동에도 벌어집니다. 무거운 조준경 장착 무기는 이동 오차와 조준 시간이 크고, 안정성이 낮은 SMG·권총은 연속 사격 시 더 벌어집니다. 소총·샷건은 비교적 안정적이며 저격총 > 지정사수소총 순으로 비조준 오차가 큽니다. 끊어 쏘기·앉기·조준으로 회복/완화할 수 있습니다.
- 킬캠에서 맵을 다시 만들지 않습니다. 리플레이 모델은 미리 준비하고 기존 월드와 카메라를 재사용합니다. 공격자 1인칭 1.75초 → 마지막 탄환 슬로 모션 0.55초 → 피해자 사망 0.5초 → 공격자와 닉네임 확대 1초, 총 3.8초입니다. 마지막 탄환의 출발/명중 위치는 신뢰성 있는 처치 이벤트로 전달합니다. 원래 즉시 판정되는 탄환의 궤적을 느리게 시각화하는 기록 기반 재구성이며 녹화 영상은 아닙니다.
- 해상도 목록은 선택한 모니터의 원본 해상도 이하로 제한합니다. 직접 입력란은 ‘직접 입력’을 선택할 때만 표시하며 전체 화면에서는 숨깁니다. 실제 전체 화면 해상도는 선택 모니터의 원본 해상도입니다.
- 6·8·16·32인 구간별 평면형 전장을 하나씩 유지합니다: ORCHARD(10), CARGO ROW(13), MESA RELAY(4), TIDAL YARD(0). 나머지 15개는 지하 -3.2m, 지상, 2층 4.2m와 일부 상부 발코니 7.4m를 갖추도록 재구성했습니다. 계단, 실내 통과 통로, 직선/이중/광장/꺾인 고가 연결로와 양쪽 진입로가 있습니다.
- 봇 경로는 겹치는 층을 구분하는 AStar3D 그래프를 사용합니다. 계단 옆 벽을 올라가는 잘못된 연결을 차단하고, 층별 장치/물체 회피를 적용합니다. 계단은 연속 충돌 경사면과 약 17.5cm 시각 단차로 구성합니다.
- 공개 사이트에서 개발/모델링 변경 설명을 제거하고 ‘플레이 가이드’와 ‘멀티플레이 접속’ 안내로 정리합니다.

## 검증과 한계

- 기능 검사: 기존 448개, 신규 무기/화면/모델/층별 경로 299개, 실제 봇 이동 9개. 최종 실행 결과는 `docs/TEST_REPORT.md`와 JSON에 기록합니다.
- Windows RTX 4080 SUPER/OpenGL 3.3에서 메뉴, 시각 장비 선택, 해상도 입력, 왼손 1인칭, 슬로 모션 탄환·사망·닉네임 킬캠 및 다층 전장을 렌더링했습니다. 킬캠 begin 함수는 해당 장비에서 0.18~0.26ms였습니다. 이 수치는 함수 시간이며 전체 프레임/GPU 시간이나 모든 PC의 끊김 제거를 보증하는 수치가 아닙니다.
- 2개 모니터 × 3개 창 모드와 직접 입력 표시 조건을 실제 Windows에서 검사했습니다. 6회 모두 통과했고 TEST_REPORT에 기록했습니다.
- 일부 종료의 `Texture with GL ID ... leaked 349524 bytes`는 기존 Godot Compatibility 정리 경고입니다. 플레이 중 GDScript 오류와 구분합니다. 해결됐다고 주장하지 않습니다.
- 실제 여러 PC LAN, 장시간 32인 교전, 내장/저사양 GPU, 물리적 8K·다른 DPI는 추가 검증 대상입니다. 같은 PC의 독립 ENet 프로세스와 CI 검사를 실제 다중 PC 검사로 표현하지 않습니다.
- 모델은 자체 제작 절차적 관절/IK 기반입니다. 얼굴은 고급 블렌드셰이프나 표정 모션캡처가 아닙니다. 맵은 네 가지 모듈형 고가 통로 유형을 바탕으로 구성되며 경쟁 밸런스를 확정한 것은 아닙니다.

## 재현

```powershell
python games/relaystrike/tools/prepare_assets.py
godot --headless --path games/relaystrike --editor --import --quit
godot --headless --path games/relaystrike --script res://tools/build_models.gd
godot --headless --path games/relaystrike --editor --import --quit
godot --headless --path games/relaystrike --script res://tests/test_v101.gd
godot --headless --path games/relaystrike --script res://tests/test_vertical_traversal.gd
godot --path games/relaystrike --script res://tests/visual_v101.gd -- --no-save-profile --no-update-check
godot --path games/relaystrike --script res://tests/windows_display.gd -- --no-save-profile --no-update-check
```

장비 카드 PNG는 `tools/build_thumbnails.gd`를 GPU 모드에서 실행해 갱신합니다. 원본 게임 모델을 직접 렌더링한 51개 이미지이며 저장소에 포함해 CI에서도 표시됩니다. 모델/무기를 수정한 뒤 썸네일도 다시 만들어야 합니다. 생성 모델·오디오·폰트는 기존 빌드 도구로 다시 만듭니다. 네트워크 테스트의 `GODOT` 환경 변수는 실행 파일의 절대 경로입니다. 포트 27888을 사용하는 검사는 동시에 실행하지 않습니다.

## 공개 배포 검증 완료

- 1.0.1 정식 릴리스: https://github.com/Nukcanon/InternalNCrush/releases/tag/internal-n-crush-v1.0.1
- 실행 코드 커밋: `2c4b859096619dc605325a1dd3fb915a0c97d443`. CI `35862125493` 전체 통과. 기능 검사 756/756, 32인 동시 최신 상태, 8인 재접속/서버 재시작/지연 시작, 물체의 기존/늦은 참가 동기화를 통과했습니다.
- 공개 ZIP을 다시 내려받아 SHA-256/9개 파일/실행 파일과 PCK 헤더를 확인하고, 그 EXE로 Windows 메뉴 및 8인 봇 연습을 각각 실행했습니다. 두 실행 모두 정상 종료, GDScript 오류 없음. 종료 텍스처 정리 경고는 인계 문서의 알려진 문제대로 남아 있습니다.
- ZIP SHA-256: `cd247e4be1657d63fd5c2bac83d23462bc09eb2f34b9ba59f467d8de71d322f1` / 49,103,360 bytes.
- 홈페이지 커밋 `309a5a62bd86a12e381c59b7255a9c5936107ef4`, Pages `35864337954` 성공. 실제 공개 HTML·버전 JSON·새 이미지 3개가 게시 커밋의 Git 파일과 바이트 단위로 일치합니다.
