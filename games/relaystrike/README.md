# Internal N Crush 1.0.2

Windows x64용 FPS. 6개 병과, 19개 전장, 5가지 모드와 최대 32인 LAN을 지원합니다. Linux/NAS 운영자가 마련한 서버에는 인터넷 로비로 접속합니다. 같은 버전끼리 플레이하세요.

## 시작과 연결

1. [Windows ZIP](https://github.com/Nukcanon/InternalNCrush/releases/tag/internal-n-crush-v1.0.2)을 모두 풀고 `InternalNCrush.exe`를 실행합니다. `.pck`는 EXE 옆에 둡니다.
2. 혼자라면 **봇과 연습**, LAN이라면 한 명이 **방 만들기**, 나머지는 **내부망 방 찾기 / IP로 접속**을 선택합니다.
3. 기본은 8인 전장입니다. 맵 규모와 정원을 함께 고르며 봇도 인원에 포함됩니다. 작은 맵에 정원 초과 방을 만들 수 없습니다.
4. B에서 오퍼레이터/장비 카드와 능력치 그래프를 확인한 뒤 적용합니다. 전투 중 변경은 다음 부활, 폭탄 모드는 다음 구매 시간에 적용됩니다.
5. 인터넷은 **인터넷 로비**에 운영자 HTTPS URL을 입력합니다. 공개 방을 만들거나 모드를 선택/생략하고 **빠른 참가**를 누릅니다. 운영자: [Docker Linux/NAS 설치](../../services/matchmaker/README.md).

LAN은 Windows 개인 네트워크 방화벽에서 UDP 27888(경기), 27889(검색)를 허용합니다. 같은 내부망에서 인터넷 없이 플레이할 수 있습니다. 서버 시작 파일 `StartServer.cmd`는 LAN 전용입니다. 인터넷 서버의 외부 포트는 TCP 80/443이며, 게임 UDP 포트를 공개하는 구성이 아닙니다.

## 조작

| 입력 | 동작 |
|---|---|
| WASD · 마우스 | 이동 · 시점 |
| 왼쪽 / 오른쪽 클릭 | 발사 / 정조준 |
| Shift | 달리기 |
| Shift 두 번 | 지상에서 이동 중 슬라이딩, 재사용 1.8초 |
| Ctrl / Space | 앉기 / 점프 |
| R / 1 / 2 | 재장전 / 주무기 / 보조무기 |
| 3 / 4 | 가젯 / 통제병 섬광탄 선택, 클릭 사용 |
| G | 가젯 사용. 돌격 파편 수류탄은 누르고 준비, 놓아 투척 |
| V | 통제병 연막/섬광 전환 |
| F | 병과 스킬. 공병은 포탑 설치/강화 |
| Q | 의료 카빈 회복탄 |
| E 유지 | 탄약 회수 / 설치·해체 |
| B / Tab / Esc | 장비 / 점수판 / 메뉴 |
| F6 / F7 | 강퇴 투표 찬성 / 반대 |

파편 수류탄은 안전핀을 뽑은 때부터 3초 후 폭발합니다. 너무 오래 들면 자신도 피해를 받습니다. 벽은 폭발을 막습니다. 슬라이딩 중에는 명중률이 떨어집니다. 저격·지정사수는 조준 이동이 느리고 비조준 퍼짐이 큽니다. 이동/연사 중 조준점 확대로 현재 퍼짐을 확인하세요.

## 규칙과 화면

- 팀 데스매치, 개인전, 제한 부활, 거점 점령, 설치/해체. 병과와 스킬을 각각 켜고 끌 수 있습니다.
- 체력 100, 방어구 0/25/50. 자동 회복 기본 OFF. ON이면 마지막 사격/피격 10초 후 초당 1 HP입니다. 부활 보호는 1.5초이며 보호 중 공격할 수 없습니다.
- 회복 LINK는 총구에서 아군 몸으로 연결됩니다. 최근 피격 대상의 회복량은 절반이며 다중 LINK는 중첩되지 않습니다. 포탑은 30초 충전, 최대 4단계로 강화합니다.
- 6·8·16·32인 규모별 평면 맵 하나, 나머지 15개 다층. 실내 6개, 야간 5개. 이동 물체는 서버가 동기화합니다.
- 병과별 키, 여성 오퍼레이터 2명, 부활 시 왼손 12%/오른손 88%. 이 확률은 성능 차이를 만들지 않습니다.
- 작은 반투명 킬 표시와 기록 기반 킬 리플레이: 1인칭 1.75초 → 마지막 탄환 0.55초 슬로 모션 → 사망 0.5초 → 공격자/닉네임 1초. SPACE/ESC로 건너뜁니다. 공격자 영상의 녹화본은 아닙니다.
- 설정에서 모니터와 창/테두리 없는 전체 화면/독점 전체 화면을 선택합니다. 창 해상도 목록은 모니터 원본 이하이며 직접 입력을 골랐을 때만 입력란이 나옵니다. 전체 화면은 선택 모니터 원본 해상도입니다.

## 빌드와 검증

Godot 4.4.1 Standard, Python 3, Windows x64 export templates를 사용합니다.

```sh
python games/relaystrike/tools/prepare_assets.py
godot --headless --path games/relaystrike --editor --import --quit
godot --headless --path games/relaystrike --script res://tools/build_models.gd
godot --headless --path games/relaystrike --editor --import --quit
GODOT=/absolute/path/godot python games/relaystrike/tests/run_functional.py
godot --path games/relaystrike --script res://tools/build_thumbnails.gd
```

PowerShell은 먼저 `$env:GODOT='실행 파일 절대 경로'`를 지정한 뒤 Python을 실행합니다. 모델/재질 변경 후 썸네일 52개도 다시 생성합니다. 네트워크 검사들은 포트 27888을 공유하므로 순서대로 실행합니다. CI는 Windows 내보내기와 Linux Docker/TLS 검사를 분리합니다. 수동 Windows 워크플로 실행만 정식 릴리스를 게시합니다.

[변경 내용](docs/RELEASE_NOTES.md) · [무기 수치와 설계 근거](docs/BALANCE_NOTES.md) · [검증 결과/한계](docs/TEST_REPORT.md) · [음원 출처](SOUND_CREDITS.md) · [게임 라이선스](LICENSE.txt)

모델/애니메이션은 자체 절차적 모델과 IK/스프링·관절 물리 기반입니다. 모션캡처 또는 수작업 AAA 에셋 제작을 완료한 상태는 아닙니다. 실제 여러 PC/WAN 장시간 경기, 경쟁 밸런스와 저사양 성능은 추가 플레이테스트가 필요합니다.
