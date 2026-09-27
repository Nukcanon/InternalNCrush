# Internal N Crush 1.2.4

다운로드판의 피부·옷 경계와 턱 아래 형태를 수정하고, 전투 효과와 손 메시의 반복 할당을 줄였습니다. 전투 규칙은 1.2.3과 같으며 Windows 상세 모델과 Web 경량 모델을 계속 분리합니다.

- 목 둘레의 실제 메시를 분할해 피부와 옷 색이 섞이던 삼각형 경계를 제거했습니다. 별도로 떠 있거나 목을 파고들던 옷깃 대신 몸의 표면을 따르는 얇은 목 둘레 마감을 사용합니다.
- 남녀 모델의 턱 아래·목 부피를 CC0 인체 보정 데이터로 정리했습니다. SERA와 MINA는 턱의 돌출·폭·길이, 얼굴 윤곽, 입가와 눈꺼풀을 조정했습니다. 눈에 옷 무늬가 적용되던 재질 경로도 수정했습니다.
- 추가 인체 데이터는 빌드 중에 기존 메시로 구워집니다. 뼈는 15개를 유지하며, 몸 메시의 삼각형 증가는 목 경계 분할에 필요한 약 0.8%입니다. 기존 CC0 얼굴 텍스처 두 장을 최대 512px로 제한해 공유하며, 웹판에는 포함하지 않습니다.
- 손·팔·옷의 동일한 메시를 제한된 공유 캐시에 재사용합니다. 폭발 효과는 최대 8개 묶음을 재사용하고, 폭발 입자의 사각형 메시와 파편 충돌 모양도 공유합니다. 연막의 전술적 범위와 폭발 판정은 바뀌지 않습니다.

- 포탑·엄폐물과 설치 윤곽선을 빌드 시 미리 생성해, 설치 순간의 긴 CPU 멈춤을 줄였습니다. 막힌 봇 경로를 매 프레임 재계산하던 문제도 수정했습니다.
- 저사양에서는 원거리 모델의 세부 수준과 벽·바닥의 재질 계산을 줄이며, 해상도·충돌·전투 규칙은 유지합니다. 인텔 10~11세대 내장 그래픽의 실제 FPS는 아직 검증하지 못했습니다.

실제 실행·메모리 측정과 남은 한계는 [VALIDATION_V124.md](https://github.com/Nukcanon/InternalNCrush/blob/main/VALIDATION_V124.md)에 기록합니다. 무료 에셋을 추가한다고 성능 비용이 없어지는 것은 아니며, 임의의 고해상도 에셋을 실행 중에 불러오는 방식은 사용하지 않습니다.

## Defusal economy and bomb usability

Owner-requested additions: separate large store price (white) and balance (yellow) boxes in the fixed footer; larger in-game white balance; yellow carrier hint replaced by E planting prompt at a site; bomb carried vertically with its lamp facing outward. Default fuse 45 seconds, configurable 30–120 seconds (owner’s contradictory “maximum 2 seconds” interpreted as 2 minutes). Defuse 15 seconds / owned kit 5 seconds, including UI/help/stat graph. Purchases allowed during preparation plus the first 60 combat seconds per round, configurable 0–300 and capped to round duration; zero permits preparation purchases only. The authority enforces alive state, deadline, price and replacement confirmation. LAN/WebRTC/Docker/Worker schemas share both new settings. 52 behavior checks pass; directory 9, allocator 10 and Worker 3 test groups pass locally.
