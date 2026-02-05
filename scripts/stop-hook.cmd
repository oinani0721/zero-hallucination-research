@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0stop-hook.ps1"
exit /b %errorlevel%
