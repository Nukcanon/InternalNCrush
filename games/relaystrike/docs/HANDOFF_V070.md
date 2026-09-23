# Internal N Crush — 작업 인계 (0.7.0)

최종 작업일: 2026-09-23. 게시 결과는 반드시 옆의 `PUBLICATION_STATUS.json`을 확인하세요.

## 소스와 배포 구조

- 새 게임 저장소: https://github.com/Nukcanon/InternalNCrush (공개, main)
- 로컬 작업 저장소: `D:/python_workplace/InternalNCrush/InternalNCrush`
- 게임 프로젝트: `games/relaystrike`, Godot **4.4.1 Standard / GDScript / Windows x64 / Compatibility**.
- 홈페이지 주소 유지: https://nukcanon.github.io/nukcanon/internal-n-crush.html
- 사이트 저장소: https://github.com/Nukcanon/nukcanon
- 사이트 로컬 체크아웃: `D:/python_workplace/InternalNCrush/site-repository`
- 원래 0.6.0 스냅샷은 수정하지 않았습니다. 과거 인계는 `games/relaystrike/docs/HANDOFF_V060.md`에 보존했습니다.
- 0.7.0 소스·배포 상태와 0.6.0의 과거 공개 상태를 혼동하지 마세요.

## 이번에 처리한 사용자 요구

1. **접속 검사**: 서버 109초/각 클라이언트 105초라는 서로 다른 종료 타이머를 없애고, 모든 클라이언트 검사 완료 → 서버가 8명 확인 → Python 실행기 해제 신호 순서로 종료합니다. 105초 유지, 8명, 최신 스냅샷, 재접속·서버 재시작 조건은 유지·강화했습니다. 2번 클라이언트는 자발적 재접속까지 3회 이상 입장을 요구합니다. 시작 간격 1.5초로 마지막 클라이언트를 10초 이상 늦게 시작한 Windows 검사도 통과했습니다.
2. **Windows 실기**: 기존 0.6.0 EXE와 새 0.7.0 EXE를 실제 Windows에서 실행했습니다. 새 메뉴·설정·리플레이·게임 화면을 네이티브 OpenGL/RTX 4080 SUPER로 확인했습니다. 처음 검사에서 기존 실행이 UDP 27888을 점유해 실패한 것과, 생성 자산이 빠져 발생한 오류를 별도로 해결했습니다.
3. **화면 설정**: 모니터 선택, 창/테두리 없는 전체 화면/독점 전체 화면, 8K·울트라와이드 프리셋·직접 입력, 15초 유지 확인·자동 복구. 전체 화면은 선택한 모니터의 원본 해상도입니다. 실제 2560×1440 모니터 **2대 × 3가지 모드 = 6회 모두 통과**했습니다. 8K 물리 모니터를 시험했다는 뜻은 아닙니다.
4. **메인 화면**: 동영상 대신 네트워크와 분리된 오프라인 6인 봇 전투를 실행합니다. 별도 뷰포트와 멀티플레이 컨텍스트를 사용하고 3D 배경 렌더링은 30 FPS입니다. 배경은 무음이며 메뉴 입력을 받지 않습니다.
5. **모션**: 가속·감속, 출발 시 전방 기울기, 급회전·정지 시 제한된 하체 지연, 제자리 회전 발 디딤, 달리기 팔 스윙, 방향에 맞는 두 관절 다리 계산, 점프 무릎 접기·착지 흡수, 앉기 보간, 상체·하체 회전 분리, 무기 손잡이 양손 IK. 프로시저럴 애니메이션이며 모션 캡처 자산을 사용한 것은 아닙니다.
6. **디자인·음향**: 캐릭터 장구류·헬멧·장갑, 총기 조작부·레일·총구·그립, 엄폐물 부품과 체결부, 공병 포탑 구동부·센서·방열부·삼각대. 탄피 12각형 몸체·테두리·뇌관·빈 탄구, 최대 72개/8초. 피격음은 저음 중심의 둔탁한 타격음, 킬 확대 전용 효과음 포함 총 53 WAV. 비조준 반동을 키우고 조준 반동은 상대적으로 억제합니다.
7. **맵**: 19개 전장의 외곽을 모서리가 잘린 비직사각형으로 변경. COURTYARD(7), SWITCHBACK(9), ROOFTOP(16), MARKET LOOP(17)는 새 건물 배치·굽은 골목·경사로·테라스로 재설계했습니다. ROOFTOP의 중앙 거점도 높아졌습니다. 물리 충돌과 봇 경로 높이가 같은 경사로 데이터를 사용합니다. 다른 15개 맵 내부를 전부 새로 만든 것은 아닙니다.
8. **킬 표시·사망 연출**: 킬피드 약 1/4 면적, 배경 알파 0.48. 수신 기록 기반 1인칭 리플레이 2.5초 + 공격자 3인칭 확대 1초, 전용 효과음. 공격자·무기·정밀 명중 여부·리플레이 표시, SPACE/ESC 스킵, 부활 시 종료. 환경 피해와 자살은 공격자 리플레이를 만들지 않습니다. 포탑 처치는 포탑 시점을 명시합니다.
9. **저장소 분리**: 게임 소스·릴리스는 새 저장소로 이동하고 기존 사이트는 주소와 공통 디자인을 유지합니다. 구 저장소 게임 경로는 이전 안내를 남기는 방식입니다. 정확한 공개 결과는 JSON 확인.

