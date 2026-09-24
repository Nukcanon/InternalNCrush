# Internal N Crush — 작업 인계

## 프로젝트와 현재 소스

- 사용자 저장소: https://github.com/Nukcanon/nukcanon
- 게임: `games/relaystrike`, Godot 4.4.1 Standard / GDScript / Windows x64 / Compatibility 렌더러.
- 버전: 0.6.0. 업로드한 게임 커밋: `d7f005208df2abdb7a6f8cf50f928ec21dbce31c`.
- 브랜치: `internal-n-crush-v0.6.0`. 공개 릴리스와 사이트의 최종 결과는 옆의 `PUBLICATION_STATUS.json`을 확인할 것.
- 소스·웹페이지·CI 설정 122개 파일을 포함하며, 글꼴과 52개 WAV, 12개 병과/팀 모델 및 장비 모델도 준비되어 있다.
- 이 인계 ZIP은 소스 스냅샷이다. Git 기록·계정 인증정보·Godot 설치 프로그램·Godot 가져오기 캐시는 포함하지 않는다.

## 지금까지 완료한 작업

- 0.5의 관전/부활 카메라, 유한 탄약·장비 예약·재접속·32인 연결, 팀/병과/모드, 강퇴/투표, 킬피드와 최소 배포 ZIP 정리.
- 0.6: 6인용 6개, 8인용 6개, 16인용 4개, 32인용 3개로 총 19개 전장. 방 설정과 봇 연습에 권장 규모별 선택 추가. 작은 맵의 부활·경계·봇 경로 대응.
- 피격 방향을 카메라 회전에 맞춰 빨간 호와 화살표로 표시, 약 1.15초 후 만료. 일반/방어구 피격음은 피해를 받은 본인에게만 전달. 포탑 원점 반영.
- 1인칭/3인칭 반동, 자신의 화면에 회전·낙하·튕김 후 사라지는 탄피. 이벤트와 스냅샷의 중복 효과 방지.
- 비유혈 충돌 섬광과 4.5초 내 사라지는 먼지 흔적, 방향별 짧은 밀림·넘어짐. 효과 수량 제한 적용.
- 실제 이동 거리에 연결된 발걸음/발소리, 어깨·몸통·총 움직임, 캐릭터별 호흡·대기 자세 변화와 선명한 파랑/주황 색상.
- 다운로드 페이지의 버전·19개 맵 안내·새 화면 3장 공개 반영 완료.

## 검증 결과와 남은 일

- 기능 검사 316/316. 상세 기록: `games/relaystrike/docs/TEST_REPORT.md`.
- 별도 ENet 프로세스에서 피격 통지·킬피드·장비 예약·관전/부활/재사격 확인.
- 8개 클라이언트 105초 연결, 재접속·서버 재시작 후 복귀. 32개 클라이언트 동시 접속/오류 없는 종료.
- 52개 음원 PCM 해시와 클리핑 검사. 17개 렌더 화면 검토.
- Windows x64 내보내기와 ZIP 무결성 통과. 내보낸 PCK를 Linux에서 열어 신규 맵과 캐릭터·음원을 확인.
- 실제 Windows에서의 실행과 소리 크기/조작감, 여러 Windows PC LAN, 장시간 경기, 내장그래픽 성능 및 지속적인 32인 교전 부하는 아직 확인해야 한다.
- 소프트웨어 OpenGL 화면 검토 종료 시 텍스처 2개 정리 경고가 있었다. 실행 중 스크립트 오류와 구별할 것.
- 맵과 캐릭터는 자체 제작된 개발 단계 자산이다. 전장 밸런스와 모션 자연스러움은 실제 플레이 피드백을 받아 계속 다듬을 수 있다.


### 게시 이후 추가 확인 — PC에서 먼저 확인할 항목

릴리스 생성용 브랜치 CI `35832209642`는 전체 성공했고, 해당 실행 ZIP의 공개 다운로드와 SHA-256을 확인했다. 같은 커밋을 main에 반영하며 자동 시작된 중복 CI `35832696897`에서는 316개 기능 검사와 2프로세스 검사는 통과했으나 8인 연결 검사 마지막 단계가 실패했다. 서버는 최종 8명을 기록했고, 7개 클라이언트는 통과했다. 클라이언트 7은 재접속 2회 이후 마지막 검사에서 population=0, snapshot age=200ms를 기록했다.

`tests/network_lifecycle.gd`의 서버는 자체 시작 후 109초에 종료하고, 클라이언트는 각자 시작 후 105초에 최종 상태를 검사한다. 프로세스 시작 지연으로 서버 종료가 마지막 클라이언트 검사보다 빨라지는 경쟁 상태가 의심된다. 아직 확정한 원인은 아니다. **다음 작업에서 서버와 모든 클라이언트의 검사 완료를 명시적으로 동기화한 뒤 재검증할 것.** 실제 접속 손실·재접속 검증 조건을 느슨하게 만들어 통과시키지 말 것.

