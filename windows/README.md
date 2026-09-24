# Windows 게임

플레이할 때는 [최신 Windows ZIP](https://github.com/Nukcanon/InternalNCrush/releases/latest)을 내려받아 **전체 압축을 푼 뒤 `InternalNCrush.exe`**를 실행하세요. 웹사이트는 다운로드와 접속 안내를 제공합니다. Docker는 Windows 게임 실행에 필요하지 않습니다.

- [게임 홈페이지](https://nukcanon.github.io/nukcanon/internal-n-crush.html)
- [조작·게임 규칙](../games/relaystrike/README.md)
- [Linux/NAS 서버 운영](../nas/README.md)

## 소스에서 실행·빌드

공통 게임 소스는 `games/relaystrike/`입니다. Godot 4.4.1로 `project.godot`를 열거나 아래 스크립트로 빌드합니다. 같은 버전의 Windows export templates를 먼저 설치하세요.

```powershell
./windows/build.ps1 -Godot 'C:/Tools/Godot/Godot_v4.4.1-stable_win64_console.exe'
```

출력은 `out/InternalNCrush/`와 `out/InternalNCrush_Windows_v버전.zip`입니다. 서버와 클라이언트는 동일 버전으로 맞춥니다. 개발용 공통 소스를 플랫폼별로 복제하지 않습니다.
