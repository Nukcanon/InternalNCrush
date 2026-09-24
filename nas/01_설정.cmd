@echo off
setlocal
chcp 65001 >nul
cd /d "%~dp0"
set PYTHONUTF8=1
py -3 -c "import sys;sys.exit(not (sys.version_info >= (3,9)))" >nul 2>nul
if not errorlevel 1 (
  py -3 setup.py
  goto done
)
python -c "import sys;sys.exit(not (sys.version_info >= (3,9)))" >nul 2>nul
if not errorlevel 1 (
  python setup.py
  goto done
)
echo Python 3.9 이상이 필요합니다. python.org에서 설치 후 다시 실행하세요.
:done
echo.
pause
