# 1.1.3 검증 기록

현재 로컬 검증 완료, 최종 CI/게시 대기. 이전 공개 결과는 TEST_REPORT_V112.md에 보존했다.

- 기능25묶음 3,525/3,525 통과. 새36개 검사는 MONOLITH 부위/거리/방어구 피해, 여성 몸체/관절/폭, 메딕/리스폰 보호 외형, 표식2초, 소품 묶음과 충돌 유지를 확인한다.
- 실제 Compatibility GPU 차폐 테스트: 직접 보이는 표면 차이0, 벽 뒤 실루엣 색 변화289.7059, 비권한 사용자 차이0. 실제 인체의 자기 가림 오버레이도 제거(직접 보이는 부분 차이0). 메시 내부 AABB로 자기 가림을 배제하며 벽이 모델 자체와 교차하는 극단적 경우에는 보수적으로 표시하지 않을 수 있다.
- SERA/MINA 정면·측면 렌더로 남성 몸체/어깨 관절과 여성 얼굴, 키, 좌우95% 폭 확인.
- 웹 오퍼레이터 총 인덱스97,728→24,348, 맵3,609,489→2,009,013. 단색 재질/작은 메시/반복 소품 MultiMesh, 중복 골격 갱신 제거. 해상도를 자동 변경하지 않는다.
- 브라우저 WebGL2 메뉴1.1.3 실행 확인. 실제 저사양 GPU/스마트폰 FPS는 아직 미측정이다. 이 PC RTX4080SUPER 결과를 저사양 결과로 보고하지 않는다.

자료: [Godot 3D 성능](https://docs.godotengine.org/en/4.4/tutorials/performance/optimizing_3d_performance.html), [깊이 텍스처와 Compatibility NDC](https://docs.godotengine.org/en/4.4/tutorials/shaders/advanced_postprocessing.html). 기본 Web export에는 occlusion culling이 포함되지 않으므로 해당 설정만 켜는 변경은 하지 않았다.
