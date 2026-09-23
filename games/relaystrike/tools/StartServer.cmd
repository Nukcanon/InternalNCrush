@echo off
cd /d "%~dp0"
InternalNCrush.exe --headless -- --server --auto-start
pause
