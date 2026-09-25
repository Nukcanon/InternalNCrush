# 기존 1.1.4에 덧씌우기

2026-09-25. 사용자가 기존 1.1.4를 교체하도록 요청한 직접 업로드용 수정본입니다.
버전은 1.1.4로 유지합니다. 새 브랜치나 새 릴리스 번호를 만들지 않고 두 저장소의 main에 순서대로 올립니다.

## 받을 파일과 위치

| ZIP | 저장소 | 올릴 위치 |
|---|---|---|
| InternalNCrush-1.1.4-overwrite.zip | https://github.com/Nukcanon/InternalNCrush | main의 최상위 |
| nukcanon-1.1.4-overwrite.zip | https://github.com/Nukcanon/nukcanon | main의 최상위 |

ZIP에는 이번 작업의 추가/수정 파일이 실제 내용과 폴더 구조 그대로 들어 있습니다.
현재 저장소 위에 추가/교체하며, ZIP에 없는 기존 파일과 폴더는 그대로 둡니다.
ZIP 자체를 올리거나 저장소 전체를 삭제하지 않습니다.

## 1. 게임 저장소부터 업로드

1. InternalNCrush-1.1.4-overwrite.zip의 압축을 풉니다.
2. https://github.com/Nukcanon/InternalNCrush 에서 브랜치가 main인지 확인합니다.
3. 최상위의 Add file → Upload files를 누릅니다.
4. 압축 안의 game, web, .github 폴더와 README.md 파일을 **함께** 끌어 놓습니다.
5. 업로드 경로가 game/scripts/web_graphics.gd, .github/workflows/windows.yml처럼 시작해야 합니다. 앞에 ZIP 이름의 포장용 폴더가 붙으면 안 됩니다.
6. 현재 main에 Commit changes를 누릅니다.
7. https://github.com/Nukcanon/InternalNCrush/actions 에서 **Build and replace Internal N Crush 1.1.4**가 초록색으로 완료될 때까지 기다립니다.

Godot 4.4.1 준비, 모델과 썸네일 생성, 기능·터치·네트워크 검사, Windows/Web 빌드가 실행됩니다.
전부 통과한 뒤 replace-release 작업이 기존 internal-n-crush-v1.1.4 릴리스의 아래 파일을 교체합니다.

- InternalNCrush_Windows_v1.1.4.zip
- InternalNCrush_Web_v1.1.4.zip
- SHA256SUMS.txt
- WEB_RELEASE_v1.1.4.json: 웹 ZIP 해시와 실제 빌드 소스 커밋

현재 main에 올린 경우에만 교체합니다. 다른 브랜치의 검사는 릴리스를 변경하지 않습니다.
검사나 빌드가 실패하면 교체 작업은 실행되지 않습니다.
빨간색이면 첫 실패 단계의 로그를 전달해 주세요. 아직 실제 엔진 검사를 통과한 묶음은 아닙니다.

## 2. 게임 작업이 성공한 뒤 사이트 업로드

1. nukcanon-1.1.4-overwrite.zip의 압축을 풉니다.
2. https://github.com/Nukcanon/nukcanon 의 main 최상위에서 Add file → Upload files를 누릅니다.
3. 압축 안의 .github 폴더, index.html, internal-n-crush.html을 **함께** 올리고 현재 main에 커밋합니다.
4. https://github.com/Nukcanon/nukcanon/actions 에서 **Install updated Internal N Crush 1.1.4**가 완료되는지 확인합니다.
5. 이어서 Pages 배포가 완료되면 기존 홈페이지 주소를 새로고침합니다.

사이트 작업은 새 릴리스의 해시와 전체 파일 목록을 검사하고 play/를 교체합니다.
홈페이지의 게임 소개, Windows 다운로드와 바로 플레이 링크도 갱신합니다.
버전은 1.1.4지만 다운로드 링크에 빌드 식별자를 붙이고 웹의 JS/WASM/PCK는 빌드별 이름을 써서 이전 캐시와 구분합니다.
관련 없는 홈페이지 파일은 건드리지 않습니다.

사이트 파일을 먼저 올려 실패했다면 게임 작업이 성공한 후 위 사이트 Actions에서
Install updated Internal N Crush 1.1.4 → Run workflow → main → Run workflow를 실행하면 됩니다.
사이트 자동 작업에 오류가 나면 그 로그를 전달해 주세요. 사용자가 Godot을 설치하거나 대용량 게임 파일을 웹 화면으로 올릴 필요는 없습니다.

## 이전 버전과 현재 상태

게임 저장소에는 internal-n-crush-v1.1.0부터 v1.1.4까지의 태그와 변경 커밋이 있습니다.
사이트도 이전 배포 커밋을 보관하고 있습니다. 이전 버전 관리를 전혀 하지 않은 상태는 아닙니다.

이번 방식은 사용자 요청에 따라 **1.1.4의 Windows/Web 다운로드 파일과 현재 웹 사이트를 덮어씁니다.**
이전 커밋과 태그를 삭제하거나 다시 쓰지는 않습니다.
1.1.4 태그 자체는 이전 소스 지점을 유지하므로 이번 수정 소스는 main 및 WEB_RELEASE_v1.1.4.json의 source_commit으로 식별합니다.
GitHub의 Source code ZIP은 태그 기준이므로 이번 교체된 실행 파일의 소스가 필요하면 해당 source_commit을 사용합니다.
기존 NAS 설정 패키지는 이번 교체 대상이 아닙니다.

실제 게임 실행, 그래픽·모바일 조작, GTX2060/스마트폰 성능 측정은 아직 미검증입니다.
로컬에서 확인한 범위는 문법 검사, 웹 준비 스크립트, 배포 스크립트의 무결성/잘못된 파일 차단 검사입니다.
이 두 ZIP은 **소스 및 자동 빌드·배포 설정**입니다. 새 실행 파일은 위 Actions가 성공해야 생성됩니다.
