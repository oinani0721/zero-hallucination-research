@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0pre-tool-hook.ps1"
exit /b %errorlevel%