## 검증과 남은 문제

- 기존 316개 + 신규 35개 = **351개 기능 검사 통과**. 가속이 추가되어 기존 속도 검사는 한 프레임 즉시 최대 속도 대신 가속 후 원래 최고 속도 도달을 검사하도록 갱신했습니다. 정지 정확도 검사도 실제로 달린 뒤 정지하게 했습니다. 버전 갱신 검사는 현재 버전보다 큰 값을 생성합니다.
- 2프로세스 ENet: 피해 통지·장비 예약·처치·부활·재사격 통과.
- Windows ENet 8인: 각 105초, 시작 간격 1.5초, 자발적 재접속, 서버 재시작, 최종 8명/신선한 스냅샷 모두 통과.
- Windows ENet 32명: 동시 접속과 오류 없는 클라이언트 종료 통과.
- Windows 디스플레이: 2개 실제 모니터, 6가지 모드 전환 통과. 설정 화면 레이아웃 시각 검토.
- 새 EXE의 네이티브 메뉴 실행과 봇 연습, 종료 코드·화면 캡처 확인. ZIP 생성기에서 파일 수·EXE/PCK 헤더·ZIP 무결성·SHA-256 검증.
- **남음**: 서로 다른 PC 사이 실제 LAN(이번에는 동일 Windows 호스트의 독립 프로세스), 장시간 32인 교전, 내장그래픽/저사양 GPU, 다양한 DPI·세로 모니터 조합과 맵 밸런스.
- **남음**: 일부 렌더 검토와 새 릴리스 EXE의 봇 연습 종료 때 Godot 4.4.1 Compatibility의 `Texture with GL ID ... leaked 349524 bytes` 정리 메시지가 재현됩니다. 실행 중 스크립트 오류와 구별하세요. 프로세스 종료 코드는 0이며 플레이 중 스크립트 오류는 없지만, 이 종료 시 GPU 자원 정리 경고의 근본 원인은 아직 해결하지 못했습니다.
- 리플레이는 영상 녹화가 아니라 로컬 수신 위치·조준·실제 사격 시작/끝 좌표의 재구성입니다. 90프레임/최대 512개 사격 이벤트로 제한합니다. 지연·수신 누락, 장치 파괴 시점과 자세의 세부 보간 때문에 원래 공격자 화면과 완전히 같지는 않습니다. 기록 부족이면 건너뜁니다.
- 모션과 디자인은 자체 제작 스타일입니다. 상용 게임 자산·모션캡처 수준의 완성을 보장하지 않으며 플레이 피드백에 따른 추가 조정이 가능합니다.

## 최종 공개 확인

