@echo off
rem Double-click or run from cmd: wraps start-local.ps1 without changing execution policy.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0start-local.ps1" %*