이 중복 실행은 Windows 내보내기/릴리스 업로드 전에 중단되어 이미 성공한 공개 ZIP을 바꾸지 않았다. 게시 완료와 모든 후속 검사 성공을 혼동하지 말 것. 실제 Windows 실행 검증도 남아 있다.

## 파일 지도

| 작업 | 파일 |
|---|---|
| 버전·규칙·맵 목록 | `scripts/rules.gd`, `project.godot` |
| 서버 규칙·피해·RPC·재접속 | `scripts/game.gd` |
| 이동·시점·총 반동 | `scripts/actor.gd` |
| 캐릭터 모양·관절 애니메이션 | `scripts/character_visual.gd` |
| 무기 모델·부품 모션 | `scripts/weapon_visual.gd` |
| 전장 배치·크기·부활 | `scripts/arena.gd`, `scripts/map_layouts.gd` |
| 봇 판단·경로 | `scripts/bot_agent.gd`, `scripts/bot_navigation.gd` |
| 피격 화면·일시 효과 | `scripts/damage_indicator.gd`, `scripts/combat_fx.gd` |
| 메뉴·설정·HUD | `scripts/ui.gd` |
| 음원 제작·자산 준비 | `tools/build_audio.py`, `tools/prepare_assets.py` |
| 모델 생성·최소 ZIP | `tools/build_models.gd`, `tools/package_release.py` |
| 홈페이지 | 저장소 루트 `internal-n-crush.html`, `internal-n-crush-version.json`, `image/*v060.jpg` |
| 자동 빌드·릴리스 | `.github/workflows/relaystrike.yml` |

`scripts/`, `tools/` 경로는 `games/relaystrike/` 기준이다.

## 자산 준비·실행·배포

Python 3와 Godot 4.4.1이 PATH에 있으면 저장소 루트에서 다음을 실행한다. PC의 Godot 실행 파일명이 다르면 `godot` 대신 실제 경로를 사용한다.

```powershell
python games/relaystrike/tools/prepare_assets.py
godot --headless --path games/relaystrike --editor --import --quit
godot --headless --path games/relaystrike --script res://tools/build_models.gd
godot --headless --path games/relaystrike --editor --import --quit
godot --path games/relaystrike
```

이 ZIP에는 글꼴·음원·모델이 이미 있다. 처음에는 가져오기만으로 실행할 수 있다. 캐릭터/무기 제작 코드를 수정하면 모델을 다시 생성해야 한다. 오래된 생성 모델이 남아 있으면 화면에 수정 전 모양이 나타날 수 있다.

```powershell
godot --headless --path games/relaystrike --script res://tests/test_v06.gd
```

기존 전체 검사는 `.github/workflows/relaystrike.yml`의 테스트 목록을 따른다. 네트워크 Python 실행기는 Godot 경로를 `GODOT` 환경 변수로 받는다. Windows 로컬 렌더 검토용 스크립트의 `/tmp` 출력 경로는 PC에 맞게 바꿔서 사용한다.

Windows 내보내기는 Godot 편집기에서 **4.4.1용 Export Templates**를 설치한 다음 진행한다.

```powershell
New-Item -ItemType Directory -Force out/InternalNCrush
$exportPath = [System.IO.Path]::GetFullPath("out/InternalNCrush/InternalNCrush.exe")
godot --headless --path games/relaystrike --export-release "Windows Desktop" $exportPath
python games/relaystrike/tools/package_release.py --build-dir out/InternalNCrush --output-dir out
```

## 계속 유지할 사용자 요구

- 실제 실행용 ZIP에는 EXE·PCK·StartServer.cmd·필수 라이선스만 넣을 것. 개발 원본·중복 실행기·검사 기록은 실행 ZIP에서 제외.
- 개발용 ZIP에는 수정과 재빌드에 필요한 원본과 인계 기록을 포함할 것.
- 새 게임 버전을 배포하면 소스·실행 ZIP·웹 다운로드 링크·버전 JSON을 함께 맞출 것.
- 모든 참가자/서버는 같은 게임 버전을 사용하도록 안내.
- 사이트의 다른 앱, 공통 디자인과 특수 업로드 버튼은 게임 작업과 관계없이 바꾸지 말 것.
- 새 대화가 이어받을 수 있도록 이 문서에 마지막 변경·검증 결과·남은 문제를 갱신할 것.

## 이번 업로드 기록

첫 create_tree 호출에서 오류 응답을 JSON으로 해석하는 과정에 실패하여 거절 원문이 보존되지 않았다. 따라서 최초 차단의 정확한 이유는 알 수 없다. 사용자가 재시도를 요청한 후 동일 변경 묶음의 생성과 커밋 업로드는 성공했다. 새 브랜치를 update_ref로 생성하려다 GitHub 422(Reference does not exist)를 받았으나, 정식 create_branch 호출로 해결했다. 이 422는 별도 API 사용 오류이며 최초 자동 승인 차단의 원인이라고 단정하지 않는다.
