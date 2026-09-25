# Windows 게임

플레이할 때는 [최신 Windows ZIP](https://github.com/Nukcanon/InternalNCrush/releases/latest)을 내려받아 **전체 압축을 푼 뒤 `InternalNCrush.exe`**를 실행하세요. 웹사이트에는 다운로드·바로 플레이와 접속 안내가 있습니다. Docker는 Windows 게임 실행에 필요하지 않습니다.

- [게임 홈페이지](https://nukcanon.github.io/nukcanon/internal-n-crush.html)
- [조작·게임 규칙](../game/README.md)
- [Linux/NAS 서버 운영](../nas/README.md)

## 소스에서 실행·빌드

공통 게임 소스는 `game/`입니다. Godot 4.4.1로 `project.godot`를 열거나 아래 스크립트로 빌드합니다. 같은 버전의 Windows export templates를 먼저 설치하세요.

```powershell
./windows/build.ps1 -Godot 'C:/Tools/Godot/Godot_v4.4.1-stable_win64_console.exe'
```

출력은 `out/InternalNCrush/`와 `out/InternalNCrush_Windows_v버전.zip`입니다. 서버와 클라이언트는 동일 버전으로 맞춥니다. 개발용 공통 소스를 플랫폼별로 복제하지 않습니다.

## 배포 ZIP 실행 검사

Windows 데스크톱에서 Python 3로 실행합니다. 빌드한 소스 커밋의 전체 SHA를 지정하세요.

```powershell
python windows/verify_build.py --zip out/InternalNCrush_Windows_v1.1.4.zip --output-dir validation/windows-package --source-commit 전체40자리커밋SHA
```

압축 무결성과 라이선스 파일, 실제 EXE의 연습장·봇 전투, 화면 없는 서버/일반 방장과 그래픽 클라이언트 사이 접속을 검사합니다. 로그·화면 캡처·해시·`verification.json`을 출력합니다. 게임 창이 잠시 열립니다. 기존 사용자 설정을 저장하지 않으며, 테스트가 시작한 프로세스만 종료합니다. 기본 테스트 포트 32888을 사용 중이면 `--port 33888`처럼 바꾸세요. 실제 다중 PC나 WAN 검사를 대신하지는 않습니다.

배포 PCK와 WebRTC DLL까지 포함한 접속 검사는 다음과 같습니다. 외부 테스트 스크립트만 읽으며 실제 게임 코드는 명시한 PCK에서 불러옵니다. 로컬 방 목록 서버를 잠시 실행하므로 TCP 30880이 비어 있어야 합니다.

```powershell
python -m pip install -r services/directory/requirements.txt
python windows/verify_webrtc.py --exe validation/windows-package/unpacked/InternalNCrush/InternalNCrush.exe
```
