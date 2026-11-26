@echo off
REM fatto da Vuoler21
powershell -ExecutionPolicy Bypass -File "%~dp0build.ps1" %*
pause
