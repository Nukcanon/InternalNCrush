# Internal N Crush — 1.1.3 인계

최종 공개 버전·소스 커밋·빌드·ZIP 해시는 PUBLICATION_STATUS.json이 기준이다. 이전1.1.2 검증은 game/docs/TEST_REPORT_V112.md에 보존했다.

## 위치와 빌드

- 게임 저장소 D:/python_workplace/InternalNCrush/InternalNCrush → Nukcanon/InternalNCrush main.
- 사이트 저장소 D:/python_workplace/InternalNCrush/site-repository → Nukcanon/nukcanon main.
- game/: 공통 게임·아트·검사. windows/: Windows 검증. web/: 별도 웹 스테이징/패키징. nas/: Linux/NAS Docker 설정. services/directory/: 방 목록·연결 신호. services/cloudflare-directory/: Workers 대안. services/matchmaker/: 이전 구조 참고 자료.
- Godot4.4.1 및 gh는 바깥 .tools 폴더. Python은 .tools/server-venv/Scripts/python.exe. 토큰/개인 환경 파일은 게시하지 않는다.
- prepare_assets.py → editor import → build_models.gd → build_arenas.gd → editor import → Windows export. 맵 캐시 REVISION115(이번 버전 맵 충돌 변경 없음).
- 웹은 Pillow 설치 후 prepare_lightweight.py → web/staging/game import → tools/lightweight_models.gd → Web export → package_web.py. 원본 Windows 모델은 경량화하지 않는다. 웹 import는 use_multiple_threads=false로 Linux 글꼴 가져오기 heap abort를 피한다.
- push CI는 릴리스 업로드 단계를 건너뛴다. 검증 성공 아티팩트를 다운로드하고 실제 Windows EXE/WebRTC를 확인한 뒤 gh release로 게시한다. 최종 문서 커밋에는 [skip ci] 사용.

## 변경 내용

MONOLITH는 유효120m 안에서 머리/몸통/팔/다리100, 손/발60 피해. 100HP 무방어 대상 기준이며 방어구·장거리 감쇠는 유지한다. 기존 느린 연사·4발 탄창·재장전도 유지한다. 총기 선택 설명을 갱신했다.

본인 설치물은 소유자만, 감지/표식 대상은 감지 팀만 차폐 부분 실루엣을 본다. 깊이 텍스처를 읽는 Compatibility 셰이더로 직접 보이는 표면은 버린다. 메시 내부 AABB의 자기 가림을 제외한다(벽이 모델 자체와 교차하는 극단적 경우는 보수적으로 미표시할 수 있음). 적 이름/표식 링으로 전 플레이어에게 노출하던 표현은 제거. 표식2초/유지6초, 감지4초. 메딕 무적은 리스폰 보호와 동일한 팀 색 캡슐 외형이다.

여성은 SERA(정찰172cm), MINA(메딕170cm). 남성 몸·목·어깨/관절/웨이트를 사용하고 얼굴/키를 달리하며 x폭만95%, 깊이100%. 여성 어깨 기본y=.175와 애니메이션y=.105가 달라 어깨가 내려가던 원인을 기준 통일로 수정. 썸네일 갱신.

웹 자동 해상도 조절 및 별도 월드 렌더 타깃 제거. 메뉴 배경도 원래 해상도/15FPS. 단순 vertex color 재질(텍스처 샘플링 없음), 추가 광원/그림자/AA 없음, 작은 메시, 반복 소품 MultiMesh. 충돌과 물리 위치는 그대로 유지. 인덱스: 캐릭터97,728→24,348, 맵3,609,489→2,009,013, 무기616,560→212,856. 중복 골격 갱신 제거/관절 노드 캐시/잠든 소품 처리 중지.

특히 웹 무기를 매번 절차 생성하던 비용을 구운 장면 재사용으로 제거했다. 계측상50~75ms→약0.1~6ms. 28종 총구/탄창/장전 복귀 회귀 검사. 이 수치는 해당 함수 비용이며 전체FPS 향상률이 아니다. 웹의 간헐 process/physics spike는 여전히 관측되었다.

## 접속 및 남은 범위

Windows UDP LAN27888/27889는 평문. 웹은 UDP 검색 불가이므로 WebRTC 로비 사용. NAS/Linux/Worker는 목록/입장/시그널링만 처리하며 방장이 전투를 계산한다. 방장 이탈 시 종료, 자동 이전 없음. 같은 외부IP LAN그룹에는 공유NAT사용자가 포함될 수 있다.

HTTPS/WSS·일회용 입장·입력/빈도/크기 제한·WebRTC 암호화는 있으나 변조 방장/에임봇을 완전히 막지 못한다. 일부NAT는 TURN 필요. 공용Workers는 계정 인증이 없어 미배포이며 기본URL은 비어 있다. GitHub Pages는 정적 게임만 제공한다. 운영자 .env는 NAS ZIP에 포함하지 않는다.

GTX960·내장GPU·실제 휴대폰/iOS·외부PC WAN·ARM NAS·장시간32인·사람 경쟁 승률은 미검증. RTX4080SUPER 브라우저 표본을 저사양 결과로 해석하지 않는다. 최초 로딩 지연·간헐 프레임 지연·기존 종료시GL텍스처 경고도 남아 있다. AAA아트/모션캡처/상용안티치트/공용서버 운영 완료로 보고하지 않는다.

## 최종 배포 검증

소스 75b7db7ce49e5fd6653cc46b686114c4de6881c0. Windows/Web CI36033303552(재시도), Docker/Worker36033303427 통과. 기능25묶음3,581/3,581, 터치23/23, 32명 접속·생명주기·물체·맵순환·실제WebRTC 검증 통과. 첫 CI는32클라이언트 시작 중 한 프로세스의 로그가 오류 메시지 없이 끝나 실패했으며, 같은 소스 로컬검사와 재시도는 통과했다. 정확한 원인은 미확정으로 남긴다.

배포 Windows ZIP 119,703,815bytes/21파일: 연습장10명·봇전투8명·화면 없는 호스트/화면 있는 호스트에 클라이언트 연결, 해당EXE/PCK WebRTC 통과. 기존 종료GL텍스처 경고는 알려진 잔여항목이다.

웹 19파일/67,401,185bytes와 Windows/NAS ZIP 익명다운로드 SHA256 일치. NAS 15,365bytes/14파일, 운영자.env 없음. 사이트 82648afcd118dc2417076e1fbe3cdfc1b229bb44, Pages 36061684402 성공. 공개1.1.3 메뉴/연습장 확인.
