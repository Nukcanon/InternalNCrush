# Internal N Crush — 1.1.4 인계

공개 상태와 해시는 [PUBLICATION_STATUS.json](PUBLICATION_STATUS.json), 이번 검사 범위와 한계는 [TEST_REPORT_V114.md](game/docs/TEST_REPORT_V114.md)가 기준입니다. 이전 인계는 Git 이력에 보존됩니다.

## 현재 공개판

- 게임: Nukcanon/InternalNCrush main, PR #1 병합. 런타임 소스 `3e87f868e10cefa98db9723096fcfe4b55f25710`.
- 릴리스: internal-n-crush-v1.1.4. Windows/Web/NAS 패키지와 SHA256SUMS 포함. 검사한 CI 아티팩트를 그대로 게시했습니다.
- 사이트: Nukcanon/nukcanon main, 게임 파일 커밋 `9970d05b091d1a6dc6bb1547b470c33725e44894`.
- 공개 웹 메뉴·연습장과 모든 manifest 파일, 익명 ZIP 해시를 확인했습니다.

## 이번 수정

포탑 전체 조립체 경계로 자기 투시를 억제하고, 최초 강화는 설치 후 35초로 설정했습니다. 교체되는 포탑은 기존 파괴 효과와 소리를 재생합니다. 권총 보조 손·재장전 이동 경로·종류별 마무리 동작, 얇은 일반 조준기, 얼굴 전용 무광 색상 표면을 반영했습니다.

Godot 에셋 가져오기는 공통 프로젝트에서 순차 처리합니다. Python/NAS/Cloudflare 디렉터리 설정도 게임과 같은 1.1.4입니다. 기존 운영자는 서버 패키지를 갱신해야 합니다.

## 빌드와 검사

Godot 4.4.1: prepare_assets.py → editor import → build_models.gd → build_arenas.gd → editor import → Windows export/package_release.py. 웹은 prepare_lightweight.py → staging import → lightweight_models.gd → Web export → package_web.py입니다. Windows 원본 모델과 웹 경량 모델을 구분합니다.

최종 빌드 36094461263, 서버 36094461238, Windows 패키지·웹 메뉴 검사 36095815353, 공개 파일·연습장 UI 확인 36096319950이 성공했습니다. 기능 27개 모음 3722/3722, 터치 23/23, 32명 및 WebRTC 연결 검사를 포함합니다.

release/1.1.4 브랜치의 publish-verified.yml은 핀된 성공 아티팩트를 검증해 게시한 일회성 배포 기록입니다. 공개된 같은 태그를 다시 덮어쓰지 마십시오. verify-live.yml은 실제 메뉴와 입장 확인창을 이용합니다. 최종 문서 변경은 [skip ci]로 기록하며 게임 코드를 다시 빌드하지 않습니다.

## 운영 및 한계

공개 로비는 배포하지 않았습니다. NAS/Worker는 목록·입장·접속 신호만 제공하고 방장이 게임을 계산합니다. Windows UDP LAN, WebRTC 호환 로비의 구분은 README를 참고하십시오.

물리 휴대폰·저사양 GPU·외부 NAT와 장시간 플레이는 미검증입니다. Windows EXE 검사는 headless이며, Chromium SwiftShader 캡처의 FPS는 사용자 GPU 성능을 나타내지 않습니다. 벽과 포탑 경계가 교차하는 극단적 배치의 보수적인 투시 제한 및 샘플 재장전 포즈 확인 범위를 검사 보고서에 기록했습니다.
