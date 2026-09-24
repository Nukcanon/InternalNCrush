# 1.0.1 무기 조정 근거

자체 게임의 수치이며 다른 게임의 데이터나 현실 총기 성능을 복제한 표가 아닙니다. 안정성이 높은 돌격소총/샷건, 낮은 SMG/권총, 큰 비조준 오차의 저격총이라는 상대적인 방향은 사용자의 요청입니다.

공식 자료에서 참고한 것은 역할 간 장단점과 이동·조준의 교환 관계입니다.

- [Riot: How the VALORANT Arsenal Was Built](https://playvalorant.com/en-us/news/dev/how-the-valorant-arsenal-was-built/): 무기군별 용도와 사격 방식 차이.
- [VALORANT 공식 무기고](https://playvalorant.com/ko-kr/arsenal/): 소총·SMG·샷건·저격총의 서로 다른 교전 거리와 사용감.
- [Activision: Modern Warfare Movement](https://blog.activision.com/call-of-duty/2019-10/The-Basics-of-Call-of-Duty-Modern-Warfare-Movement): 이동/달리기/점프와 정확도, 앉기, 조준 전환의 관계.
- [Counter-Strike Arms Deal FAQ](https://www.counter-strike.net/armsdeal/faq.php): 반동·정확도와 탄창 크기 등 장단점의 교환 관계.

`assets/weapons.json`이 실제 게임과 선택 화면의 단일 데이터 원본입니다. 퍼짐은 도 단위의 원뿔 반각이며, 화면 조준점은 현재 FOV에서 무작위 탄 퍼짐 + 반동 패턴의 범위를 투영합니다. ADS는 `ads_ms` 동안 보간하므로 입력 순간 곧바로 저격 정확도가 되지 않습니다. 안정성은 연속 사격 블룸의 증가/최대치/회복과 반동 배율에 반영합니다. 무게와 휴대성은 이동 오차에 반영하며, 기존 중화기 이동 10% 감소 외에 달리기 속도를 새로 일괄 변경하지 않습니다.

예: VECTOR-24 24 피해 / 안정성 78 / 250ms / 3.30kg / 휴대성 68 / 기본 1.05°·조준 0.22°. MONOLITH 6.80kg / 520ms / 기본 12.5°·조준 0.045°. ECHO 기본 6.4°·조준 0.13°. 연발을 오래 유지하면 오차가 커지고 사격을 쉬면 회복됩니다. 낮은 난이도에서 모든 무기가 어렵게 느껴지지 않도록 ADS와 짧은 점사 정확도를 남겼습니다.

총기별 실제 명중률/교전 거리, 장시간 다인전 승률에 따른 후속 조정은 가능하며 현재 값을 확정 경쟁 밸런스라고 주장하지 않습니다.