- **0.7.0 게시 완료**. 릴리스 소스: `d75719830d05dfe6d5576b270b6a5bb95be5afdd`. 이후 문서 전용 커밋은 빌드 코드 변경이 아닙니다.
- [새 저장소 CI 35839178082](https://github.com/Nukcanon/InternalNCrush/actions/runs/35839178082): 351개 기능 검사, 2프로세스 전투, 8인 기본/지연 접속 생명주기, 32명 접속, Windows 내보내기·ZIP 게시 모두 성공.
- [0.7.0 릴리스](https://github.com/Nukcanon/InternalNCrush/releases/tag/internal-n-crush-v0.7.0): 공개 알파. ZIP 43,613,355 bytes / 9 files.
- ZIP SHA-256: `5cd2ddff00fff41a9c4ddfb7d5744ee856089d27a278293808012ec63a9eace2`.
- 공개 다운로드 주소에서 ZIP과 SHA256SUMS를 다시 받아 해시·압축 무결성·EXE/PCK 헤더를 확인했습니다. 해당 다운로드 EXE를 실제 Windows에서 메뉴와 8인 봇 연습으로 각각 실행했고 종료 코드는 모두 0입니다. 봇 연습 종료 시 아래에 기록한 텍스처 경고는 재현됐습니다.
- 사이트 커밋: `3b3322b4b047057633e4fdee2daed0cf42550e6f`. [Pages 35840069011](https://github.com/Nukcanon/nukcanon/actions/runs/35840069011) 성공. 공개 HTML·버전 JSON(0.7.0)·새 이미지 3장 HTTP 200 및 게시 내용 일치 확인. 브라우저에서 새 다운로드/소스 링크·갤러리 확인.
- 옛 저장소 `games/relaystrike`는 이전 안내 README만 남겼고, 옛 게임 빌드 워크플로는 제거했습니다. 과거 소스 Git 기록과 0.6.0 이전 릴리스는 보존됩니다.
- 초기 source push 실행 35839169346은 같은 커밋의 수동 배포 검사로 대체되어 취소됐습니다. 실제 게시 판정은 성공한 35839178082를 사용하세요. 구 저장소 0.6.0의 실패 실행은 과거 기록입니다.

## 주요 파일

| 영역 | 파일 (`games/relaystrike` 기준) |
|---|---|
| 연결 종료 동기화 | `tests/network_lifecycle.gd`, `tests/run_network_lifecycle.py` |
| 이동·비조준 반동 | `scripts/actor.gd` |
| 관성·발/팔 IK·캐릭터 생성 | `scripts/character_visual.gd` |
| 총기·포탑·탄피 | `scripts/weapon_visual.gd`, `scripts/combat_fx.gd` |
| 맵·경사로·봇 경로 | `scripts/arena.gd`, `scripts/urban_layout.gd`, `scripts/bot_navigation.gd` |
| 모니터·설정·미리듣기 | `scripts/game.gd`, `scripts/ui.gd` |
| 실시간 메뉴·킬 연출 | `scripts/menu_demo.gd`, `scripts/kill_replay.gd`, `scripts/kill_feed.gd` |
| 음원 생성 | `tools/build_audio.py` |
| 신규 검증·Windows 시각 검사 | `tests/test_v07.gd`, `tests/windows_display.gd`, `tests/windows_smoke.gd`, `tests/motion_review.gd` |

## 재빌드와 실행

로컬 도구는 작업 공간의 `.tools/godot/Godot_v4.4.1-stable_win64_console.exe`입니다. 공식 4.4.1 Windows export templates를 `%APPDATA%/Godot/export_templates/4.4.1.stable`에 설치했습니다. 도구와 인증은 Git에 넣지 않습니다.

```powershell
python games/relaystrike/tools/prepare_assets.py
godot --headless --path games/relaystrike --editor --import --quit
godot --headless --path games/relaystrike --script res://tools/build_models.gd
godot --headless --path games/relaystrike --editor --import --quit
godot --path games/relaystrike
```

CI가 기능·네트워크 검사 및 Windows 내보내기를 수행합니다. 현재 빌드 호스트는 Ubuntu이며 Windows 템플릿으로 내보냅니다. 네이티브 Windows 실행 검증은 이 PC에서 별도로 수행했습니다. 소스 push는 검토용 빌드 아티팩트를 생성하고, `workflow_dispatch`일 때만 릴리스를 게시합니다. 게임 버전 변경 시 소스·EXE ZIP·릴리스 태그·사이트 링크·버전 JSON을 같이 갱신하세요. 실사용 ZIP에는 EXE/PCK/StartServer.cmd/라이선스 9개 파일만 포함합니다.

테스트 결과 로그와 캡처는 로컬 `validation` 폴더 및 작업 공간의 `*-tests.log`, `network-*.log`, `windows-*.log`에 있습니다. 테스트용 `--no-save-profile`은 사용자 설정을 저장하지 않습니다. Headless 검사도 사용자 설정을 읽거나 덮어쓰지 않습니다.

참고한 공개 설계 설명: Ubisoft의 [Far Cry 6 이동 애니메이션](https://news.ubisoft.com/en-gb/article/27176jslYNMPt7vBfCaRQ1/far-cry-6-how-ai-helped-animate-yaras-hero), [동작 전환 관성](https://www.ubisoft.com/en-us/studio/laforge/news/6xXL85Q3bF2vEj76xmnmIu/introducing-learned-motion-matching). 해당 게임의 코드·자산을 가져오지는 않았습니다.
